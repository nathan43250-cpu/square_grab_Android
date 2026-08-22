import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'grid_utils.dart';
import 'transport_mode.dart';

/// Une cellule collectée, avec le mode de transport utilisé pour l'obtenir
/// et la date de collecte.
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

/// Résultat d'une expédition validée : combien de cases étaient
/// entièrement nouvelles, et combien existaient déjà mais ont changé de
/// couleur car le nouveau transport était plus prioritaire.
class ExpeditionCommitResult {
  final int newCells;
  final int upgradedCells;

  const ExpeditionCommitResult({required this.newCells, required this.upgradedCells});
}

/// Gère la persistance locale des cellules collectées.
/// Stocke pour chaque cellule (clé "lat_lng") un JSON {mode, timestamp}.
class StorageService {
  static const String _boxName = 'collected_cells_v2';
  late Box<String> _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<String>(_boxName);
  }

  bool isCollected(GridCell cell) => _box.containsKey(cell.id);

  int get totalCollected => _box.length;

  int countForMode(TransportMode mode) =>
      allCollectedCells.where((c) => c.mode == mode).length;

  void _write(GridCell cell, TransportMode mode) {
    final value = jsonEncode({
      'mode': mode.storageKey,
      'timestamp': DateTime.now().toIso8601String(),
    });
    _box.put(cell.id, value);
  }

  /// Enregistre une cellule collectée avec la règle de priorité :
  /// - si la case n'existait pas encore -> on l'ajoute (nouvelle case)
  /// - si elle existait avec un transport MOINS prioritaire -> on la met
  ///   à jour avec le nouveau transport (case "améliorée")
  /// - si elle existait avec un transport égal ou PLUS prioritaire -> on
  ///   ne touche à rien (jamais de rétrogradation)
  /// Retourne 'new', 'upgraded', ou 'unchanged'.
  String _upsertSingle(GridCell cell, TransportMode mode) {
    final raw = _box.get(cell.id);
    if (raw == null) {
      _write(cell, mode);
      return 'new';
    }

    final existingMode = TransportMode.fromStorageKey(
      (jsonDecode(raw) as Map<String, dynamic>)['mode'] as String,
    );
    if (mode.priority > existingMode.priority) {
      _write(cell, mode);
      return 'upgraded';
    }
    return 'unchanged';
  }

  /// Enregistre toutes les cellules d'une expédition terminée avec le mode
  /// de transport choisi, en appliquant la règle de priorité ci-dessus.
  ExpeditionCommitResult commitExpedition(Set<GridCell> cells, TransportMode mode) {
    var newCount = 0;
    var upgradedCount = 0;
    for (final cell in cells) {
      switch (_upsertSingle(cell, mode)) {
        case 'new':
          newCount++;
        case 'upgraded':
          upgradedCount++;
      }
    }
    return ExpeditionCommitResult(newCells: newCount, upgradedCells: upgradedCount);
  }

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

  Future<void> reset() async {
    await _box.clear();
  }
}
