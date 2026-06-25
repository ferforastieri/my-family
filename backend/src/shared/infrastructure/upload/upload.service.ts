import {
  BadRequestException,
  Injectable,
  PayloadTooLargeException,
} from '@nestjs/common';
import {
  DeleteObjectCommand,
  GetObjectCommand,
  ListObjectsV2Command,
  PutObjectCommand,
  S3Client,
} from '@aws-sdk/client-s3';
import { randomUUID } from 'node:crypto';
import * as path from 'node:path';
import type { Readable } from 'node:stream';
import sharp from 'sharp';
import { TenantContext } from '@tenancy/application/tenant-context';
import { Environment } from '@shared/infrastructure/environment/environment.module';

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

export interface StoredFile {
  stream: Readable;
  contentType: string;
  contentLength?: number;
}

export const MAX_UPLOAD_BYTES = 40 * 1024 * 1024;

@Injectable()
export class UploadService {
  private readonly s3: S3Client;

  constructor(
    private env: Environment,
    private tenantContext: TenantContext,
  ) {
    this.s3 = new S3Client({
      endpoint: env.storage.endpoint,
      region: env.storage.region,
      credentials: {
        accessKeyId: env.storage.accessKeyId,
        secretAccessKey: env.storage.secretAccessKey,
      },
    });
  }

  async saveFile(
    file: Express.Multer.File,
    context: UploadContext,
  ): Promise<UploadResult> {
    if (!file) throw new BadRequestException('Arquivo não enviado');

    const inputExt = path.extname(file.originalname || '') || '.bin';
    const shouldOptimizeImage =
      (context === UploadContext.Fotos || context === UploadContext.Avatar) &&
      isCompressibleImage(file, inputExt);
    const ext = shouldOptimizeImage ? '.webp' : inputExt.toLowerCase();
    const filename = `${randomUUID()}${ext}`;
    const relativePath = `tenants/${this.tenantContext.tenantId}/${context}/${filename}`;
    const input = file.buffer;
    if (!input) {
      throw new BadRequestException('Upload em memória não configurado.');
    }
    if (input.length > MAX_UPLOAD_BYTES) {
      throw new PayloadTooLargeException('O arquivo deve ter no máximo 40 MB.');
    }
    const data = shouldOptimizeImage
      ? await sharp(input, { animated: false })
          .rotate()
          .resize({
            width: 1600,
            height: 1600,
            fit: 'inside',
            withoutEnlargement: true,
          })
          .webp({ quality: 82, effort: 5 })
          .toBuffer()
      : input;

    await this.write(
      relativePath,
      data,
      shouldOptimizeImage
        ? 'image/webp'
        : file.mimetype || mediaType(relativePath),
    );
    return { relativePath, filename };
  }

  async openFile(relativePath: string): Promise<StoredFile> {
    return this.openTenantFile(this.tenantContext.tenantId, relativePath);
  }

  async openTenantFile(
    tenantId: string,
    relativePath: string,
  ): Promise<StoredFile> {
    const key = this.normalizeTenantPath(tenantId, relativePath);
    const response = await this.s3.send(
      new GetObjectCommand({ Bucket: this.env.storage.bucket, Key: key }),
    );
    if (!response.Body) throw new Error(`Arquivo sem conteúdo: ${key}`);
    return {
      stream: response.Body as Readable,
      contentType: response.ContentType || mediaType(key),
      contentLength: response.ContentLength,
    };
  }

  async processMedia(relativePath: string) {
    const key = this.normalizeTenantPath(
      this.tenantContext.tenantId,
      relativePath,
    );
    const data = await this.read(key);
    const result: Record<string, unknown> = {
      relativePath: key,
      size: data.length,
      processedAt: new Date().toISOString(),
    };

    if (isImagePath(key)) {
      const image = sharp(data);
      const metadata = await image.metadata();
      result.width = metadata.width ?? null;
      result.height = metadata.height ?? null;
      result.format = metadata.format ?? null;

      const thumbnail = await image
        .resize({
          width: 480,
          height: 480,
          fit: 'inside',
          withoutEnlargement: true,
        })
        .webp({ quality: 82 })
        .toBuffer();
      const thumbnailPath = this.thumbnailPath(key);
      await this.write(thumbnailPath, thumbnail, 'image/webp');
      result.thumbnail = thumbnailPath;
    }

    await this.write(
      `${key}.meta.json`,
      Buffer.from(JSON.stringify(result, null, 2)),
      'application/json',
    );
    return result;
  }

  async removeFile(relativePath: string): Promise<void> {
    const key = this.normalizeTenantPath(
      this.tenantContext.tenantId,
      relativePath,
    );
    await Promise.all([
      this.remove(key),
      this.remove(`${key}.meta.json`),
      this.remove(this.thumbnailPath(key)),
    ]);
  }

  async removeOrphanFiles(
    context: UploadContext,
    referencedPaths: Set<string>,
    olderThanMs: number,
  ) {
    const tenantId = this.tenantContext.tenantId;
    const prefix = `tenants/${tenantId}/${context}/`;
    const removed: string[] = [];
    const cutoff = Date.now() - olderThanMs;

    for (const stored of await this.list(prefix)) {
      if (stored.key.endsWith('.meta.json')) continue;
      if (referencedPaths.has(stored.key)) continue;
      if (stored.modifiedAt > cutoff) continue;
      await this.removeFile(stored.key);
      removed.push(stored.key);
    }
    return removed;
  }

  private normalizeTenantPath(tenantId: string, relativePath: string): string {
    const normalized = relativePath.replace(/\\/g, '/').replace(/^\/+/, '');
    const prefix = `tenants/${tenantId}/`;
    if (!normalized.startsWith(prefix) || normalized.includes('../')) {
      throw new BadRequestException('Caminho de mídia inválido.');
    }
    return normalized;
  }

  private async read(key: string): Promise<Buffer> {
    const response = await this.s3.send(
      new GetObjectCommand({ Bucket: this.env.storage.bucket, Key: key }),
    );
    if (!response.Body) throw new Error(`Arquivo sem conteúdo: ${key}`);
    return Buffer.from(await response.Body.transformToByteArray());
  }

  private async write(key: string, data: Buffer, contentType: string) {
    await this.s3.send(
      new PutObjectCommand({
        Bucket: this.env.storage.bucket,
        Key: key,
        Body: data,
        ContentType: contentType,
      }),
    );
  }

  private async remove(key: string) {
    await this.s3.send(
      new DeleteObjectCommand({ Bucket: this.env.storage.bucket, Key: key }),
    );
  }

  private async list(prefix: string) {
    const files: Array<{ key: string; modifiedAt: number }> = [];
    let continuationToken: string | undefined;
    do {
      const page = await this.s3.send(
        new ListObjectsV2Command({
          Bucket: this.env.storage.bucket,
          Prefix: prefix,
          ContinuationToken: continuationToken,
        }),
      );
      for (const item of page.Contents ?? []) {
        if (!item.Key) continue;
        files.push({
          key: item.Key,
          modifiedAt: item.LastModified?.getTime() ?? 0,
        });
      }
      continuationToken = page.IsTruncated
        ? page.NextContinuationToken
        : undefined;
    } while (continuationToken);
    return files;
  }

  private thumbnailPath(relativePath: string) {
    const parsed = path.posix.parse(relativePath);
    return path.posix.join('thumbs', parsed.dir, `${parsed.name}.webp`);
  }
}

export function mediaType(relativePath: string) {
  const extension = path.extname(relativePath).toLowerCase();
  if (extension === '.png') return 'image/png';
  if (extension === '.gif') return 'image/gif';
  if (extension === '.webp') return 'image/webp';
  if (extension === '.mp4') return 'video/mp4';
  if (extension === '.webm') return 'video/webm';
  if (extension === '.json') return 'application/json';
  return 'image/jpeg';
}

function isImagePath(relativePath: string) {
  return /\.(png|jpe?g|webp|gif)$/i.test(relativePath);
}

function isCompressibleImage(file: Express.Multer.File, ext: string) {
  const mimetype = file.mimetype?.toLowerCase() ?? '';
  const normalizedExt = ext.toLowerCase();
  if (mimetype === 'image/gif' || normalizedExt === '.gif') return false;
  return (
    mimetype.startsWith('image/') ||
    ['.png', '.jpg', '.jpeg', '.webp', '.heic', '.heif'].includes(normalizedExt)
  );
}
