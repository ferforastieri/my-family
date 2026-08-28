import { Injectable, BadRequestException } from '@nestjs/common';
import { Environment } from '@shared/infrastructure/environment/environment.module';
import * as fs from 'fs/promises';
import * as path from 'path';
import { createHash, randomUUID } from 'crypto';
import sharp from 'sharp';
import {
  DeleteObjectCommand,
  GetObjectCommand,
  HeadObjectCommand,
  ListObjectsV2Command,
  DeleteObjectsCommand,
  PutObjectCommand,
  S3Client,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { TenantContextService } from '../database/tenant-context';
import { createHmac } from 'crypto';

export enum UploadContext {
  Avatar = 'avatar',
  Fotos = 'fotos',
}

interface UploadResult {
  relativePath: string;
  filename: string;
}

@Injectable()
export class UploadService {
  private s3?: S3Client;
  private get basePath(): string {
    const p = this.env.uploadPath;
    return path.isAbsolute(p) ? p : path.resolve(p);
  }

  constructor(
    private env: Environment,
    private tenantContext: TenantContextService,
  ) {
    if (env.r2) {
      this.s3 = new S3Client({
        region: 'auto',
        endpoint: `https://${env.r2.accountId}.r2.cloudflarestorage.com`,
        credentials: {
          accessKeyId: env.r2.accessKeyId,
          secretAccessKey: env.r2.secretAccessKey,
        },
      });
    }
  }

  async saveFile(
    file: Express.Multer.File,
    context: UploadContext,
  ): Promise<UploadResult> {
    if (!file) {
      throw new BadRequestException('Arquivo não enviado');
    }
    const mime = file.mimetype?.toLowerCase() ?? '';
    const allowed =
      context === UploadContext.Avatar
        ? /^image\/(jpeg|png|webp)$/
        : /^image\/(jpeg|png|webp|gif)$|^video\/(mp4|webm)$/;
    if (!allowed.test(mime))
      throw new BadRequestException('Tipo de arquivo não permitido');
    const maxSize =
      context === UploadContext.Avatar
        ? 10_000_000
        : mime.startsWith('video/')
          ? 100_000_000
          : 25_000_000;
    if (file.size > maxSize)
      throw new BadRequestException('Arquivo excede o limite permitido');

    const shouldOptimizeImage =
      (context === UploadContext.Fotos || context === UploadContext.Avatar) &&
      mime.startsWith('image/') &&
      mime !== 'image/gif';
    const ext = shouldOptimizeImage ? '.webp' : extensionForMime(mime);
    const filename = `${randomUUID()}${ext}`;
    const tenantId = this.tenantContext.tenantId;
    if (!tenantId)
      throw new BadRequestException('Contexto de família obrigatório');
    const dir = path.join(this.basePath, 'tenants', tenantId, context);

    await fs.mkdir(dir, { recursive: true });
    const filePath = path.join(dir, filename);

    const data = file.buffer ?? (await fs.readFile((file as any).path));
    if (shouldOptimizeImage) {
      await sharp(data, { animated: false })
        .rotate()
        .resize({
          width: 1600,
          height: 1600,
          fit: 'inside',
          withoutEnlargement: true,
        })
        .webp({ quality: 82, effort: 5 })
        .toFile(filePath);
    } else {
      await fs.writeFile(filePath, data);
    }

    const relativePath = `tenants/${tenantId}/${context}/${filename}`;
    if (this.s3 && this.env.r2) {
      const contents = await fs.readFile(filePath);
      await this.s3.send(
        new PutObjectCommand({
          Bucket: this.env.r2.bucket,
          Key: relativePath,
          Body: contents,
          ContentType: shouldOptimizeImage ? 'image/webp' : file.mimetype,
        }),
      );
      await fs.unlink(filePath).catch(() => undefined);
    }
    return { relativePath, filename };
  }

  async createUploadUrl(context: UploadContext, contentType: string) {
    if (!this.s3 || !this.env.r2)
      throw new BadRequestException('Upload direto não configurado');
    if (!/^image\/(jpeg|png|webp|gif)$|^video\/(mp4|webm)$/.test(contentType))
      throw new BadRequestException('Tipo de arquivo não permitido');
    const tenantId = this.tenantContext.tenantId;
    if (!tenantId)
      throw new BadRequestException('Contexto de família obrigatório');
    const key = `quarantine/${tenantId}/${context}/${randomUUID()}`;
    const url = await getSignedUrl(
      this.s3,
      new PutObjectCommand({
        Bucket: this.env.r2.bucket,
        Key: key,
        ContentType: contentType,
      }),
      { expiresIn: 300 },
    );
    return { key, url, expiresIn: 300 };
  }

  async createReadUrl(relativePath: string) {
    if (!this.s3 || !this.env.r2) return null;
    const tenantId = this.tenantContext.tenantId;
    if (!tenantId || !relativePath.startsWith(`tenants/${tenantId}/`))
      throw new BadRequestException('Caminho inválido');
    if (this.env.r2.mediaBaseUrl && this.env.r2.signingSecret) {
      const expires = Math.floor(Date.now() / 1000) + 300;
      const signature = createHmac('sha256', this.env.r2.signingSecret)
        .update(`${relativePath}:${expires}`)
        .digest('hex');
      return `${this.env.r2.mediaBaseUrl.replace(/\/$/, '')}/${relativePath}?expires=${expires}&signature=${signature}`;
    }
    return getSignedUrl(
      this.s3,
      new GetObjectCommand({ Bucket: this.env.r2.bucket, Key: relativePath }),
      { expiresIn: 300 },
    );
  }

  async processMedia(relativePath: string) {
    const tenantId = this.tenantContext.tenantId;
    if (!tenantId)
      throw new BadRequestException('Contexto de família obrigatório');
    if (this.s3 && this.env.r2) {
      if (relativePath.startsWith(`tenants/${tenantId}/`)) {
        return {
          relativePath,
          processedAt: new Date().toISOString(),
          storage: 'r2',
        };
      }
      if (!relativePath.startsWith(`quarantine/${tenantId}/`))
        throw new BadRequestException('Objeto de quarentena inválido');
      const head = await this.s3.send(
        new HeadObjectCommand({
          Bucket: this.env.r2.bucket,
          Key: relativePath,
        }),
      );
      const contentType = head.ContentType?.toLowerCase() ?? '';
      const maxSize = contentType.startsWith('video/')
        ? 100_000_000
        : 25_000_000;
      if (!head.ContentLength || head.ContentLength > maxSize)
        throw new BadRequestException('Arquivo excede o limite permitido');
      if (!/^image\/(jpeg|png|webp|gif)$|^video\/(mp4|webm)$/.test(contentType))
        throw new BadRequestException('Tipo de arquivo não permitido');

      const object = await this.s3.send(
        new GetObjectCommand({ Bucket: this.env.r2.bucket, Key: relativePath }),
      );
      if (!object.Body) throw new BadRequestException('Arquivo não encontrado');
      const input = Buffer.from(await object.Body.transformToByteArray());
      const sha256 = createHash('sha256').update(input).digest('hex');
      const id = path.basename(relativePath);
      let finalPath: string;
      let thumbnail: string | undefined;
      if (contentType.startsWith('image/')) {
        const metadata = await sharp(input).metadata();
        if (!metadata.format) throw new BadRequestException('Imagem inválida');
        finalPath = `tenants/${tenantId}/fotos/${id}.webp`;
        thumbnail = `tenants/${tenantId}/thumbs/fotos/${id}.webp`;
        const [main, thumb] = await Promise.all([
          sharp(input)
            .rotate()
            .resize({
              width: 1600,
              height: 1600,
              fit: 'inside',
              withoutEnlargement: true,
            })
            .webp({ quality: 82, effort: 5 })
            .toBuffer(),
          sharp(input)
            .rotate()
            .resize({
              width: 480,
              height: 480,
              fit: 'inside',
              withoutEnlargement: true,
            })
            .webp({ quality: 80 })
            .toBuffer(),
        ]);
        await Promise.all([
          this.putR2(finalPath, main, 'image/webp'),
          this.putR2(thumbnail, thumb, 'image/webp'),
        ]);
      } else {
        const extension = contentType === 'video/webm' ? 'webm' : 'mp4';
        finalPath = `tenants/${tenantId}/fotos/${id}.${extension}`;
        await this.putR2(finalPath, input, contentType);
      }
      await this.s3.send(
        new DeleteObjectCommand({
          Bucket: this.env.r2.bucket,
          Key: relativePath,
        }),
      );
      return {
        relativePath: finalPath,
        thumbnail,
        size: head.ContentLength,
        sha256,
        processedAt: new Date().toISOString(),
        storage: 'r2',
      };
    }
    const fullPath = this.resolveTenantPath(relativePath);
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

  resolveTenantPath(relativePath: string, context?: UploadContext): string {
    const tenantId = this.tenantContext.tenantId;
    if (!tenantId)
      throw new BadRequestException('Contexto de família obrigatório');
    const prefix = `tenants/${tenantId}/${context ? `${context}/` : ''}`;
    if (!relativePath.startsWith(prefix))
      throw new BadRequestException('Caminho inválido');
    const resolved = path.resolve(this.basePath, relativePath);
    const allowed = path.resolve(this.basePath, prefix);
    if (resolved !== allowed && !resolved.startsWith(`${allowed}${path.sep}`))
      throw new BadRequestException('Caminho inválido');
    return resolved;
  }

  async removeFile(relativePath: string): Promise<void> {
    const tenantId = this.tenantContext.tenantId;
    if (!tenantId || !relativePath.startsWith(`tenants/${tenantId}/`)) {
      throw new BadRequestException('Caminho inválido');
    }
    if (this.s3 && this.env.r2) {
      await this.s3.send(
        new DeleteObjectCommand({
          Bucket: this.env.r2.bucket,
          Key: relativePath,
        }),
      );
      return;
    }
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

  async deleteTenantFiles(tenantId: string): Promise<void> {
    if (!/^[a-f\d]{24}$/i.test(tenantId))
      throw new BadRequestException('Tenant inválido');
    if (this.s3 && this.env.r2) {
      for (const prefix of [
        `tenants/${tenantId}/`,
        `quarantine/${tenantId}/`,
      ]) {
        let continuationToken: string | undefined;
        do {
          const page = await this.s3.send(
            new ListObjectsV2Command({
              Bucket: this.env.r2.bucket,
              Prefix: prefix,
              ContinuationToken: continuationToken,
            }),
          );
          const objects = (page.Contents ?? []).flatMap((item) =>
            item.Key ? [{ Key: item.Key }] : [],
          );
          if (objects.length) {
            await this.s3.send(
              new DeleteObjectsCommand({
                Bucket: this.env.r2.bucket,
                Delete: { Objects: objects, Quiet: true },
              }),
            );
          }
          continuationToken = page.IsTruncated
            ? page.NextContinuationToken
            : undefined;
        } while (continuationToken);
      }
      return;
    }
    await fs.rm(path.join(this.basePath, 'tenants', tenantId), {
      recursive: true,
      force: true,
    });
  }

  private putR2(key: string, body: Buffer, contentType: string) {
    if (!this.s3 || !this.env.r2) {
      throw new Error('Armazenamento R2 não configurado');
    }
    return this.s3.send(
      new PutObjectCommand({
        Bucket: this.env.r2.bucket,
        Key: key,
        Body: body,
        ContentType: contentType,
      }),
    );
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
}

function isImagePath(relativePath: string) {
  return /\.(png|jpe?g|webp|gif)$/i.test(relativePath);
}

function extensionForMime(mime: string) {
  const extensions: Record<string, string> = {
    'image/gif': '.gif',
    'video/mp4': '.mp4',
    'video/webm': '.webm',
  };
  const extension = extensions[mime];
  if (!extension) throw new BadRequestException('Tipo de arquivo inválido');
  return extension;
}
