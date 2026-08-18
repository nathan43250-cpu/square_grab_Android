import 'package:flutter/material.dart';
import 'language_controller.dart';
import 'translations.dart';

class SettingsScreen extends StatelessWidget {
  final LanguageController controller;

  const SettingsScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppTranslations.t('settings_title', controller.current))),

      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          return ListView(
            children: [
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
          );
        },
      ),
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