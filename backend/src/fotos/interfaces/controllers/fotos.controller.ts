import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  Query,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { StreamableFile } from '@nestjs/common';
import { createReadStream } from 'fs';
import { FotosService } from '../../application/fotos.service';
import { JwtAuthGuard } from '@auth/guards/jwt-auth.guard';
import { UploadService, UploadContext } from '@shared/infrastructure/upload';
import type { FotoWriteDto } from '../dto/foto.dto';

@Controller('fotos')
export class FotosController {
  constructor(
    private readonly fotosService: FotosService,
    private readonly upload: UploadService,
  ) {}

  @Get()
  async findAll() {
    return this.fotosService.findAll();
  }

  @Get('file')
  getFile(@Query('path') relativePath: string) {
    if (!relativePath || !relativePath.startsWith('fotos/')) {
      throw new BadRequestException('Caminho inválido');
    }
    const fullPath = this.upload.resolvePath(relativePath);
    const file = createReadStream(fullPath);
    const ext = relativePath.split('.').pop()?.toLowerCase();
    const type =
      ext === 'png'
        ? 'image/png'
        : ext === 'gif'
          ? 'image/gif'
          : ext === 'webp'
            ? 'image/webp'
            : ext === 'mp4'
              ? 'video/mp4'
              : ext === 'webm'
                ? 'video/webm'
                : 'image/jpeg';
    return new StreamableFile(file, { type });
  }

  @Post('upload')
  @UseGuards(JwtAuthGuard)
  @UseInterceptors(FileInterceptor('file'))
  async uploadFile(@UploadedFile() file: Express.Multer.File) {
    if (!file) throw new BadRequestException('Nenhum arquivo enviado');
    const { relativePath } = await this.upload.saveFile(
      file,
      UploadContext.Fotos,
    );
    await this.fotosService.processUpload(relativePath);
    return { relativePath };
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.fotosService.findOne(id);
  }

  @Post()
  @UseGuards(JwtAuthGuard)
  async create(@Body() data: FotoWriteDto) {
    return this.fotosService.create(data);
  }

  @Put(':id')
  @UseGuards(JwtAuthGuard)
  async update(@Param('id') id: string, @Body() data: Partial<FotoWriteDto>) {
    return this.fotosService.update(id, data);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard)
  async delete(@Param('id') id: string) {
    return this.fotosService.delete(id);
  }
}
