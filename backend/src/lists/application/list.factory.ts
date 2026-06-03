import type { Factory } from '@shared/application/mapper';
import type {
  FamilyListItemWrite,
  FamilyListWrite,
} from '../infrastructure/repositories/lists.repository';
import type {
  FamilyListItemWriteDto,
  FamilyListWriteDto,
} from '../interfaces/dto/list.dto';

export class FamilyListFactory implements Factory<
  Partial<FamilyListWriteDto>,
  Partial<FamilyListWrite>
> {
  create(input: Partial<FamilyListWriteDto>): Partial<FamilyListWrite> {
    return {
      title: input.title?.trim(),
      description: input.description?.trim() || null,
    };
  }
}

export class FamilyListItemFactory implements Factory<
  Partial<FamilyListItemWriteDto>,
  Partial<FamilyListItemWrite>
> {
  create(input: Partial<FamilyListItemWriteDto>): Partial<FamilyListItemWrite> {
    return {
      listId: input.listId,
      text: input.text?.trim(),
      checked: input.checked,
    };
  }
}

export const familyListFactory = new FamilyListFactory();
export const familyListItemFactory = new FamilyListItemFactory();
