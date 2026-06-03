import { IsBoolean, IsOptional, IsString } from 'class-validator';

export class FamilyListWriteDto {
  @IsString()
  title: string;

  @IsOptional()
  @IsString()
  description?: string | null;
}

export class FamilyListItemWriteDto {
  @IsString()
  listId: string;

  @IsString()
  text: string;

  @IsOptional()
  @IsBoolean()
  checked?: boolean;
}

export class FamilyListResponseDto {
  id: string;
  title: string;
  description: string | null;
  createdBy: string | null;
  createdAt: Date;
  updatedAt: Date;
}

export class FamilyListItemResponseDto {
  id: string;
  listId: string;
  text: string;
  checked: boolean;
  createdBy: string | null;
  createdAt: Date;
  updatedAt: Date;
}
