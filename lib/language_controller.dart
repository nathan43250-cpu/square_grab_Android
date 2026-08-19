import 'package:flutter/material.dart';

/// Liste des langues supportées par l'application.
enum AppLanguage { fr, en, zh }

/// Gère l'état global de la langue choisie par l'utilisateur.
/// Étend ChangeNotifier pour permettre aux widgets de se reconstruire automatiquement.
class LanguageController extends ChangeNotifier {
  // Langue par défaut : Français.
  AppLanguage _current = AppLanguage.fr;

  /// Langue actuelle.
  AppLanguage get current => _current;

  /// Change la langue et notifie tous les écouteurs (ListenableBuilder, etc.).
  void setLanguage(AppLanguage language) {
    if (_current == language) return;
    _current = language;
    notifyListeners();
  }
}
