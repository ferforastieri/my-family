export const CARTA_NOTIFIER = Symbol('CARTA_NOTIFIER');

export interface CartaNotifierPort {
  letterCreated(title: string, authorName: string): Promise<void>;
}
