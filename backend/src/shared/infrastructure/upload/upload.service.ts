import { Injectable, BadRequestException } from '@nestjs/common';
import { Environment } from '@shared/infrastructure/environment/environment.module';
import * as fs from 'fs/promises';
import * as path from 'path';
import { randomUUID } from 'crypto';
import sharp from 'sharp';

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

  async saveFile(
    file: Express.Multer.File,
    context: UploadContext,
  ): Promise<UploadResult> {
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

  async processMedia(relativePath: string) {
    const fullPath = this.resolvePath(relativePath);
    const stat = await fs.stat(fullPath);
    const metadataPath = `${fullPath}.meta.json`;
    const result: Record<string, unknown> = {
      relativePath,
      size: stat.size,
      processedAt: new Date().toISOString(),
    };

    if (isImagePath(relativePath)) {
      const image = sharp(fullPath);
      const metadata = await image.metadata();
      result.width = metadata.width ?? null;
      result.height = metadata.height ?? null;
      result.format = metadata.format ?? null;

      const thumbnailPath = this.thumbnailPath(relativePath);
      await fs.mkdir(path.dirname(thumbnailPath), { recursive: true });
      await image
        .resize({
          width: 480,
          height: 480,
          fit: 'inside',
          withoutEnlargement: true,
        })
        .webp({ quality: 82 })
        .toFile(thumbnailPath);
      result.thumbnail = this.relativeFromBase(thumbnailPath);
    }

    await fs.writeFile(metadataPath, JSON.stringify(result, null, 2));
    return result;
  }

  resolvePath(relativePath: string): string {
    return path.join(this.basePath, relativePath);
  }

  async removeFile(relativePath: string): Promise<void> {
    const fullPath = path.join(this.basePath, relativePath);
    try {
      await fs.unlink(fullPath);
    } catch {}
    try {
      await fs.unlink(`${fullPath}.meta.json`);
    } catch {}
    try {
      await fs.unlink(this.thumbnailPath(relativePath));
    } catch {}
  }

  async removeOrphanFiles(
    context: UploadContext,
    referencedPaths: Set<string>,
    olderThanMs: number,
  ) {
    const dir = path.join(this.basePath, context);
    const removed: string[] = [];
    const cutoff = Date.now() - olderThanMs;
    for (const relativePath of await this.listRelativeFiles(dir, context)) {
      if (
        relativePath.endsWith('.meta.json') ||
        relativePath.startsWith('thumbs/')
      )
        continue;
      if (referencedPaths.has(relativePath)) continue;
      const fullPath = this.resolvePath(relativePath);
      const stat = await fs.stat(fullPath);
      if (stat.mtimeMs > cutoff) continue;
      await this.removeFile(relativePath);
      removed.push(relativePath);
    }
    return removed;
  }

  private thumbnailPath(relativePath: string) {
    const parsed = path.parse(relativePath);
    return path.join(
      this.basePath,
      'thumbs',
      parsed.dir,
      `${parsed.name}.webp`,
    );
  }

  private relativeFromBase(fullPath: string) {
    return path.relative(this.basePath, fullPath).replace(/\\/g, '/');
  }

  private async listRelativeFiles(
    dir: string,
    context: UploadContext,
  ): Promise<string[]> {
    let entries: Array<{ name: string; isDirectory(): boolean }>;
    try {
      entries = (await fs.readdir(dir, {
        withFileTypes: true,
      })) as unknown as Array<{
        name: string;
        isDirectory(): boolean;
      }>;
    } catch {
      return [];
    }
    const files: string[] = [];
    for (const entry of entries) {
      const entryName = String(entry.name);
      const entryPath = path.join(dir, entryName);
      if (entry.isDirectory()) {
        files.push(...(await this.listRelativeFiles(entryPath, context)));
      } else {
        files.push(
          path
            .relative(path.join(this.basePath, context, '..'), entryPath)
            .replace(/\\/g, '/'),
        );
      }
    }
    return files;
  }
}

function isImagePath(relativePath: string) {
  return /\.(png|jpe?g|webp|gif)$/i.test(relativePath);
}
