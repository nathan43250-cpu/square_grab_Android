import 'package:flutter/material.dart';
import 'transport_mode.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Règles du jeu')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Comment jouer',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const _RuleStep(
            number: '1',
            text: "Va dans l'onglet EXP et appuie sur \"Démarrer l'expédition\".",
          ),
          const _RuleStep(
            number: '2',
            text: 'Déplace-toi dans le monde réel : chaque case de ~100m que tu traverses est enregistrée.',
          ),
          const _RuleStep(
            number: '3',
            text: 'Quand tu as fini, appuie sur "Terminer l\'expédition" et choisis le moyen de transport utilisé.',
          ),
          const _RuleStep(
            number: '4',
            text: 'Les carrés parcourus sont ajoutés à ta carte, colorés selon le transport choisi.',
          ),
          const _RuleStep(
            number: '5',
            text: "Un carré déjà possédé garde sa couleur d'origine, même si tu le retraverses avec un autre transport.",
          ),
          const SizedBox(height: 28),
          const Text(
            'Légende des couleurs',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          for (final mode in TransportMode.values)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: mode.color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(mode.icon, size: 20, color: mode.color),
                  const SizedBox(width: 8),
                  Text(mode.label, style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RuleStep extends StatelessWidget {
  final String number;
  final String text;

  const _RuleStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(number, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
