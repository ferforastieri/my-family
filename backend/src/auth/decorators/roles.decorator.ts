import { SetMetadata } from '@nestjs/common';
import type { UserRole } from '@auth/domain/entities/user.entity';

export const ROLES_KEY = 'roles';

/**
 * Define quais roles podem acessar o endpoint.
 * Ex.: @Roles('marido', 'esposa')
 */
export const Roles = (...roles: UserRole[]) => SetMetadata(ROLES_KEY, roles);
