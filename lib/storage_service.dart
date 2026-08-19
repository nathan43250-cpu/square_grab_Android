import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'grid_utils.dart';
import 'transport_mode.dart';

/// Objet métier représentant une cellule qui a été validée par l'utilisateur.
class CollectedCell {
  final GridCell cell;
  final TransportMode mode;
  final DateTime collectedAt;

  CollectedCell({
    required this.cell,
    required this.mode,
    required this.collectedAt,
  });
}

/// Service gérant la persistance des carrés collectés via la base de données Hive.
class StorageService {
  /// Nom du conteneur Hive pour le stockage.
  static const String _boxName = 'collected_cells_v2';
  
  /// Instance de la "boîte" (table) Hive.
  late Box<String> _box;

  /// Initialise Hive pour Flutter et ouvre la boîte de stockage.
  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<String>(_boxName);
  }

  /// Vérifie si une cellule donnée a déjà été collectée.
  bool isCollected(GridCell cell) => _box.containsKey(cell.id);

  /// Renvoie le nombre total de carrés collectés depuis le début.
  int get totalCollected => _box.length;

  /// Compte combien de carrés ont été collectés pour un mode de transport spécifique.
  int countForMode(TransportMode mode) =>
      allCollectedCells.where((c) => c.mode == mode).length;

  /// Tente de collecter une cellule unique. Renvoie true si elle a été ajoutée, false si elle existait déjà.
  bool _collectSingle(GridCell cell, TransportMode mode) {
    if (_box.containsKey(cell.id)) return false;
    
    // Stockage sous forme de JSON pour conserver le mode et la date.
    final value = jsonEncode({
      'mode': mode.storageKey,
      'timestamp': DateTime.now().toIso8601String(),
    });
    _box.put(cell.id, value);
    return true;
  }

  /// Enregistre une liste de cellules parcourues pendant une expédition.
  /// Renvoie le nombre de NOUVEAUX carrés réellement ajoutés.
  int commitExpedition(Set<GridCell> cells, TransportMode mode) {
    var newCount = 0;
    for (final cell in cells) {
      if (_collectSingle(cell, mode)) newCount++;
    }
    return newCount;
  }

  /// Récupère la liste complète des carrés collectés, triés par défaut par ordre d'insertion Hive.
  List<CollectedCell> get allCollectedCells {
    return _box.keys.map((key) {
      final parts = (key as String).split('_');
      final cell = GridCell(int.parse(parts[0]), int.parse(parts[1]));
      final raw = _box.get(key)!;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return CollectedCell(
        cell: cell,
        mode: TransportMode.fromStorageKey(data['mode'] as String),
        collectedAt: DateTime.parse(data['timestamp'] as String),
      );
    }).toList();
  }

  /// Vide complètement la base de données (pour tests ou remise à zéro).
  Future<void> reset() async {
    await _box.clear();
  }
}
