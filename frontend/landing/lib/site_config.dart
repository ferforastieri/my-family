const siteUrl = String.fromEnvironment(
  'SITE_URL',
  defaultValue: 'http://localhost:8080',
);
const apiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://localhost:3001/api',
);
const appUrl = String.fromEnvironment(
  'APP_URL',
  defaultValue: 'http://localhost:3458',
);
const turnstileSiteKey = String.fromEnvironment('TURNSTILE_SITE_KEY');
const downloadUrl = String.fromEnvironment(
  'DOWNLOAD_URL',
  defaultValue:
      'https://github.com/ferforastieri/siao/releases/latest/download/app-release.apk',
);
