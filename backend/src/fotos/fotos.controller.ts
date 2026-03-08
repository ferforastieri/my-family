import { Controller, Get, Post, Put, Delete, Body, Param, UseGuards, UseInterceptors, UploadedFile, Query, BadRequestException } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { StreamableFile } from '@nestjs/common';
import { createReadStream } from 'fs';
import { FotosService } from './fotos.service';
import { NewFoto } from '@shared/infrastructure/database/schema';
import { JwtAuthGuard } from '@auth/guards/jwt-auth.guard';
import { UploadService, UploadContext } from '@shared/infrastructure/upload';

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
    const type = ext === 'png' ? 'image/png' : ext === 'gif' ? 'image/gif' : ext === 'webp' ? 'image/webp' : ext === 'mp4' ? 'video/mp4' : ext === 'webm' ? 'video/webm' : 'image/jpeg';
    return new StreamableFile(file, { type });
  }

  @Post('upload')
  @UseGuards(JwtAuthGuard)
  @UseInterceptors(FileInterceptor('file'))
  async uploadFile(@UploadedFile() file: Express.Multer.File) {
    if (!file) throw new BadRequestException('Nenhum arquivo enviado');
    const { relativePath } = await this.upload.saveFile(file, UploadContext.Fotos);
    return { relativePath };
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.fotosService.findOne(id);
  }

  @Post()
  async create(@Body() data: NewFoto) {
    return this.fotosService.create(data);
  }

  @Put(':id')
  async update(@Param('id') id: string, @Body() data: Partial<NewFoto>) {
    return this.fotosService.update(id, data);
  }

  @Delete(':id')
  async delete(@Param('id') id: string) {
    return this.fotosService.delete(id);
  }
}


