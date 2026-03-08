import { Controller, Post, Get, Body, UseGuards, Req } from '@nestjs/common';
import { AuthService } from './auth.service';
import { RegisterDto } from './auth.dto';
import { LocalAuthGuard } from './guards/local-auth.guard';
import { JwtAuthGuard } from './guards/jwt-auth.guard';

@Controller('auth')
export class AuthController {
  constructor(private auth: AuthService) {}

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
  async me(@Req() req: { user: { id: number; email: string; name: string | null; role: string } }) {
    const { id, email, name, role } = req.user;
    return { user: { id, email, name, role } };
  }
}
