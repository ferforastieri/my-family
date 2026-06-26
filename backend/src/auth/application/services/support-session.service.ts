import { ForbiddenException, Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { randomUUID } from 'node:crypto';
import { Model } from 'mongoose';
import {
  SupportSessionDocument,
  SupportSessionMongoDocument,
} from '../../infrastructure/persistence/support-session.schema';

@Injectable()
export class SupportSessionService {
  constructor(
    @InjectModel(SupportSessionDocument.name)
    private readonly sessions: Model<SupportSessionMongoDocument>,
  ) {}

  async create(data: {
    actorUserId: string;
    effectiveUserId: string;
    tenantId: string;
    reason: string;
  }) {
    const expiresAt = new Date(Date.now() + 30 * 60 * 1000);
    const document = await this.sessions.create({
      sessionId: randomUUID(),
      ...data,
      reason: data.reason.trim(),
      expiresAt,
    });
    return {
      sessionId: document.sessionId,
      actorUserId: document.actorUserId,
      effectiveUserId: document.effectiveUserId,
      tenantId: document.tenantId,
      reason: document.reason,
      expiresAt: document.expiresAt,
    };
  }

  async requireActive(sessionId: string) {
    const session = await this.sessions.findOne({ sessionId }).lean().exec();
    if (
      !session ||
      session.endedAt ||
      session.expiresAt.getTime() <= Date.now()
    ) {
      throw new ForbiddenException('Sessão de suporte expirada ou encerrada.');
    }
    return session;
  }

  async end(sessionId: string, actorUserId: string): Promise<void> {
    const result = await this.sessions.updateOne(
      { sessionId, actorUserId, endedAt: { $exists: false } },
      { $set: { endedAt: new Date() } },
    );
    if (!result.matchedCount) {
      throw new ForbiddenException('Sessão de suporte não encontrada.');
    }
  }
}
