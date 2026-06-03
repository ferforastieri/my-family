export interface FamilyListEntity {
  id: string;
  title: string;
  description?: string | null;
  createdBy?: string | null;
  createdAt: Date;
  updatedAt: Date;
}

export interface FamilyListItemEntity {
  id: string;
  listId: string;
  text: string;
  checked: boolean;
  createdBy?: string | null;
  createdAt: Date;
  updatedAt: Date;
}
