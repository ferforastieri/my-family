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
  Res,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import type { Response } from 'express';
import { FotosService } from '../../application/services/fotos.service';
import { Access } from '@auth/decorators/access.decorator';
import { AccessGuard } from '@auth/guards/access.guard';
import { JwtAuthGuard } from '@auth/guards/jwt-auth.guard';
import { UploadService, UploadContext } from '@shared/infrastructure/upload';
import { FotoWriteDto } from '../dto/foto.dto';
import type { PaginationQuery } from '@shared/infrastructure/database/mongo.utils';
import { DemoRestrictedGuard } from '@tenancy/interfaces/demo-restricted.guard';

@Controller('fotos')
@UseGuards(JwtAuthGuard, AccessGuard)
@Access('memorias')
export class FotosController {
  constructor(
    private readonly fotosService: FotosService,
    private readonly upload: UploadService,
  ) {}

  @Get()
  async findAll(@Query() query: PaginationQuery) {
    return this.fotosService.findAll(query);
  }

  @Get('albums')
  async findAlbums() {
    return this.fotosService.findAlbums();
  }

  @Post('upload-url')
  @UseGuards(DemoRestrictedGuard)
  createUploadUrl(@Body() body: { contentType: string }) {
    return this.upload.createUploadUrl(UploadContext.Fotos, body.contentType);
  }

  @Post('upload-complete')
  @UseGuards(DemoRestrictedGuard)
  completeDirectUpload(@Body('key') key: string) {
    if (!key) throw new BadRequestException('Chave do arquivo é obrigatória');
    return this.fotosService.processUpload(key);
  }

  @Get('upload-status/:jobId')
  uploadStatus(@Param('jobId') jobId: string) {
    return this.fotosService.uploadStatus(jobId);
  }

  @Get('file-url')
  async getFileUrl(@Query('path') relativePath: string) {
    return { url: await this.upload.createReadUrl(relativePath) };
  }

  @Get('file')
  async getFile(
    @Query('path') relativePath: string,
    @Res() response: Response,
  ) {
    if (!relativePath) throw new BadRequestException('Caminho inválido');
    const signedUrl = await this.upload.createReadUrl(relativePath);
    if (signedUrl) return response.redirect(302, signedUrl);
    return response.sendFile(
      this.upload.resolveTenantPath(relativePath, UploadContext.Fotos),
    );
  }

  @Post('upload')
  @UseGuards(DemoRestrictedGuard)
  @UseInterceptors(
    FileInterceptor('file', { limits: { fileSize: 100_000_000, files: 1 } }),
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
  async create(@Body() data: FotoWriteDto) {
    const row = await this.fotosService.create(data);
    return { message: 'Memória salva com sucesso.', ...row };
  }

  @Put(':id')
  async update(@Param('id') id: string, @Body() data: Partial<FotoWriteDto>) {
    const row = await this.fotosService.update(id, data);
    return row ? { message: 'Memória atualizada.', ...row } : row;
  }

  @Delete(':id')
  async delete(@Param('id') id: string) {
    return {
      ok: await this.fotosService.delete(id),
      message: 'Memória removida.',
    };
  }
}
