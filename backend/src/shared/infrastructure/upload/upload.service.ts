import { Injectable, BadRequestException } from '@nestjs/common';
import { Environment } from '@shared/infrastructure/environment/environment.module';
import * as fs from 'fs/promises';
import * as path from 'path';
import { randomUUID } from 'crypto';

export enum UploadContext {
  Avatar = 'avatar',
  Fotos = 'fotos',
  Galeria = 'galeria',
}

export function isUploadContext(value: string): value is UploadContext {
  return Object.values(UploadContext).includes(value as UploadContext);
}

export interface UploadResult {
  relativePath: string;
  filename: string;
}

@Injectable()
export class UploadService {
  private get basePath(): string {
    const p = this.env.uploadPath;
    return path.isAbsolute(p) ? p : path.resolve(p);
  }

  constructor(private env: Environment) {}

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

  resolvePath(relativePath: string): string {
    return path.join(this.basePath, relativePath);
  }

  async removeFile(relativePath: string): Promise<void> {
    const fullPath = path.join(this.basePath, relativePath);
    try {
      await fs.unlink(fullPath);
    } catch {
    }
  }
}
