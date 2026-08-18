import 'package:flutter/material.dart';

enum AppLanguage { fr, en, zh }

class LanguageController extends ChangeNotifier {
  AppLanguage _current = AppLanguage.fr;

  AppLanguage get current => _current;

    void setLanguage(AppLanguage language) {
      _current = language;
      notifyListeners();
    }
  }