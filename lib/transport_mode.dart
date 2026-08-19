import 'package:flutter/material.dart';
import 'language_controller.dart';
import 'translations.dart';

/// Définit les différents types de déplacement autorisés pour capturer des carrés.
enum TransportMode {
  /// Marche, course à pied ou randonnée.
  walk,
  
  /// Vélo, trottinette non électrique ou autre moyen similaire.
  bike,
  
  /// Voiture, bus, train ou autre moyen motorisé.
  car;

  /// Libellé par défaut (français).
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

  /// Icône Material associée au mode.
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

  /// Couleur distinctive utilisée sur la carte et dans la légende.
  Color get color {
    switch (this) {
      case TransportMode.walk:
        return const Color(0xFF2ECC71); // Vert émeraude
      case TransportMode.bike:
        return const Color(0xFFE67E22); // Orange carotte
      case TransportMode.car:
        return const Color(0xFFE74C3C); // Rouge alizarine
    }
  }

  /// Clé unique utilisée pour enregistrer le mode dans la base Hive.
  String get storageKey => name;

  /// Récupère le libellé traduit pour ce mode.
  String labelFor(AppLanguage language) {
    return AppTranslations.t('transport_$name', language);
  }

  /// Recrée une instance de TransportMode à partir d'une clé stockée en base.
  static TransportMode fromStorageKey(String key) {
    return TransportMode.values.firstWhere(
      (m) => m.storageKey == key,
      orElse: () => TransportMode.walk,
    );
  }
}
