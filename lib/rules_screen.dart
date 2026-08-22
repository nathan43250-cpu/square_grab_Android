import 'dart:ui';
import 'package:flutter/material.dart';

import 'floating_nav_bar.dart';
import 'language_controller.dart';
import 'transport_mode.dart';
import 'translations.dart';

class RulesScreen extends StatelessWidget {
  final LanguageController languageController;

  const RulesScreen({super.key, required this.languageController});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: languageController,
      builder: (context, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final lang = languageController.current;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          MediaQuery.of(context).padding.top + 16,
          16,
          floatingNavBarClearance,
        ),
        children: [
          Text(
            AppTranslations.t('how_to_play_title', lang),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _RuleStep(
            number: 1,
            icon: Icons.play_arrow,
            title: AppTranslations.t('rule_step_1_title', lang),
            text: AppTranslations.t('rule_step_1_text', lang),
          ),
          _RuleStep(
            number: 2,
            icon: Icons.directions_walk,
            title: AppTranslations.t('rule_step_2_title', lang),
            text: AppTranslations.t('rule_step_2_text', lang),
          ),
          _RuleStep(
            number: 3,
            icon: Icons.stop,
            title: AppTranslations.t('rule_step_3_title', lang),
            text: AppTranslations.t('rule_step_3_text', lang),
          ),
          _RuleStep(
            number: 4,
            icon: Icons.grid_on,
            title: AppTranslations.t('rule_step_4_title', lang),
            text: AppTranslations.t('rule_step_4_text', lang),
          ),
          _RuleStep(
            number: 5,
            icon: Icons.trending_up,
            title: AppTranslations.t('rule_step_5_title', lang),
            text: AppTranslations.t('rule_step_5_text', lang),
            isLast: true,
          ),
          const SizedBox(height: 28),
          Text(
            AppTranslations.t('color_legend_title', lang),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            AppTranslations.t('color_legend_subtitle', lang),
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          _GlassCard(
            child: Column(
              children: [
                for (final mode in TransportMode.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: mode.color.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: mode.color.withOpacity(0.5)),
                          ),
                          child: Icon(mode.icon, color: mode.color, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            mode.labelFor(lang),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: mode.color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: mode.color.withOpacity(0.6), blurRadius: 6),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Une carte "verre dépoli" réutilisable, cohérente avec le style du
/// reste de l'app (légende sur MAP, panneau de stats sur EXP...).
class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _GlassCard({required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _RuleStep extends StatelessWidget {
  final int number;
  final IconData icon;
  final String title;
  final String text;
  final bool isLast;

  const _RuleStep({
    required this.number,
    required this.icon,
    required this.title,
    required this.text,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: _GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: scheme.onPrimaryContainer, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$number. ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: scheme.primary,
                          fontSize: 15,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    text,
                    style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant, height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
