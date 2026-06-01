import 'package:flutter/material.dart';

import '../../../core/widgets/love_background.dart';
import '../../../core/widgets/love_text_card.dart';
import '../../../core/widgets/section_title.dart';

class GamesPage extends StatelessWidget {
  const GamesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LoveBackground(
      child: ListView(
        padding: const EdgeInsets.all(32),
        children: [
          const SectionTitle('Jogos do Amor', size: 38),
          const SizedBox(height: 32),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Wrap(
                spacing: 32,
                runSpacing: 32,
                children: const [
                  SizedBox(
                    width: 560,
                    child: LoveTextCard(title: 'Quiz do Amor ❤️', body: 'Teste seus conhecimentos sobre nossa história de amor!'),
                  ),
                  SizedBox(
                    width: 560,
                    child: LoveTextCard(title: 'Caça Palavras 🔍', body: 'Encontre palavras românticas que mudam todos os dias!'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
