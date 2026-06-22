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
import { LoginDto, RefreshTokenDto, RegisterDto } from '../dto/auth.dto';
import { Public } from '../../decorators/public.decorator';
import { UploadService, UploadContext } from '@shared/infrastructure/upload';
import { StreamableFile } from '@nestjs/common';
import { createReadStream } from 'fs';
import { TenantService } from '@tenancy/application/tenant.service';

@Controller('auth')
export class AuthController {
  constructor(
    private auth: AuthService,
    private upload: UploadService,
    private tenants: TenantService,
  ) {}

  @Post('register')
  @Public()
  async register(@Body() dto: RegisterDto) {
    const response = await this.auth.register({
      email: dto.email,
      password: dto.password,
      name: dto.name,
      familyName: dto.familyName,
      slug: dto.slug,
      locale: dto.locale,
    });
    return { message: 'Cadastro realizado com sucesso.', ...response };
  }

  @Post('login')
  @Public()
  async login(@Body() body: LoginDto) {
    const user = await this.auth.validateUser(body.email, body.password);
    if (!user) throw new UnauthorizedException('Email ou senha inválidos.');
    return {
      message: 'Login realizado com sucesso.',
      ...(await this.auth.tokenResponse(
        user,
        undefined,
        undefined,
        body.tenantSlug,
      )),
    };
  }

  @Post('refresh')
  @Public()
  async refresh(@Body() dto: RefreshTokenDto) {
    const token = dto.refreshToken ?? dto.refresh_token;
    const response = await this.auth.refresh(token ?? '');
    return { message: 'Sessão renovada.', ...response };
  }

  @Get('me')
  async me(
    @Req()
    req: {
      user: {
        id: string;
        email: string;
        name: string | null;
        role: string;
        access: string[];
        avatarPath?: string | null;
      };
    },
  ) {
    return {
      user: this.auth.publicUser(req.user as any),
      tenant: await this.tenants.current(),
    };
  }

  @Patch('me')
  async updateMe(
    @Req() req: { user: { id: string; tenantId: string } },
    @Body() dto: { name?: string },
  ) {
    const user = await this.auth.updateProfile(req.user.id, {
      name: dto.name,
    });
    const sessionUser = user
      ? await this.auth.findAuthenticatedUser(user.id, req.user.tenantId)
      : null;
    return {
      message: 'Perfil atualizado.',
      user: sessionUser ? this.auth.publicUser(sessionUser) : null,
    };
  }

  @Post('avatar')
  @UseInterceptors(FileInterceptor('file'))
  async uploadAvatar(
    @Req() req: { user: { id: string; tenantId: string } },
    @UploadedFile() file: Express.Multer.File,
  ) {
    if (!file) throw new BadRequestException('Nenhum arquivo enviado');
    const { relativePath } = await this.upload.saveFile(
      file,
      UploadContext.Avatar,
    );
    const user = await this.auth.updateAvatar(req.user.id, relativePath);
    const sessionUser = user
      ? await this.auth.findAuthenticatedUser(user.id, req.user.tenantId)
      : null;
    return {
      message: 'Foto do perfil atualizada.',
      user: sessionUser ? this.auth.publicUser(sessionUser) : null,
    };
  }

  @Post('forgot-password')
  @Public()
  async forgotPassword(@Body('email') email: string) {
    if (!email) throw new BadRequestException('Email é obrigatório');
    await this.auth.requestPasswordReset(email);
    return {
      message:
        'Se o email existir, você receberá um token de recuperação por email.',
    };
  }

  @Post('reset-password')
  @Public()
  async resetPassword(@Body() body: { token: string; newPassword: string }) {
    const { token, newPassword } = body;
    if (!token || !newPassword)
      throw new BadRequestException('Token e nova senha são obrigatórios');
    await this.auth.resetPassword(token, newPassword);
    return { message: 'Senha redefinida com sucesso.' };
  }

  @Get('avatar')
  @Public()
  getAvatar(@Query('path') relativePath: string) {
    const match = relativePath?.match(/^tenants\/([^/]+)\/avatar\//);
    if (!match) {
      throw new BadRequestException('Caminho inválido');
    }
    const fullPath = this.upload.resolveTenantPath(match[1], relativePath);
    const file = createReadStream(fullPath);
    const ext = relativePath.split('.').pop()?.toLowerCase();
    const type =
      ext === 'png'
        ? 'image/png'
        : ext === 'gif'
          ? 'image/gif'
          : ext === 'webp'
            ? 'image/webp'
            : 'image/jpeg';
    return new StreamableFile(file, { type });
  }
}
