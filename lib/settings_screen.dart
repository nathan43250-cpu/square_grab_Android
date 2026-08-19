import 'package:flutter/material.dart';
import 'language_controller.dart';
import 'translations.dart';

/// Écran de configuration permettant de modifier la langue de l'application.
class SettingsScreen extends StatelessWidget {
  final LanguageController controller;

  const SettingsScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    // Le ListenableBuilder assure que l'écran se redessine dès qu'on change la langue.
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final lang = controller.current;
        return Scaffold(
          appBar: AppBar(
            title: Text(AppTranslations.t('settings_title', lang)),
          ),
          body: ListView(
            children: [
              // Génère une option de sélection pour chaque langue définie dans l'enum.
              for (final l in AppLanguage.values)
                RadioListTile<AppLanguage>(
                  title: Text(_labelFor(l)),
                  value: l,
                  groupValue: lang,
                  onChanged: (selected) {
                    if (selected != null) {
                      controller.setLanguage(selected);
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  /// Renvoie le nom "en clair" de la langue pour l'affichage dans la liste.
  String _labelFor(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.fr:
        return 'Français';
      case AppLanguage.en:
        return 'English';
      case AppLanguage.zh:
        return '中文';
    }
  }
}
