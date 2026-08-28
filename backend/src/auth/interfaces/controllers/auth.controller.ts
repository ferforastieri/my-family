import {
  Controller,
  Post,
  Get,
  Patch,
  Body,
  UseGuards,
  Req,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
  Query,
  Res,
  Header,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { AuthService } from '../../application/services/auth.service';
import { RequestPhoneCodeDto, VerifyPhoneCodeDto } from '../dto/auth.dto';
import { JwtAuthGuard } from '../../guards/jwt-auth.guard';
import { UploadService, UploadContext } from '@shared/infrastructure/upload';
import type { Request, Response } from 'express';
import { TurnstileService } from '@shared/infrastructure/security/turnstile.service';
import { DemoRestrictedGuard } from '@tenancy/interfaces/demo-restricted.guard';
import {
  AuthCookieService,
  REFRESH_COOKIE,
  cookieValue,
} from '@shared/infrastructure/security/auth-cookies';

@Controller('auth')
export class AuthController {
  constructor(
    private auth: AuthService,
    private upload: UploadService,
    private turnstile: TurnstileService,
    private cookies: AuthCookieService,
  ) {}

  @Post('phone/request-code')
  async requestPhoneCode(
    @Body() dto: RequestPhoneCodeDto,
    @Req() req: { ip?: string },
  ) {
    await this.turnstile.verify(dto.turnstileToken, req.ip, {
      required: false,
      action: 'phone',
    });
    return {
      message: `Código enviado por ${dto.channel === 'whatsapp' ? 'WhatsApp' : 'SMS'}.`,
      ...(await this.auth.requestCode(dto.phone, dto.channel)),
    };
  }

  @Post('phone/verify-code')
  @Header('Cache-Control', 'no-store')
  async verifyPhoneCode(
    @Body() dto: VerifyPhoneCodeDto,
    @Req() req: { headers: Record<string, string | undefined> },
    @Res({ passthrough: true }) response: Response,
  ) {
    const session = await this.auth.authenticateWithCode({
      ...dto,
      userAgent: req.headers['user-agent'],
    });
    const csrfToken = this.cookies.setSession(response, session);
    return {
      message: 'Celular confirmado.',
      ...publicSession(session),
      csrfToken,
    };
  }

  @Get('csrf')
  @Header('Cache-Control', 'no-store')
  csrf(@Res({ passthrough: true }) response: Response) {
    return { csrfToken: this.cookies.rotateCsrf(response) };
  }

  @Post('refresh')
  @Header('Cache-Control', 'no-store')
  async refresh(
    @Req() req: Request,
    @Res({ passthrough: true }) response: Response,
  ) {
    const session = await this.auth.refresh(
      cookieValue(req, REFRESH_COOKIE) ?? '',
      req.headers['user-agent'],
    );
    const csrfToken = this.cookies.setSession(response, session);
    return {
      message: 'Sessão renovada.',
      ...publicSession(session),
      csrfToken,
    };
  }

  @Post('logout')
  async logout(
    @Req() req: Request,
    @Res({ passthrough: true }) response: Response,
  ) {
    await this.auth.logout(cookieValue(req, REFRESH_COOKIE) ?? '');
    this.cookies.clear(response);
    return { message: 'Sessão encerrada.' };
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  async me(
    @Req()
    req: {
      user: {
        id: string;
        phoneNumber: string;
        name: string | null;
        role: string;
        access: string[];
        avatarPath?: string | null;
      };
    },
  ) {
    return {
      user: req.user,
      tenant: (req.user as { tenant?: unknown }).tenant ?? null,
    };
  }

  @Get('tenants')
  @UseGuards(JwtAuthGuard)
  async tenants(@Req() req: { user: { id: string } }) {
    return { items: await this.auth.listTenants(req.user.id) };
  }

  @Post('switch-tenant')
  @UseGuards(JwtAuthGuard)
  async switchTenant(
    @Req()
    req: {
      user: { id: string };
      headers: Record<string, string | undefined>;
    },
    @Body('tenantId') tenantId: string,
    @Res({ passthrough: true }) response: Response,
  ) {
    if (!tenantId) throw new BadRequestException('tenantId é obrigatório');
    const session = await this.auth.switchTenant(
      req.user.id,
      tenantId,
      req.headers['user-agent'],
    );
    const csrfToken = this.cookies.setSession(response, session);
    return { ...publicSession(session), csrfToken };
  }

  @Patch('me')
  @UseGuards(JwtAuthGuard, DemoRestrictedGuard)
  async updateMe(
    @Req() req: { user: { id: string } },
    @Body() dto: { name?: string },
  ) {
    const user = await this.auth.updateProfile(req.user.id, {
      name: dto.name,
    });
    return {
      message: 'Perfil atualizado.',
      user: user
        ? {
            id: user.id,
            phoneNumber: user.phoneNumber,
            name: user.name,
            role: user.role,
            access: user.access,
            avatarPath: user.avatarPath,
          }
        : null,
    };
  }

  @Post('avatar')
  @UseGuards(JwtAuthGuard, DemoRestrictedGuard)
  @UseInterceptors(
    FileInterceptor('file', { limits: { fileSize: 10_000_000, files: 1 } }),
  )
  async uploadAvatar(
    @Req() req: { user: { id: string } },
    @UploadedFile() file: Express.Multer.File,
  ) {
    if (!file) throw new BadRequestException('Nenhum arquivo enviado');
    const { relativePath } = await this.upload.saveFile(
      file,
      UploadContext.Avatar,
    );
    const user = await this.auth.updateAvatar(req.user.id, relativePath);
    return {
      message: 'Foto do perfil atualizada.',
      user: user
        ? {
            id: user.id,
            phoneNumber: user.phoneNumber,
            name: user.name,
            role: user.role,
            avatarPath: user.avatarPath,
          }
        : null,
    };
  }

  @Get('avatar')
  @UseGuards(JwtAuthGuard)
  async getAvatar(
    @Query('path') relativePath: string,
    @Res() response: Response,
  ) {
    if (!relativePath) throw new BadRequestException('Caminho inválido');
    const signedUrl = await this.upload.createReadUrl(relativePath);
    if (signedUrl) return response.redirect(302, signedUrl);
    return response.sendFile(
      this.upload.resolveTenantPath(relativePath, UploadContext.Avatar),
    );
  }
}

function publicSession<T extends { accessToken: string; refreshToken: string }>(
  session: T,
): Omit<T, 'accessToken' | 'refreshToken'> {
  const {
    accessToken: _accessToken,
    refreshToken: _refreshToken,
    ...rest
  } = session;
  void _accessToken;
  void _refreshToken;
  return rest;
}
