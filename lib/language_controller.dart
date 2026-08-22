import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

enum AppLanguage { fr, en, zh }

/// Gère la langue actuelle de l'application, la sauvegarde localement et
/// la recharge au démarrage. Au tout premier lancement (rien de sauvegardé
/// encore), la langue par défaut est l'anglais.
class LanguageController extends ChangeNotifier {
  static const String _boxName = 'app_prefs';
  static const String _languageKey = 'language';

  AppLanguage _current = AppLanguage.en;

  AppLanguage get current => _current;

  /// À appeler une fois au démarrage de l'app, avant d'afficher l'UI :
  /// charge la langue précédemment choisie si elle existe.
  Future<void> init() async {
    await Hive.initFlutter();
    final box = await Hive.openBox<String>(_boxName);
    final saved = box.get(_languageKey);
    if (saved != null) {
      _current = AppLanguage.values.firstWhere(
        (l) => l.name == saved,
        orElse: () => AppLanguage.en,
      );
    }
    // Pas de notifyListeners() ici : l'écran principal attend la fin de
    // ce init() avant son tout premier affichage, donc _current est déjà
    // la bonne valeur dès le premier build.
  }

  Future<void> setLanguage(AppLanguage language) async {
    _current = language;
    notifyListeners();
    final box = await Hive.openBox<String>(_boxName);
    await box.put(_languageKey, language.name);
  }
}
