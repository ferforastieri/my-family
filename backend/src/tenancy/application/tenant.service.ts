import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { userAccessKeys } from '@auth/domain/entities/user.entity';
import type { TenantLocale } from '../domain/tenant.entity';
import { isTenantAdmin } from '../domain/tenant.entity';
import { TenantContext } from './tenant-context';
import { TenantRepository } from '../infrastructure/tenant.repository';

@Injectable()
export class TenantService {
  constructor(
    private repository: TenantRepository,
    private context: TenantContext,
  ) {}

  async createForOwner(data: {
    ownerUserId: string;
    name: string;
    slug?: string;
    defaultLocale?: TenantLocale;
    status?: 'draft' | 'pending_payment' | 'active';
    isDemo?: boolean;
    isPublished?: boolean;
  }) {
    const slug = normalizeSlug(data.slug || data.name);
    if (slug.length < 3) {
      throw new BadRequestException(
        'Escolha um endereço com ao menos 3 caracteres.',
      );
    }
    if (await this.repository.findTenantBySlug(slug)) {
      throw new ConflictException('Este endereço já está sendo utilizado.');
    }
    const tenant = await this.repository.createTenant({
      name: data.name.trim(),
      slug,
      ownerUserId: data.ownerUserId,
      defaultLocale: data.defaultLocale ?? 'pt-BR',
      status: data.status ?? 'pending_payment',
      isDemo: data.isDemo ?? false,
      isPublished: data.isPublished ?? false,
    });
    try {
      const membership = await this.repository.createMembership({
        tenantId: tenant.id,
        userId: data.ownerUserId,
        role: 'owner',
        access: [...userAccessKeys],
      });
      return { tenant, membership };
    } catch (error) {
      await this.repository.deleteTenant(tenant.id);
      throw error;
    }
  }

  async current() {
    const tenant = await this.repository.findTenantById(this.context.tenantId);
    if (!tenant) throw new NotFoundException('Família não encontrada.');
    return tenant;
  }

  async updateCurrent(data: {
    name?: string;
    slug?: string;
    defaultLocale?: TenantLocale;
    theme?: Record<string, unknown>;
  }) {
    this.requireAdmin();
    const update = { ...data };
    if (update.slug) {
      update.slug = normalizeSlug(update.slug);
      const existing = await this.repository.findTenantBySlug(update.slug);
      if (existing && existing.id !== this.context.tenantId) {
        throw new ConflictException('Este endereço já está sendo utilizado.');
      }
    }
    return this.repository.updateTenant(this.context.tenantId, update);
  }

  async setPublished(isPublished: boolean) {
    this.requireAdmin();
    const tenant = await this.current();
    if (isPublished && tenant.status !== 'active' && !tenant.isDemo) {
      throw new ForbiddenException(
        'A assinatura precisa estar ativa antes da publicação.',
      );
    }
    return this.repository.updateTenant(tenant.id, { isPublished });
  }

  async publicBySlug(slug: string) {
    const tenant = await this.repository.findTenantBySlug(normalizeSlug(slug));
    if (
      !tenant ||
      !tenant.isPublished ||
      (tenant.status !== 'active' && !tenant.isDemo)
    ) {
      throw new NotFoundException('Site não encontrado.');
    }
    return tenant;
  }

  async assertEntitled(tenantId = this.context.tenantId) {
    const tenant = await this.repository.findTenantById(tenantId);
    if (!tenant || (tenant.status !== 'active' && !tenant.isDemo)) {
      throw new ForbiddenException('Assinatura inativa para esta família.');
    }
    return tenant;
  }

  private requireAdmin() {
    if (!isTenantAdmin(this.context.current.role)) {
      throw new ForbiddenException('Acesso administrativo obrigatório.');
    }
  }
}

export function normalizeSlug(input: string): string {
  return input
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 60);
}
