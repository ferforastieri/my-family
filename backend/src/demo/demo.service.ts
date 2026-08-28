import { Injectable, OnModuleInit } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';
import { randomInt, randomUUID } from 'node:crypto';
import {
  CartaDocument,
  CartaMongoDocument,
  FamilyListDocument,
  FamilyListItemDocument,
  GameWordDocument,
  HomeSettingsDocument,
  NotaDocument,
  QuizQuestionDocument,
} from '@shared/infrastructure/database/schemas';
import { UserRepository } from '@auth/infrastructure/repositories/user.repository';
import { TenancyRepository } from '@tenancy/infrastructure/tenancy.repository';
import { TenantContextService } from '@shared/infrastructure/database/tenant-context';
import { AuthService } from '@auth/application/services/auth.service';
import { JobsService } from '@shared/infrastructure/queue/jobs.service';
import { UploadService } from '@shared/infrastructure/upload';

@Injectable()
export class DemoService implements OnModuleInit {
  constructor(
    private users: UserRepository,
    private tenancy: TenancyRepository,
    private context: TenantContextService,
    private auth: AuthService,
    private jobs: JobsService,
    private upload: UploadService,
    @InjectConnection() private connection: Connection,
    @InjectModel(HomeSettingsDocument.name)
    private home: Model<HomeSettingsDocument>,
    @InjectModel(NotaDocument.name) private notes: Model<NotaDocument>,
    @InjectModel(CartaDocument.name) private letters: Model<CartaMongoDocument>,
    @InjectModel(FamilyListDocument.name)
    private lists: Model<FamilyListDocument>,
    @InjectModel(FamilyListItemDocument.name)
    private items: Model<FamilyListItemDocument>,
    @InjectModel(QuizQuestionDocument.name)
    private questions: Model<QuizQuestionDocument>,
    @InjectModel(GameWordDocument.name) private words: Model<GameWordDocument>,
  ) {}

  onModuleInit() {
    void this.jobs.scheduleDemoCleanup();
  }

  async create() {
    const id = randomUUID().slice(0, 8);
    const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000);
    const user = await this.users.create({
      phoneNumber: `+999${Date.now().toString().slice(-9)}${randomInt(0, 9)}`,
      name: 'Visitante da demo',
      role: 'friends',
    });
    const tenant = await this.tenancy.createTenant({
      name: 'Família Aurora',
      slug: `demo-${id}`,
      isDemo: true,
      expiresAt,
    });
    try {
      await this.tenancy.createMembership({
        tenantId: tenant.id,
        userId: user.id,
        role: 'admin',
        relationship: 'friends',
        access: [
          'memorias',
          'playlist',
          'cartas',
          'jogos',
          'listas',
          'notas',
          'chat',
          'nossaHistoria',
        ],
      });
      await this.context.run(tenant.id, () => this.seed(user.id));
      const session = await this.auth.tokenResponse(
        user,
        tenant.id,
        'anonymous-demo',
      );
      return { slug: tenant.slug, session, expiresAt };
    } catch (error) {
      await this.tenancy.deleteTenant(tenant.id);
      await this.users.delete(user.id);
      throw error;
    }
  }

  private async seed(userId: string) {
    await this.home.create({
      key: 'home',
      events: [
        {
          title: 'Nossa história',
          icon: 'favorite',
          date: new Date('2018-05-12'),
          message: 'O dia em que tudo começou',
          countDirection: 'forward',
        },
      ],
      galleryImages: [],
      galleryTitle: 'Nossas memórias',
      galleryTitleVisible: true,
      galleryTitleLayout: 'arc',
    });
    await this.notes.create([
      {
        titulo: 'Filme de sexta',
        conteudo: 'Escolher juntos depois do jantar.',
        data: new Date(),
      },
      {
        titulo: 'Receita da vó',
        conteudo: 'Guardar aqui antes que alguém esqueça.',
        data: new Date(),
      },
    ]);
    await this.letters.create({
      type: 'letter',
      title: 'Para os dias corridos',
      content:
        'Mesmo quando o dia passa depressa, esta família continua sendo o nosso lugar.',
      date: new Date(),
    });
    const list = await this.lists.create({
      title: 'Fim de semana',
      description: 'O que queremos fazer juntos',
      createdBy: userId,
    });
    await this.items.create([
      {
        listId: String(list._id),
        text: 'Preparar o café sem pressa',
        createdBy: userId,
      },
      {
        listId: String(list._id),
        text: 'Escolher uma foto para o álbum',
        createdBy: userId,
      },
    ]);
    await this.questions.create({
      question: 'Qual programa combina mais com a família?',
      options: ['Filme e pipoca', 'Passeio ao ar livre', 'Cozinhar juntos'],
      correctIndex: 0,
      active: true,
    });
    await this.words.create({
      word: `abraço-${randomUUID().slice(0, 6)}`,
      active: true,
    });
  }

  async cleanupExpired() {
    const tenants = await this.tenancy.expiredDemos();
    for (const tenant of tenants) {
      const tenantId = String(tenant._id);
      const memberships = await this.tenancy.listMembershipsForTenant(tenantId);
      for (const collection of Object.values(this.connection.collections)) {
        if (
          [
            'tenants',
            'memberships',
            'invitations',
            'auth_sessions',
            'users',
            'phone_challenges',
          ].includes(collection.collectionName)
        )
          continue;
        await collection.deleteMany({ tenantId });
      }
      await this.upload.deleteTenantFiles(tenantId);
      await this.tenancy.deleteTenant(tenantId);
      for (const membership of memberships)
        await this.users.delete(membership.userId);
    }
    return { removed: tenants.length };
  }
}
