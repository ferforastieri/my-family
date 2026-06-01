import { SetMetadata } from '@nestjs/common';
import type { UserRole } from '@shared/domain/entities';

export const ROLES_KEY = 'roles';

/**
 * Define quais roles podem acessar o endpoint.
 * Ex.: @Roles('admin') ou @Roles('admin', 'wife')
 */
export const Roles = (...roles: UserRole[]) => SetMetadata(ROLES_KEY, roles);
