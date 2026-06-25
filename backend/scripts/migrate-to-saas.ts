import 'dotenv/config';
import { MongoClient, type Db } from 'mongodb';

const apply = process.argv.includes('--apply');
const mongoUri = process.env.MONGO_URI;
const allAccess = [
  'memorias',
  'playlist',
  'cartas',
  'jogos',
  'listas',
  'notas',
  'localizacao',
  'chat',
  'nossaHistoria',
];

const scopedCollections = [
  'cartas',
  'chat_conversations',
  'chat_messages',
  'family_list_items',
  'family_lists',
  'fotos',
  'game_completions',
  'game_words',
  'home_settings',
  'location_places',
  'location_presences',
  'location_updates',
  'mini_game_configs',
  'musicas',
  'notas',
  'notifications',
  'quiz_questions',
  'scheduled_notifications',
];

async function main() {
  if (!mongoUri) throw new Error('MONGO_URI é obrigatório.');
  const client = new MongoClient(mongoUri);
  await client.connect();
  try {
    const db = client.db();
    const users = await db
      .collection('users')
      .find()
      .sort({ createdAt: 1 })
      .toArray();
    if (!users.length)
      throw new Error('Nenhum usuário encontrado para ser proprietário.');
    const owner =
      users.find((user) => user.role === 'husband') ||
      users.find((user) => user.role === 'wife') ||
      users[0];
    let tenant = await db
      .collection('tenants')
      .findOne({ slug: 'nossa-familia' });
    report('modo', apply ? 'APLICAR' : 'INSPEÇÃO');
    report('usuários', users.length);
    report('proprietário', String(owner._id));
    for (const name of scopedCollections) {
      report(
        `${name} sem tenant`,
        await db
          .collection(name)
          .countDocuments({ tenantId: { $exists: false } }),
      );
    }
    if (!apply) {
      report(
        'resultado',
        'nenhuma alteração realizada; use --apply para executar',
      );
      return;
    }

    if (!tenant) {
      const now = new Date();
      const inserted = await db.collection('tenants').insertOne({
        name: 'Nossa Família',
        slug: 'nossa-familia',
        ownerUserId: String(owner._id),
        defaultLocale: 'pt-BR',
        status: 'active',
        isDemo: false,
        isPublished: true,
        theme: {},
        createdAt: now,
        updatedAt: now,
      });
      tenant = await db
        .collection('tenants')
        .findOne({ _id: inserted.insertedId });
    }
    if (!tenant) throw new Error('Falha ao criar tenant inicial.');
    const tenantId = String(tenant._id);
    await db.collection('tenants').updateOne(
      { _id: tenant._id },
      {
        $set: {
          status: 'active',
          isPublished: true,
          ownerUserId: String(owner._id),
          updatedAt: new Date(),
        },
      },
    );

    for (const user of users) {
      const isOwner = String(user._id) === String(owner._id);
      const legacyAdmin = user.role === 'husband' || user.role === 'wife';
      await db.collection('memberships').updateOne(
        { tenantId, userId: String(user._id) },
        {
          $set: {
            role: isOwner ? 'owner' : legacyAdmin ? 'admin' : 'member',
            access:
              isOwner || legacyAdmin ? allAccess : normalizeAccess(user.access),
            updatedAt: new Date(),
          },
          $setOnInsert: { createdAt: user.createdAt || new Date() },
        },
        { upsert: true },
      );
    }

    for (const name of scopedCollections) {
      await db
        .collection(name)
        .updateMany({ tenantId: { $exists: false } }, { $set: { tenantId } });
    }
    await migrateStoredPaths(db, tenantId);
    await rebuildTenantIndexes(db);
    report('resultado', `migração concluída para tenant ${tenantId}`);
  } finally {
    await client.close();
  }
}

async function migrateStoredPaths(db: Db, tenantId: string) {
  const prefix = `tenants/${tenantId}/`;
  for await (const user of db
    .collection('users')
    .find({ avatarPath: { $type: 'string', $not: /^tenants\// } })) {
    await db
      .collection('users')
      .updateOne(
        { _id: user._id },
        { $set: { avatarPath: prefix + user.avatarPath } },
      );
  }
  for await (const photo of db
    .collection('fotos')
    .find({ url: { $type: 'string', $not: /^tenants\// } })) {
    await db
      .collection('fotos')
      .updateOne({ _id: photo._id }, { $set: { url: prefix + photo.url } });
  }
  for await (const message of db
    .collection('chat_messages')
    .find({ mediaUrl: { $type: 'string', $not: /^(https?:|tenants\/)/ } })) {
    await db
      .collection('chat_messages')
      .updateOne(
        { _id: message._id },
        { $set: { mediaUrl: prefix + message.mediaUrl } },
      );
  }
  for await (const settings of db.collection('home_settings').find({})) {
    const galleryImages = (settings.galleryImages || []).map((path: string) =>
      path.startsWith('tenants/') || path.startsWith('http')
        ? path
        : prefix + path,
    );
    await db
      .collection('home_settings')
      .updateOne({ _id: settings._id }, { $set: { galleryImages } });
  }
}

async function rebuildTenantIndexes(db: Db) {
  await replaceIndex(
    db,
    'home_settings',
    'key_1',
    { tenantId: 1, key: 1 },
    { unique: true },
  );
  await replaceIndex(
    db,
    'location_presences',
    'userId_1_placeId_1',
    { tenantId: 1, userId: 1, placeId: 1 },
    { unique: true },
  );
  await replaceIndex(
    db,
    'notifications',
    'title_1_body_1_url_1_type_1',
    { tenantId: 1, title: 1, body: 1, url: 1, type: 1 },
    { unique: true },
  );
  await replaceIndex(
    db,
    'game_words',
    'word_1',
    { tenantId: 1, word: 1 },
    { unique: true },
  );
  await replaceIndex(
    db,
    'mini_game_configs',
    'type_1',
    { tenantId: 1, type: 1 },
    { unique: true },
  );
  await db
    .collection('memberships')
    .createIndex({ tenantId: 1, userId: 1 }, { unique: true });
}

async function replaceIndex(
  db: Db,
  collection: string,
  oldName: string,
  keys: Record<string, 1 | -1>,
  options: { unique?: boolean },
) {
  const names = (await db.collection(collection).indexes()).map(
    (index) => index.name,
  );
  if (names.includes(oldName))
    await db.collection(collection).dropIndex(oldName);
  await db.collection(collection).createIndex(keys, options);
}

function normalizeAccess(value: unknown) {
  return Array.isArray(value)
    ? value.filter((item) => allAccess.includes(String(item)))
    : [];
}

function report(label: string, value: unknown) {
  process.stdout.write(`${label}: ${String(value)}\n`);
}

void main().catch((error) => {
  process.stderr.write(
    `${error instanceof Error ? error.message : String(error)}\n`,
  );
  process.exitCode = 1;
});
