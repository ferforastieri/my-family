import 'package:flutter/widgets.dart';

enum MarketingLocale {
  pt('pt', 'pt-BR', 'Português'),
  en('en', 'en', 'English'),
  es('es', 'es', 'Español');

  const MarketingLocale(this.code, this.apiCode, this.label);

  final String code;
  final String apiCode;
  final String label;

  static MarketingLocale resolve(String? value) {
    return MarketingLocale.values.firstWhere(
      (locale) => locale.code == value,
      orElse: () {
        final device =
            WidgetsBinding.instance.platformDispatcher.locale.languageCode;
        return MarketingLocale.values.firstWhere(
          (locale) => locale.code == device,
          orElse: () => MarketingLocale.pt,
        );
      },
    );
  }
}

class MarketingCopy {
  const MarketingCopy({
    required this.brand,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.primary,
    required this.demo,
    required this.login,
    required this.featuresTitle,
    required this.features,
    required this.demoBadge,
    required this.back,
    required this.signupTitle,
    required this.signupBody,
    required this.name,
    required this.email,
    required this.password,
    required this.familyName,
    required this.slug,
    required this.signupButton,
    required this.loginTitle,
    required this.loginBody,
    required this.noAccount,
    required this.hasAccount,
    required this.loading,
    required this.tryAgain,
    required this.memories,
    required this.events,
  });

  final String brand;
  final String eyebrow;
  final String title;
  final String description;
  final String primary;
  final String demo;
  final String login;
  final String featuresTitle;
  final List<(String, String, String)> features;
  final String demoBadge;
  final String back;
  final String signupTitle;
  final String signupBody;
  final String name;
  final String email;
  final String password;
  final String familyName;
  final String slug;
  final String signupButton;
  final String loginTitle;
  final String loginBody;
  final String noAccount;
  final String hasAccount;
  final String loading;
  final String tryAgain;
  final String memories;
  final String events;
}

const marketingCopy = <MarketingLocale, MarketingCopy>{
  MarketingLocale.pt: MarketingCopy(
    brand: 'My Family',
    eyebrow: 'Um lugar só de vocês',
    title: 'A história da sua família merece um cantinho especial.',
    description:
        'Memórias, cartas, músicas, datas importantes e pequenos momentos reunidos em um espaço bonito, privado e feito para durar.',
    primary: 'Criar meu espaço',
    demo: 'Explorar demonstração',
    login: 'Entrar',
    featuresTitle: 'Tudo que aproxima, sem complicar.',
    features: [
      ('📷', 'Memórias em fotos', 'Organize fotos, vídeos e álbuns.'),
      ('♫', 'A trilha sonora', 'Guarde as músicas que marcaram vocês.'),
      ('💌', 'Cartas e declarações', 'Escreva o que merece permanecer.'),
      ('🌿', 'Uma jornada viva', 'Conte a história capítulo por capítulo.'),
    ],
    demoBadge: 'Demonstração — dados fictícios e somente leitura',
    back: 'Voltar',
    signupTitle: 'Crie o espaço da sua família',
    signupBody:
        'Depois do cadastro, você poderá ativar a assinatura e personalizar tudo.',
    name: 'Seu nome',
    email: 'Email',
    password: 'Senha (mínimo 8 caracteres)',
    familyName: 'Nome da família ou do casal',
    slug: 'Endereço desejado',
    signupButton: 'Criar conta',
    loginTitle: 'Que bom ter você de volta',
    loginBody: 'Entre para continuar cuidando das suas memórias.',
    noAccount: 'Ainda não tenho conta',
    hasAccount: 'Já tenho conta',
    loading: 'Carregando…',
    tryAgain: 'Tentar novamente',
    memories: 'Memórias',
    events: 'Datas especiais',
  ),
  MarketingLocale.en: MarketingCopy(
    brand: 'My Family',
    eyebrow: 'A place that belongs to you',
    title: 'Your family story deserves a special home.',
    description:
        'Memories, letters, music, meaningful dates and everyday moments gathered in a beautiful, private space built to last.',
    primary: 'Create my space',
    demo: 'Explore the demo',
    login: 'Sign in',
    featuresTitle: 'Everything that brings you closer, without the fuss.',
    features: [
      ('📷', 'Photo memories', 'Organize photos, videos and albums.'),
      ('♫', 'Your soundtrack', 'Save the music that shaped your story.'),
      ('💌', 'Letters and declarations', 'Write down what deserves to remain.'),
      ('🌿', 'A living journey', 'Tell your story chapter by chapter.'),
    ],
    demoBadge: 'Demo — fictional data, read-only mode',
    back: 'Back',
    signupTitle: 'Create your family space',
    signupBody: 'After signup, activate your plan and customize everything.',
    name: 'Your name',
    email: 'Email',
    password: 'Password (at least 8 characters)',
    familyName: 'Family or couple name',
    slug: 'Preferred address',
    signupButton: 'Create account',
    loginTitle: 'It is good to have you back',
    loginBody: 'Sign in to keep caring for your memories.',
    noAccount: 'I do not have an account',
    hasAccount: 'I already have an account',
    loading: 'Loading…',
    tryAgain: 'Try again',
    memories: 'Memories',
    events: 'Special dates',
  ),
  MarketingLocale.es: MarketingCopy(
    brand: 'My Family',
    eyebrow: 'Un lugar solo para ustedes',
    title: 'La historia de tu familia merece un rincón especial.',
    description:
        'Recuerdos, cartas, música, fechas importantes y momentos cotidianos reunidos en un espacio hermoso, privado y hecho para durar.',
    primary: 'Crear mi espacio',
    demo: 'Explorar demostración',
    login: 'Entrar',
    featuresTitle: 'Todo lo que acerca, sin complicaciones.',
    features: [
      ('📷', 'Recuerdos en fotos', 'Organiza fotos, videos y álbumes.'),
      ('♫', 'La banda sonora', 'Guarda la música que marcó su historia.'),
      (
        '💌',
        'Cartas y declaraciones',
        'Escribe aquello que merece permanecer.'
      ),
      ('🌿', 'Un camino vivo', 'Cuenta la historia capítulo a capítulo.'),
    ],
    demoBadge: 'Demostración — datos ficticios y modo de solo lectura',
    back: 'Volver',
    signupTitle: 'Crea el espacio de tu familia',
    signupBody:
        'Después del registro podrás activar el plan y personalizarlo todo.',
    name: 'Tu nombre',
    email: 'Email',
    password: 'Contraseña (mínimo 8 caracteres)',
    familyName: 'Nombre de la familia o pareja',
    slug: 'Dirección deseada',
    signupButton: 'Crear cuenta',
    loginTitle: 'Qué bueno tenerte de vuelta',
    loginBody: 'Entra para seguir cuidando tus recuerdos.',
    noAccount: 'Todavía no tengo cuenta',
    hasAccount: 'Ya tengo cuenta',
    loading: 'Cargando…',
    tryAgain: 'Intentar nuevamente',
    memories: 'Recuerdos',
    events: 'Fechas especiales',
  ),
};
