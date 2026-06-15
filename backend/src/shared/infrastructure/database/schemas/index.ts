export * from './carta.schema';
export * from './chat-conversation.schema';
export * from './chat-message.schema';
export * from './foto.schema';
export * from './family-list.schema';
export * from './family-list-item.schema';
export * from './game-completion.schema';
export * from './mini-game-config.schema';
export * from './game-word.schema';
export * from './home-settings.schema';
export * from './location-update.schema';
export * from './location-place.schema';
export * from './location-presence.schema';
export * from './musica.schema';
export * from './notification.schema';
export * from './password-reset.schema';
export * from './push-subscription.schema';
export * from './user.schema';
export * from './quiz-question.schema';
export * from './scheduled-notification.schema';

import { CartaDocument, CartaSchema } from './carta.schema';
import {
  ChatConversationDocument,
  ChatConversationSchema,
} from './chat-conversation.schema';
import { ChatMessageDocument, ChatMessageSchema } from './chat-message.schema';
import { FotoDocument, FotoSchema } from './foto.schema';
import { FamilyListDocument, FamilyListSchema } from './family-list.schema';
import {
  FamilyListItemDocument,
  FamilyListItemSchema,
} from './family-list-item.schema';
import {
  GameCompletionDocument,
  GameCompletionSchema,
} from './game-completion.schema';
import {
  MiniGameConfigDocument,
  MiniGameConfigSchema,
} from './mini-game-config.schema';
import { GameWordDocument, GameWordSchema } from './game-word.schema';
import {
  HomeSettingsDocument,
  HomeSettingsSchema,
} from './home-settings.schema';
import {
  LocationUpdateDocument,
  LocationUpdateSchema,
} from './location-update.schema';
import {
  LocationPlaceDocument,
  LocationPlaceSchema,
} from './location-place.schema';
import {
  LocationPresenceDocument,
  LocationPresenceSchema,
} from './location-presence.schema';
import { MusicaDocument, MusicaSchema } from './musica.schema';
import {
  NotificationDocument,
  NotificationSchema,
} from './notification.schema';
import {
  PasswordResetDocument,
  PasswordResetSchema,
} from './password-reset.schema';
import {
  PushSubscriptionDocument,
  PushSubscriptionSchema,
} from './push-subscription.schema';
import { UserDocument, UserSchema } from './user.schema';
import {
  QuizQuestionDocument,
  QuizQuestionSchema,
} from './quiz-question.schema';
import {
  ScheduledNotificationDocument,
  ScheduledNotificationSchema,
} from './scheduled-notification.schema';

export const mongoModels = [
  { name: UserDocument.name, schema: UserSchema },
  { name: PasswordResetDocument.name, schema: PasswordResetSchema },
  { name: ChatConversationDocument.name, schema: ChatConversationSchema },
  { name: ChatMessageDocument.name, schema: ChatMessageSchema },
  { name: FotoDocument.name, schema: FotoSchema },
  { name: FamilyListDocument.name, schema: FamilyListSchema },
  { name: FamilyListItemDocument.name, schema: FamilyListItemSchema },
  { name: GameCompletionDocument.name, schema: GameCompletionSchema },
  { name: MiniGameConfigDocument.name, schema: MiniGameConfigSchema },
  { name: GameWordDocument.name, schema: GameWordSchema },
  { name: HomeSettingsDocument.name, schema: HomeSettingsSchema },
  { name: LocationUpdateDocument.name, schema: LocationUpdateSchema },
  { name: LocationPlaceDocument.name, schema: LocationPlaceSchema },
  { name: LocationPresenceDocument.name, schema: LocationPresenceSchema },
  { name: MusicaDocument.name, schema: MusicaSchema },
  { name: CartaDocument.name, schema: CartaSchema },
  { name: NotificationDocument.name, schema: NotificationSchema },
  { name: PushSubscriptionDocument.name, schema: PushSubscriptionSchema },
  { name: QuizQuestionDocument.name, schema: QuizQuestionSchema },
  {
    name: ScheduledNotificationDocument.name,
    schema: ScheduledNotificationSchema,
  },
];
