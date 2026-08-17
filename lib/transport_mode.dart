import 'package:flutter/material.dart';

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

  String get storageKey => name;

  static TransportMode fromStorageKey(String key) {
    return TransportMode.values.firstWhere(
      (m) => m.storageKey == key,
      orElse: () => TransportMode.walk,
    );
  }
}
