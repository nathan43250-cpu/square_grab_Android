import 'package:flutter/material.dart';
import 'language_controller.dart';
import 'translations.dart';

class SettingsScreen extends StatelessWidget {
  final LanguageController controller;

  const SettingsScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(AppTranslations.t('settings_title', controller.current)),
          ),
          body: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  AppTranslations.t('language_label', controller.current),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              for (final lang in AppLanguage.values)
                RadioListTile<AppLanguage>(
                  title: Text(_labelFor(lang)),
                  value: lang,
                  groupValue: controller.current,
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
