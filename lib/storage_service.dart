import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'grid_utils.dart';
import 'transport_mode.dart';

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

  bool _collectSingle(GridCell cell, TransportMode mode) {
    if (_box.containsKey(cell.id)) return false;
    final value = jsonEncode({
      'mode': mode.storageKey,
      'timestamp': DateTime.now().toIso8601String(),
    });
    _box.put(cell.id, value);
    return true;
  }

  int commitExpedition(Set<GridCell> cells, TransportMode mode) {
    var newCount = 0;
    for (final cell in cells) {
      if (_collectSingle(cell, mode)) newCount++;
    }
    return newCount;
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
