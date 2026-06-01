import 'package:flutter/material.dart';

import '../../../core/widgets/love_background.dart';
import '../../../core/widgets/love_text_card.dart';
import '../../../core/widgets/section_title.dart';

class StoryPage extends StatelessWidget {
  const StoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = [
      ('Como Nos Conhecemos', 'Nossa história começou de uma forma moderna e especial, através de um aplicativo de relacionamento da nossa igreja. O que começou como uma simples conversa logo se transformou em algo muito especial.'),
      ('Nosso Relacionamento', 'Oficialmente começamos nosso namoro em 12 de outubro de 2024. Desde então, temos compartilhado momentos incríveis juntos, construindo uma relação baseada em amor, respeito e valores em comum.'),
      ('Nossa Conexão', 'Nossa fé e valores compartilhados têm sido a base do nosso relacionamento. Unidos pela igreja e por nossos princípios, construímos uma conexão verdadeira e especial.'),
    ];
    return LoveBackground(
      child: ListView(
        padding: const EdgeInsets.all(32),
        children: [
          const SectionTitle('Nossa História', size: 44),
          const SizedBox(height: 32),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                children: sections.map((section) => LoveTextCard(title: section.$1, body: section.$2)).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

