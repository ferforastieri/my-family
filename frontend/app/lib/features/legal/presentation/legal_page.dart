import 'package:flutter/material.dart';
import 'package:family_ui/family_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_brand.dart';
import '../../../core/widgets/love_background.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../data/family_repository.dart';

enum LegalKind { terms, privacy }

class LegalPage extends StatefulWidget {
  const LegalPage({
    super.key,
    required this.repository,
    required this.kind,
  });

  final FamilyRepository repository;
  final LegalKind kind;

  @override
  State<LegalPage> createState() => _LegalPageState();
}

class _LegalPageState extends State<LegalPage> {
  late Future<Map<String, dynamic>> content;

  @override
  void initState() {
    super.initState();
    content = widget.repository.getPublicLegal();
  }

  String get title =>
      widget.kind == LegalKind.terms ? 'Termos de uso' : 'Privacidade';

  String get key =>
      widget.kind == LegalKind.terms ? 'terms' : 'privacy';

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Scaffold(
      backgroundColor: palette.bgStart,
      body: LoveBackground(
        child: SafeArea(
          child: FutureBuilder<Map<String, dynamic>>(
            future: content,
            builder: (context, snapshot) {
              final text = snapshot.data?[key]?.toString() ?? '';
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 48),
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(FamilyIcons.chevronLeft),
                        tooltip: 'Voltar',
                      ),
                      const SizedBox(width: 4),
                      AppBrandLogo(width: 42, height: 42),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: palette.foreground,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const SkeletonBox(height: 360, borderRadius: 18)
                  else if (snapshot.hasError)
                    FamilyCard(
                      child: Column(
                        children: [
                          const Icon(FamilyIcons.errorOutline, size: 32),
                          const SizedBox(height: 10),
                          Text('Não foi possível carregar o conteúdo.'),
                          const SizedBox(height: 12),
                          FamilyFilledButton(
                            onPressed: () => setState(() {
                              content = widget.repository.getPublicLegal();
                            }),
                            child: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    )
                  else
                    FamilyCard(
                      padding: const EdgeInsets.all(22),
                      child: SelectableText(
                        text.isEmpty ? 'Conteúdo ainda não publicado.' : text,
                        style: TextStyle(
                          color: palette.foreground,
                          fontSize: 16,
                          height: 1.65,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
