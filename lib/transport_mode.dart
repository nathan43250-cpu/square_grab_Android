import 'package:flutter/material.dart';

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

  static TransportMode fromStorageKey(String key) {
    return TransportMode.values.firstWhere(
      (m) => m.storageKey == key,
      orElse: () => TransportMode.walk,
    );
  }
}
