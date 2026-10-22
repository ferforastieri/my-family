import 'dart:io';

Future<void> main(List<String> arguments) async {
  if (arguments.length != 2) {
    stderr.writeln('Uso: dart run tool/finalize.dart <site-url> <api-url>');
    exitCode = 64;
    return;
  }
  final site = Uri.parse(arguments[0]);
  final api = Uri.parse(arguments[1]);
  if (!site.hasScheme ||
      site.host.isEmpty ||
      !api.hasScheme ||
      api.host.isEmpty) {
    stderr.writeln('SITE_URL e API_URL precisam ser URLs absolutas.');
    exitCode = 64;
    return;
  }

  final output = Directory('build/jaspr');
  if (!output.existsSync()) {
    stderr.writeln('Execute jaspr build antes de finalizar os arquivos SEO.');
    exitCode = 66;
    return;
  }

  await File('${output.path}/robots.txt').writeAsString('''User-agent: *
Allow: /
Disallow: /cadastro
Disallow: /demo
Disallow: /app
Sitemap: ${site.resolve('/sitemap.xml')}
''');

  await File('${output.path}/_headers').writeAsString('''/*
  X-Content-Type-Options: nosniff
  X-Frame-Options: DENY
  Referrer-Policy: strict-origin-when-cross-origin
  Permissions-Policy: camera=(), microphone=(), geolocation=()
  Content-Security-Policy: default-src 'self'; img-src 'self' data: https://challenges.cloudflare.com; frame-src https://challenges.cloudflare.com; script-src 'self' 'unsafe-inline' https://challenges.cloudflare.com; style-src 'self' 'unsafe-inline'; connect-src 'self' ${api.origin} https://challenges.cloudflare.com
/assets/*
  Cache-Control: public, max-age=31536000, immutable
''');
}
