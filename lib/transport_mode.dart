import 'package:flutter/material.dart';
import 'language_controller.dart';
import 'translations.dart';

/// Les moyens de transport disponibles à la fin d'une expédition.
/// Chaque mode a sa propre couleur pour distinguer les carrés sur la carte.
enum TransportMode {
  walk,
  bike,
  car;

  String get label {
    switch (this) {
      case TransportMode.walk:
        return 'Marche / Course';
      case TransportMode.bike:
        return 'Vélo';
      case TransportMode.car:
        return 'Voiture';
    }
  }

  IconData get icon {
    switch (this) {
      case TransportMode.walk:
        return Icons.directions_walk;
      case TransportMode.bike:
        return Icons.directions_bike;
      case TransportMode.car:
        return Icons.directions_car;
    }
  }

  Color get color {
    switch (this) {
      case TransportMode.walk:
        return const Color(0xFF2ECC71); // vert
      case TransportMode.bike:
        return const Color(0xFFE67E22); // orange
      case TransportMode.car:
        return const Color(0xFFE74C3C); // rouge
    }
  }

  /// Nom stocké en base (String -> enum lors de la relecture).
  String get storageKey => name;

  /// Niveau de priorité pour la règle de remplacement des couleurs sur la
  /// carte : Marche > Vélo > Voiture. Un carré déjà collecté ne change de
  /// couleur que si le nouveau transport a une priorité STRICTEMENT plus
  /// élevée que celui déjà enregistré (jamais l'inverse).
  int get priority {
    switch (this) {
      case TransportMode.walk:
        return 2;
      case TransportMode.bike:
        return 1;
      case TransportMode.car:
        return 0;
    }
  }

  /// Libellé traduit selon la langue actuelle (à utiliser dans l'UI).
  /// Utilise les clés 'transport_walk', 'transport_bike', 'transport_car'
  /// du dictionnaire, qui correspondent exactement au nom de l'enum.
  String labelFor(AppLanguage language) {
    return AppTranslations.t('transport_$name', language);
  }

  static TransportMode fromStorageKey(String key) {
    return TransportMode.values.firstWhere(
      (m) => m.storageKey == key,
      orElse: () => TransportMode.walk,
    );
  }
}
