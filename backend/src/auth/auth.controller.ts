import { Controller, Post, Get, Body, UseGuards, Req, UseInterceptors, UploadedFile, BadRequestException, Query } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { AuthService } from './auth.service';
import { RegisterDto } from './auth.dto';
import { LocalAuthGuard } from './guards/local-auth.guard';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { UploadService, UploadContext } from '@shared/infrastructure/upload';
import { StreamableFile } from '@nestjs/common';
import { createReadStream } from 'fs';

@Controller('auth')
export class AuthController {
  constructor(
    private auth: AuthService,
    private upload: UploadService,
  ) {}

  @Post('register')
  async register(@Body() dto: RegisterDto) {
    return this.auth.register(dto.email, dto.password, dto.name, dto.role);
  }

  @Post('login')
  @UseGuards(LocalAuthGuard)
  async login(@Req() req: { user: { id: number; email: string; name: string | null } }) {
    return this.auth.tokenResponse(req.user as any);
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  async me(@Req() req: { user: { id: number; email: string; name: string | null; role: string; avatarPath?: string | null } }) {
    const { id, email, name, role, avatarPath } = req.user;
    return { user: { id, email, name, role, avatarPath } };
  }

  @Post('avatar')
  @UseGuards(JwtAuthGuard)
  @UseInterceptors(FileInterceptor('file'))
  async uploadAvatar(
    @Req() req: { user: { id: number } },
    @UploadedFile() file: Express.Multer.File,
  ) {
    if (!file) throw new BadRequestException('Nenhum arquivo enviado');
    const { relativePath } = await this.upload.saveFile(file, UploadContext.Avatar);
    const user = await this.auth.updateAvatar(req.user.id, relativePath);
    return { user: user ? { id: user.id, email: user.email, name: user.name, role: user.role, avatarPath: user.avatarPath } : null };
  }

  @Post('forgot-password')
  async forgotPassword(@Body('email') email: string) {
    if (!email) throw new BadRequestException('Email é obrigatório');
    await this.auth.requestPasswordReset(email);
    return { success: true, message: 'Se o email existir, você receberá um token de recuperação por email.' };
  }

  @Post('reset-password')
  async resetPassword(@Body() body: { token: string; newPassword: string }) {
    const { token, newPassword } = body;
    if (!token || !newPassword) throw new BadRequestException('Token e nova senha são obrigatórios');
    await this.auth.resetPassword(token, newPassword);
    return { success: true, message: 'Senha redefinida com sucesso.' };
  }

  @Get('avatar')
  getAvatar(@Query('path') relativePath: string) {
    if (!relativePath || !relativePath.startsWith('avatar/')) {
      throw new BadRequestException('Caminho inválido');
    }
    const fullPath = this.upload.resolvePath(relativePath);
    const file = createReadStream(fullPath);
    const ext = relativePath.split('.').pop()?.toLowerCase();
    const type = ext === 'png' ? 'image/png' : ext === 'gif' ? 'image/gif' : ext === 'webp' ? 'image/webp' : 'image/jpeg';
    return new StreamableFile(file, { type });
  }
}
