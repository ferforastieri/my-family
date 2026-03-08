import { Injectable, BadRequestException } from '@nestjs/common';
import { Environment } from '@shared/infrastructure/environment/environment.module';
import * as fs from 'fs/promises';
import * as path from 'path';
import { randomUUID } from 'crypto';

/** Contextos de upload: cada valor é uma subpasta em UPLOAD_PATH (ex.: avatar -> {UPLOAD_PATH}/avatar/) */
export enum UploadContext {
  Avatar = 'avatar',
  Fotos = 'fotos',
  Galeria = 'galeria',
}

export function isUploadContext(value: string): value is UploadContext {
  return Object.values(UploadContext).includes(value as UploadContext);
}

export interface UploadResult {
  /** Caminho relativo para guardar no banco (ex.: avatar/abc123.jpg) */
  relativePath: string;
  /** Nome do arquivo salvo */
  filename: string;
}

@Injectable()
export class UploadService {
  /** Caminho absoluto no servidor onde os arquivos são salvos (valor de UPLOAD_PATH). */
  private get basePath(): string {
    const p = this.env.uploadPath;
    return path.isAbsolute(p) ? p : path.resolve(p);
  }

  constructor(private env: Environment) {}

  /**
   * Salva o arquivo em {UPLOAD_PATH}/{context}/ no servidor e retorna o caminho relativo (para o banco).
   * @param file arquivo do multer (memory ou disk)
   * @param context pasta-contexto (ex.: 'avatar')
   */
  async saveFile(file: Express.Multer.File, context: UploadContext): Promise<UploadResult> {
    if (!file) {
      throw new BadRequestException('Arquivo não enviado');
    }

    const ext = path.extname(file.originalname || '') || '.bin';
    const filename = `${randomUUID()}${ext}`;
    const dir = path.join(this.basePath, context);

    await fs.mkdir(dir, { recursive: true });
    const filePath = path.join(dir, filename);

    const data = file.buffer ?? (await fs.readFile((file as any).path));
    await fs.writeFile(filePath, data);

    const relativePath = `${context}/${filename}`;
    return { relativePath, filename };
  }

  /**
   * Retorna o caminho absoluto no disco do servidor para um caminho relativo salvo no banco.
   */
  resolvePath(relativePath: string): string {
    return path.join(this.basePath, relativePath);
  }

  /**
   * Remove arquivo pelo caminho relativo (ex.: avatar/abc123.jpg).
   */
  async removeFile(relativePath: string): Promise<void> {
    const fullPath = path.join(this.basePath, relativePath);
    try {
      await fs.unlink(fullPath);
    } catch {
      // ignora se arquivo não existir
    }
  }
}
