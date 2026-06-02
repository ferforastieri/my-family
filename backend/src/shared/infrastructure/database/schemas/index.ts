export * from './carta.schema';
export * from './foto.schema';
export * from './musica.schema';
export * from './notification.schema';
export * from './password-reset.schema';
export * from './push-subscription.schema';
export * from './user.schema';

import { CartaDocument, CartaSchema } from './carta.schema';
import { FotoDocument, FotoSchema } from './foto.schema';
import { MusicaDocument, MusicaSchema } from './musica.schema';
import { NotificationDocument, NotificationSchema } from './notification.schema';
import { PasswordResetDocument, PasswordResetSchema } from './password-reset.schema';
import { PushSubscriptionDocument, PushSubscriptionSchema } from './push-subscription.schema';
import { UserDocument, UserSchema } from './user.schema';

export const mongoModels = [
  { name: UserDocument.name, schema: UserSchema },
  { name: PasswordResetDocument.name, schema: PasswordResetSchema },
  { name: FotoDocument.name, schema: FotoSchema },
  { name: MusicaDocument.name, schema: MusicaSchema },
  { name: CartaDocument.name, schema: CartaSchema },
  { name: NotificationDocument.name, schema: NotificationSchema },
  { name: PushSubscriptionDocument.name, schema: PushSubscriptionSchema },
];

