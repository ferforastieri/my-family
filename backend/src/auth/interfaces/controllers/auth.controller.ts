import {
  Controller,
  Post,
  Get,
  Patch,
  Body,
  Req,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
  UnauthorizedException,
  Query,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { AuthService } from '../../application/services/auth.service';
import {
  ForgotPasswordDto,
  LoginDto,
  RefreshTokenDto,
  RegisterDto,
  ResetPasswordDto,
  SelectTenantDto,
  UpdateProfileDto,
} from '../dto/auth.dto';
import { Public } from '../../decorators/public.decorator';
import {
  mediaType,
  MAX_UPLOAD_BYTES,
  UploadService,
  UploadContext,
} from '@shared/infrastructure/upload';
import { StreamableFile } from '@nestjs/common';
import { AuditService } from '../../../audit/application/audit.service';
import type { Request } from 'express';
import type { UserEntity } from '@auth/domain/entities/user.entity';

@Controller('auth')
export class AuthController {
  constructor(
    private auth: AuthService,
    private upload: UploadService,
    private audit: AuditService,
  ) {}

  @Post('register')
  @Public()
  async register(@Body() dto: RegisterDto, @Req() request: Request) {
    const response = await this.auth.register({
      email: dto.email,
      password: dto.password,
      name: dto.name,
      familyName: dto.familyName,
      slug: dto.slug,
      locale: dto.locale,
    });
    await this.audit.record({
      action: 'auth.register',
      resource: 'auth',
      source: 'http',
      success: true,
      ...this.audit.requestActor(request),
      actorUserId: response.user.id,
      actorEmail: response.user.email,
      method: request.method,
      path: request.originalUrl,
      metadata: {
        tenantSlug: response.memberships[0]?.tenant.slug,
      },
    });
    return { message: 'Cadastro realizado com sucesso.', ...response };
  }

  @Post('login')
  @Public()
  async login(@Body() body: LoginDto, @Req() request: Request) {
    const user = await this.auth.validateUser(body.email, body.password);
    if (!user) {
      await this.audit.record({
        action: 'auth.login.failed',
        resource: 'auth',
        source: 'http',
        success: false,
        ...this.audit.requestActor(request),
        actorEmail: body.email,
        method: request.method,
        path: request.originalUrl,
        statusCode: 401,
      });
      throw new UnauthorizedException('Email ou senha inválidos.');
    }
    const response = await this.auth.accountSession(user);
    await this.audit.record({
      action: 'auth.login',
      resource: 'auth',
      source: 'http',
      success: true,
      ...this.audit.requestActor(request),
      actorUserId: user.id,
      actorEmail: user.email,
      method: request.method,
      path: request.originalUrl,
      statusCode: 201,
      metadata: { scope: response.scope },
    });
    return {
      message: 'Login realizado com sucesso.',
      ...response,
    };
  }

  @Post('select-tenant')
  async selectTenant(
    @Req() request: Request & { user: { id: string } },
    @Body() dto: SelectTenantDto,
  ) {
    return {
      message: 'Família selecionada.',
      ...(await this.auth.tenantSession(request.user.id, dto.tenantSlug)),
    };
  }

  @Post('platform')
  async platform(@Req() request: Request & { user: { id: string } }) {
    return {
      message: 'Sessão administrativa iniciada.',
      ...(await this.auth.platformSession(request.user.id)),
    };
  }

  @Post('logout')
  async logout(
    @Req()
    request: Request & {
      user: { id: string; email: string; tenantId?: string | null };
    },
  ) {
    await this.audit.record({
      action: 'auth.logout',
      resource: 'auth',
      source: 'http',
      success: true,
      actorUserId: request.user.id,
      actorEmail: request.user.email,
      tenantId: request.user.tenantId ?? undefined,
      method: request.method,
      path: request.originalUrl,
      ...this.audit.requestActor(request),
    });
    return { message: 'Sessão encerrada.' };
  }

  @Post('refresh')
  @Public()
  async refresh(@Body() dto: RefreshTokenDto) {
    const token = dto.refreshToken ?? dto.refresh_token;
    const response = await this.auth.refresh(token ?? '');
    return { message: 'Sessão renovada.', ...response };
  }

  @Get('session')
  session(@Req() req: { user: UserEntity }) {
    return this.auth.sessionFor(req.user);
  }

  @Patch('me')
  async updateMe(
    @Req()
    req: {
      user: UserEntity;
    },
    @Body() dto: UpdateProfileDto,
  ) {
    const user = await this.auth.updateProfile(req.user.id, {
      name: dto.name,
    });
    const sessionUser =
      user && req.user.tenantId
        ? await this.auth.findAuthenticatedUser(user.id, req.user.tenantId)
        : user;
    return {
      message: 'Perfil atualizado.',
      user: sessionUser ? this.auth.publicUser(sessionUser) : null,
    };
  }

  @Post('avatar')
  @UseInterceptors(
    FileInterceptor('file', {
      limits: { fileSize: MAX_UPLOAD_BYTES, files: 1, fields: 5 },
    }),
  )
  async uploadAvatar(
    @Req()
    req: {
      user: UserEntity;
    },
    @UploadedFile() file: Express.Multer.File,
  ) {
    if (!file) throw new BadRequestException('Nenhum arquivo enviado');
    if (!req.user.tenantId) {
      throw new BadRequestException('Selecione uma família para o avatar.');
    }
    const { relativePath } = await this.upload.saveFile(
      file,
      UploadContext.Avatar,
    );
    const user = await this.auth.updateAvatar(req.user.id, relativePath);
    const sessionUser =
      user && req.user.tenantId
        ? await this.auth.findAuthenticatedUser(user.id, req.user.tenantId)
        : user;
    return {
      message: 'Foto do perfil atualizada.',
      user: sessionUser ? this.auth.publicUser(sessionUser) : null,
    };
  }

  @Post('forgot-password')
  @Public()
  async forgotPassword(@Body() body: ForgotPasswordDto) {
    await this.auth.requestPasswordReset(body.email);
    return {
      message:
        'Se o email existir, você receberá um token de recuperação por email.',
    };
  }

  @Post('reset-password')
  @Public()
  async resetPassword(@Body() body: ResetPasswordDto) {
    const { token, newPassword } = body;
    if (!token || !newPassword)
      throw new BadRequestException('Token e nova senha são obrigatórios');
    await this.auth.resetPassword(token, newPassword);
    return { message: 'Senha redefinida com sucesso.' };
  }

  @Get('avatar')
  @Public()
  async getAvatar(@Query('path') relativePath: string) {
    const match = relativePath?.match(/^tenants\/([^/]+)\/avatar\//);
    if (!match) {
      throw new BadRequestException('Caminho inválido');
    }
    const file = await this.upload.openTenantFile(match[1], relativePath);
    return new StreamableFile(file.stream, {
      type: file.contentType || mediaType(relativePath),
      length: file.contentLength,
    });
  }
}
