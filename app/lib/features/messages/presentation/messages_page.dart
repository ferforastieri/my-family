import 'package:flutter/material.dart';

import '../../../core/widgets/love_background.dart';
import '../../../core/widgets/love_text_card.dart';
import '../../../core/widgets/section_title.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final messages = [
      ('Meu Amor', 'Cada dia ao seu lado é uma nova aventura cheia de amor e felicidade...', '10 de Novembro, 2024'),
      ('Para Sempre', 'Você é o sonho que eu não sabia que tinha até te encontrar...', '11 de Fevereiro, 2024'),
    ];
    return LoveBackground(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 80, 24, 32),
        children: [
          const SectionTitle('Mensagens do Coração', size: 38),
          const SizedBox(height: 32),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 900
                      ? 3
                      : constraints.maxWidth >= 620
                          ? 2
                          : 1;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: columns,
                    childAspectRatio: 1.22,
                    crossAxisSpacing: 32,
                    mainAxisSpacing: 32,
                    children: messages
                        .map((message) => LoveTextCard(title: message.$1, body: message.$2, footer: message.$3))
                        .toList(),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

