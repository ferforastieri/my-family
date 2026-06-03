import type { Mapper } from '@shared/application/mapper';
import type {
  FamilyListEntity,
  FamilyListItemEntity,
} from '@shared/domain/entities';
import {
  FamilyListItemResponseDto,
  FamilyListResponseDto,
} from '../interfaces/dto/list.dto';

export class FamilyListMapper implements Mapper<
  FamilyListEntity,
  FamilyListResponseDto
> {
  toDto(source: FamilyListEntity): FamilyListResponseDto {
    return {
      id: source.id,
      title: source.title,
      description: source.description ?? null,
      createdBy: source.createdBy ?? null,
      createdAt: source.createdAt,
      updatedAt: source.updatedAt,
    };
  }
}

export class FamilyListItemMapper implements Mapper<
  FamilyListItemEntity,
  FamilyListItemResponseDto
> {
  toDto(source: FamilyListItemEntity): FamilyListItemResponseDto {
    return {
      id: source.id,
      listId: source.listId,
      text: source.text,
      checked: source.checked,
      createdBy: source.createdBy ?? null,
      createdAt: source.createdAt,
      updatedAt: source.updatedAt,
    };
  }
}

export const familyListMapper = new FamilyListMapper();
export const familyListItemMapper = new FamilyListItemMapper();
