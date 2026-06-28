export const locales = ['pt', 'en', 'es'] as const;
export type Locale = (typeof locales)[number];

type Copy = {
  htmlLang: string;
  brand: string;
  navProduct: string;
  navPlans: string;
  navPrivacy: string;
  navLogin: string;
  navSignup: string;
  eyebrow: string;
  title: string;
  description: string;
  primaryCta: string;
  secondaryCta: string;
  trustLine: string;
  proofItems: string[];
  featureTitle: string;
  featureDescription: string;
  features: Array<{ title: string; body: string }>;
  plansEyebrow: string;
  plansTitle: string;
  plansDescription: string;
  plansEmpty: string;
  highlighted: string;
  choosePlan: string;
  privacyEyebrow: string;
  privacyTitle: string;
  privacyDescription: string;
  privacyMissing: string;
  privacyUpdated: string;
  privacyOpen: string;
  interval: Record<string, string>;
  privacyPage: {
    title: string;
    description: string;
    missingTitle: string;
    missingBody: string;
    back: string;
  };
  familyPage: {
    login: string;
    memories: string;
    playlist: string;
    journey: string;
    letters: string;
    events: string;
    empty: string;
  };
  seo: {
    title: string;
    description: string;
  };
};

export const copy: Record<Locale, Copy> = {
  pt: {
    htmlLang: 'pt-BR',
    brand: 'Nossa Família',
    navProduct: 'Produto',
    navPlans: 'Planos',
    navPrivacy: 'Privacidade',
    navLogin: 'Entrar',
    navSignup: 'Criar família',
    eyebrow: 'Espaço privado para famílias',
    title: 'A casa digital para guardar memórias, rotina e afeto.',
    description:
      'Organize fotos, cartas, playlists, listas, localização e conversas em um espaço seguro para a sua família.',
    primaryCta: 'Começar agora',
    secondaryCta: 'Ver demonstração',
    trustLine: 'Conteúdo privado, controle familiar e assinatura transparente.',
    proofItems: ['Memórias organizadas', 'Site público opcional', 'Rotina em família'],
    featureTitle: 'Tudo que importa em um só lugar.',
    featureDescription:
      'O app segue nativo no Android e iOS. A web pública é renderizada para buscadores e aponta para o mesmo produto.',
    features: [
      {
        title: 'Memórias vivas',
        body: 'Galeria, músicas, cartas e jornada preservam histórias com contexto.',
      },
      {
        title: 'Rotina compartilhada',
        body: 'Listas, notas, localização e chat mantêm a família coordenada.',
      },
      {
        title: 'Presença pública controlada',
        body: 'Cada família pode publicar um site próprio quando fizer sentido.',
      },
    ],
    plansEyebrow: 'Planos dinâmicos',
    plansTitle: 'Planos publicados pelo backend.',
    plansDescription:
      'Os valores abaixo vêm da API pública. Nada fica travado no Next.',
    plansEmpty: 'Nenhum plano ativo foi retornado pelo backend neste momento.',
    highlighted: 'Mais escolhido',
    choosePlan: 'Selecionar plano',
    privacyEyebrow: 'Documento público',
    privacyTitle: 'Política de privacidade vinda do backend.',
    privacyDescription:
      'A página legal renderiza somente o documento publicado na API.',
    privacyMissing:
      'Ainda não existe política de privacidade publicada no backend.',
    privacyUpdated: 'Atualizada em',
    privacyOpen: 'Abrir política',
    interval: {
      monthly: 'mensal',
      semiannual: 'semestral',
      annual: 'anual',
      lifetime: 'vitalício',
    },
    privacyPage: {
      title: 'Política de privacidade',
      description:
        'Documento público carregado diretamente do backend da plataforma.',
      missingTitle: 'Política não configurada',
      missingBody:
        'Publique o documento de privacidade no backend para esta página renderizar o conteúdo legal.',
      back: 'Voltar para a landing',
    },
    familyPage: {
      login: 'Entrar no espaço da família',
      memories: 'Memórias',
      playlist: 'Playlist',
      journey: 'Nossa jornada',
      letters: 'Cartas',
      events: 'Datas especiais',
      empty: 'Este espaço público ainda não tem conteúdo publicado.',
    },
    seo: {
      title: 'Nossa Família | Memórias, rotina e site familiar',
      description:
        'Nossa Família ajuda famílias a preservarem memórias, organizarem rotinas e publicarem um site familiar com controle e privacidade.',
    },
  },
  en: {
    htmlLang: 'en',
    brand: 'Our Family',
    navProduct: 'Product',
    navPlans: 'Plans',
    navPrivacy: 'Privacy',
    navLogin: 'Sign in',
    navSignup: 'Create family',
    eyebrow: 'Private space for families',
    title: 'A digital home for memories, routine and care.',
    description:
      'Organize photos, letters, playlists, lists, location and conversations in one safe family space.',
    primaryCta: 'Get started',
    secondaryCta: 'View demo',
    trustLine: 'Private content, family controls and transparent billing.',
    proofItems: ['Organized memories', 'Optional public site', 'Family routine'],
    featureTitle: 'Everything that matters in one place.',
    featureDescription:
      'The app stays native on Android and iOS. The public web experience is rendered for search engines and points to the same product.',
    features: [
      {
        title: 'Living memories',
        body: 'Gallery, songs, letters and timelines keep stories connected to their context.',
      },
      {
        title: 'Shared routine',
        body: 'Lists, notes, location and chat keep the family coordinated.',
      },
      {
        title: 'Controlled public presence',
        body: 'Each family can publish its own site when that makes sense.',
      },
    ],
    plansEyebrow: 'Dynamic plans',
    plansTitle: 'Plans published by the backend.',
    plansDescription:
      'The prices below come from the public API. Nothing is locked into Next.',
    plansEmpty: 'No active plan was returned by the backend right now.',
    highlighted: 'Most chosen',
    choosePlan: 'Choose plan',
    privacyEyebrow: 'Public document',
    privacyTitle: 'Privacy policy from the backend.',
    privacyDescription:
      'The legal page renders only the document published by the API.',
    privacyMissing: 'There is no published privacy policy in the backend yet.',
    privacyUpdated: 'Updated on',
    privacyOpen: 'Open policy',
    interval: {
      monthly: 'monthly',
      semiannual: 'semiannual',
      annual: 'annual',
      lifetime: 'lifetime',
    },
    privacyPage: {
      title: 'Privacy policy',
      description:
        'Public document loaded directly from the platform backend.',
      missingTitle: 'Policy not configured',
      missingBody:
        'Publish the privacy document in the backend for this page to render legal content.',
      back: 'Back to landing',
    },
    familyPage: {
      login: 'Enter family space',
      memories: 'Memories',
      playlist: 'Playlist',
      journey: 'Our journey',
      letters: 'Letters',
      events: 'Special dates',
      empty: 'This public space does not have published content yet.',
    },
    seo: {
      title: 'Our Family | Memories, routine and family site',
      description:
        'Our Family helps families preserve memories, organize routines and publish a controlled family site.',
    },
  },
  es: {
    htmlLang: 'es',
    brand: 'Nuestra Familia',
    navProduct: 'Producto',
    navPlans: 'Planes',
    navPrivacy: 'Privacidad',
    navLogin: 'Entrar',
    navSignup: 'Crear familia',
    eyebrow: 'Espacio privado para familias',
    title: 'Un hogar digital para recuerdos, rutina y cuidado.',
    description:
      'Organiza fotos, cartas, playlists, listas, ubicación y conversaciones en un espacio seguro para tu familia.',
    primaryCta: 'Empezar ahora',
    secondaryCta: 'Ver demo',
    trustLine: 'Contenido privado, controles familiares y cobro transparente.',
    proofItems: ['Recuerdos organizados', 'Sitio público opcional', 'Rutina familiar'],
    featureTitle: 'Todo lo importante en un solo lugar.',
    featureDescription:
      'La app sigue nativa en Android e iOS. La web pública se renderiza para buscadores y apunta al mismo producto.',
    features: [
      {
        title: 'Recuerdos vivos',
        body: 'Galería, canciones, cartas y línea de tiempo preservan historias con contexto.',
      },
      {
        title: 'Rutina compartida',
        body: 'Listas, notas, ubicación y chat mantienen a la familia coordinada.',
      },
      {
        title: 'Presencia pública controlada',
        body: 'Cada familia puede publicar su propio sitio cuando tenga sentido.',
      },
    ],
    plansEyebrow: 'Planes dinámicos',
    plansTitle: 'Planes publicados por el backend.',
    plansDescription:
      'Los valores abajo vienen desde la API pública. Nada queda fijo en Next.',
    plansEmpty: 'Ningún plan activo fue devuelto por el backend en este momento.',
    highlighted: 'Más elegido',
    choosePlan: 'Seleccionar plan',
    privacyEyebrow: 'Documento público',
    privacyTitle: 'Política de privacidad desde el backend.',
    privacyDescription:
      'La página legal renderiza solamente el documento publicado en la API.',
    privacyMissing:
      'Todavía no existe política de privacidad publicada en el backend.',
    privacyUpdated: 'Actualizada el',
    privacyOpen: 'Abrir política',
    interval: {
      monthly: 'mensual',
      semiannual: 'semestral',
      annual: 'anual',
      lifetime: 'vitalicio',
    },
    privacyPage: {
      title: 'Política de privacidad',
      description:
        'Documento público cargado directamente desde el backend de la plataforma.',
      missingTitle: 'Política no configurada',
      missingBody:
        'Publica el documento de privacidad en el backend para que esta página renderice el contenido legal.',
      back: 'Volver a la landing',
    },
    familyPage: {
      login: 'Entrar al espacio familiar',
      memories: 'Recuerdos',
      playlist: 'Playlist',
      journey: 'Nuestro camino',
      letters: 'Cartas',
      events: 'Fechas especiales',
      empty: 'Este espacio público todavía no tiene contenido publicado.',
    },
    seo: {
      title: 'Nuestra Familia | Recuerdos, rutina y sitio familiar',
      description:
        'Nuestra Familia ayuda a familias a preservar recuerdos, organizar rutinas y publicar un sitio familiar controlado.',
    },
  },
};

export function resolveLocale(value?: string): Locale {
  return locales.includes(value as Locale) ? (value as Locale) : 'pt';
}

export function localePath(locale: Locale, path = '') {
  return `/${locale}${path}`;
}
