import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/love_background.dart';
import '../../../core/widgets/section_title.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.onNavigate});

  final ValueChanged<String> onNavigate;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Timer timer;
  late List<CounterInfo> counters;

  @override
  void initState() {
    super.initState();
    counters = _buildCounters();
    timer = Timer.periodic(const Duration(seconds: 1),
        (_) => setState(() => counters = _buildCounters()));
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
      MenuCardData(
          'Nossa História',
          'Descubra como tudo começou e os momentos que nos trouxeram até aqui.',
          '/nossa-historia'),
      MenuCardData(
          'Jogos do Amor 🎮',
          'Divirta-se com nossos jogos especiais, incluindo o Quiz do Amor!',
          '/jogos'),
      MenuCardData('Mensagens do Coração',
          'Palavras de amor e carinho que compartilhamos.', '/mensagens'),
      MenuCardData(
          'Carta de Amor',
          'Uma declaração especial do meu coração para você.',
          '/carta-de-amor'),
      MenuCardData(
          'Uma Flor para Minha Esposa',
          'Um jardim especial dedicado à mulher da minha vida 🌹',
          '/flor-para-esposa'),
    ];

    return LoveBackground(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 40),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1152),
              child: Column(
                children: [
                  const SectionTitle('Para Meu Amor ❤️', size: 38),
                  const SizedBox(height: 28),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 760;
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: wide ? 3 : 1,
                        childAspectRatio: wide ? 1.05 : 1.22,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        children: counters
                            .map((counter) => CounterCard(counter))
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 672),
                    child: Text(
                      'Um jardim digital de memórias e amor, onde cada momento representa uma parte especial da nossa história juntos.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: muted, fontSize: 16, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 1280
                      ? 5
                      : constraints.maxWidth >= 1024
                          ? 4
                          : constraints.maxWidth >= 640
                              ? 2
                              : 1;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: columns,
                    childAspectRatio: columns == 1 ? 1.8 : .95,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    children: cards
                        .map(
                          (card) => InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => widget.onNavigate(card.path),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      card.title,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: primary,
                                        fontFamily: 'serif',
                                        fontWeight: FontWeight.w800,
                                        fontSize: 20,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      card.description,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          color: muted,
                                          fontSize: 14,
                                          height: 1.35),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
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

class MenuCardData {
  const MenuCardData(this.title, this.description, this.path);

  final String title;
  final String description;
  final String path;
}

class CounterInfo {
  const CounterInfo({
    required this.title,
    required this.icon,
    required this.date,
    required this.message,
    required this.elapsed,
    required this.colors,
  });

  final String title;
  final String icon;
  final DateTime date;
  final String message;
  final ElapsedTime elapsed;
  final List<Color> colors;
}

class ElapsedTime {
  const ElapsedTime({
    required this.years,
    required this.months,
    required this.days,
    required this.totalDays,
    required this.isFuture,
  });

  final int years;
  final int months;
  final int days;
  final int totalDays;
  final bool isFuture;
}

List<CounterInfo> _buildCounters() {
  return [
    CounterInfo(
      title: 'Começamos a Namorar',
      icon: '💕',
      date: DateTime(2024, 10, 12),
      message: 'Desde o primeiro olhar, sabia que você era especial',
      elapsed: _elapsed(DateTime(2024, 10, 12)),
      colors: const [primary, primaryDark],
    ),
    CounterInfo(
      title: 'Nosso Casamento',
      icon: '💍',
      date: DateTime(2025, 4, 15),
      message: 'O dia mais feliz da minha vida ao seu lado',
      elapsed: _elapsed(DateTime(2025, 4, 15)),
      colors: const [Color(0xffff73b9), Color(0xffdf5198)],
    ),
    CounterInfo(
      title: 'Nascimento do Fernando',
      icon: '👶',
      date: DateTime(2026, 6, 1),
      message: 'Nosso maior presente de amor chegando',
      elapsed: _elapsed(DateTime(2026, 6, 1)),
      colors: const [Color(0xffc084fc), Color(0xff9333ea)],
    ),
  ];
}

ElapsedTime _elapsed(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);
  final isFuture = diff.isNegative;
  final days = diff.inDays.abs();
  return ElapsedTime(
    years: days ~/ 365,
    months: ((days % 365) / 30.44).floor(),
    days: (days % 30.44).floor(),
    totalDays: days,
    isFuture: isFuture,
  );
}

class CounterCard extends StatelessWidget {
  const CounterCard(this.info, {super.key});

  final CounterInfo info;

  @override
  Widget build(BuildContext context) {
    final values = [
      ('${info.elapsed.years}', 'Anos'),
      ('${info.elapsed.months}', 'Meses'),
      ('${info.elapsed.days}', 'Dias'),
    ];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: info.colors),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: .26)),
        boxShadow: [
          BoxShadow(
              color: info.colors.last.withValues(alpha: .24),
              blurRadius: 16,
              offset: const Offset(0, 8))
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(info.icon, style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  info.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(_formatDate(info.date),
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
          const SizedBox(height: 8),
          Text(info.message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 12, height: 1.3)),
          const Spacer(),
          Row(
            children: values
                .map(
                  (value) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .95),
                          borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        children: [
                          Text(value.$1,
                              style: const TextStyle(
                                  color: primary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 24)),
                          Text(value.$2,
                              style: const TextStyle(
                                  color: muted,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .18),
              border: Border.all(color: Colors.white.withValues(alpha: .25)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${info.elapsed.isFuture ? 'Faltam' : 'Já se passaram'}\n${info.elapsed.totalDays} dias',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.25),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  const months = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro'
  ];
  return '${date.day.toString().padLeft(2, '0')} de ${months[date.month - 1]} de ${date.year}';
}
