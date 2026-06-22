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
import { FotosService } from '../../application/services/fotos.service';
import { Access } from '@auth/decorators/access.decorator';
import { AccessGuard } from '@auth/guards/access.guard';
import { UploadService, UploadContext } from '@shared/infrastructure/upload';
import type { FotoWriteDto } from '../dto/foto.dto';

@Controller('fotos')
@UseGuards(AccessGuard)
@Access('memorias')
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
    if (!relativePath || !relativePath.includes('/fotos/')) {
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
  @UseGuards(AccessGuard)
  @Access('memorias')
  @UseInterceptors(FileInterceptor('file'))
  async uploadFile(@UploadedFile() file: Express.Multer.File) {
    if (!file) throw new BadRequestException('Nenhum arquivo enviado');
    const { relativePath } = await this.upload.saveFile(
      file,
      UploadContext.Fotos,
    );
    await this.fotosService.processUpload(relativePath);
    return { relativePath, message: 'Arquivo enviado com sucesso.' };
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.fotosService.findOne(id);
  }

  @Post()
  @UseGuards(AccessGuard)
  @Access('memorias')
  async create(@Body() data: FotoWriteDto) {
    const row = await this.fotosService.create(data);
    return { message: 'Memória salva com sucesso.', ...row };
  }

  @Put(':id')
  @UseGuards(AccessGuard)
  @Access('memorias')
  async update(@Param('id') id: string, @Body() data: Partial<FotoWriteDto>) {
    const row = await this.fotosService.update(id, data);
    return row ? { message: 'Memória atualizada.', ...row } : row;
  }

  @Delete(':id')
  @UseGuards(AccessGuard)
  @Access('memorias')
  async delete(@Param('id') id: string) {
    return {
      ok: await this.fotosService.delete(id),
      message: 'Memória removida.',
    };
  }
}
