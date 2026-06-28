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
import { FotosService } from '../../application/services/fotos.service';
import { Access } from '@auth/decorators/access.decorator';
import { AccessGuard } from '@auth/guards/access.guard';
import {
  mediaType,
  MAX_UPLOAD_BYTES,
  UploadService,
  UploadContext,
} from '@shared/infrastructure/upload';
import { FotoUpdateDto, FotoWriteDto } from '../dto/foto.dto';
import { PaginationMessageDto } from '@shared/interfaces/websocket/websocket.dto';

@Controller('fotos')
@UseGuards(AccessGuard)
@Access('memorias')
export class FotosController {
  constructor(
    private readonly fotosService: FotosService,
    private readonly upload: UploadService,
  ) {}

  @Get()
  async findAll(@Query() query: PaginationMessageDto) {
    return this.fotosService.findAll(query);
  }

  @Get('albums')
  async albums() {
    return this.fotosService.findAlbums();
  }

  @Get('file')
  async getFile(@Query('path') relativePath: string) {
    if (!relativePath || !relativePath.includes('/fotos/')) {
      throw new BadRequestException('Caminho inválido');
    }
    const file = await this.upload.openFile(relativePath);
    return new StreamableFile(file.stream, {
      type: file.contentType || mediaType(relativePath),
      length: file.contentLength,
    });
  }

  @Post('upload')
  @UseGuards(AccessGuard)
  @Access('memorias')
  @UseInterceptors(
    FileInterceptor('file', {
      limits: { fileSize: MAX_UPLOAD_BYTES, files: 1, fields: 5 },
    }),
  )
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
  async update(@Param('id') id: string, @Body() data: FotoUpdateDto) {
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
