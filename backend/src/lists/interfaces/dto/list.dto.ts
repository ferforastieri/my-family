import { IsBoolean, IsOptional, IsString } from 'class-validator';
import { PartialType } from '@nestjs/mapped-types';
import { Type } from 'class-transformer';
import { ValidateNested } from 'class-validator';
import { PaginationMessageDto } from '@shared/interfaces/websocket/websocket.dto';

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

export class FamilyListUpdateDto extends PartialType(FamilyListWriteDto) {}
export class FamilyListItemUpdateDto extends PartialType(
  FamilyListItemWriteDto,
) {}

export class FamilyListUpdateMessageDto {
  @IsString()
  id: string;

  @ValidateNested()
  @Type(() => FamilyListUpdateDto)
  data: FamilyListUpdateDto;
}

export class FamilyListItemUpdateMessageDto {
  @IsString()
  id: string;

  @ValidateNested()
  @Type(() => FamilyListItemUpdateDto)
  data: FamilyListItemUpdateDto;
}

export class FamilyListItemsQueryDto extends PaginationMessageDto {
  @IsString()
  listId: string;
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
