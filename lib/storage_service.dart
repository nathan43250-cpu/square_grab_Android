import 'package:hive_flutter/hive_flutter.dart';
import 'grid_utils.dart';

/// Gère la persistance locale des cellules collectées.
/// Utilise une simple box Hive nom -> timestamp de collecte (String -> String).
class StorageService {
  static const String _boxName = 'collected_cells';
  late Box<String> _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<String>(_boxName);
  }

  /// Retourne true si c'est une nouvelle cellule (première collecte).
  bool collect(GridCell cell) {
    if (_box.containsKey(cell.id)) return false;
    _box.put(cell.id, DateTime.now().toIso8601String());
    return true;
  }

  bool isCollected(GridCell cell) => _box.containsKey(cell.id);

  int get totalCollected => _box.length;

  /// Reconstruit la liste des GridCell depuis les clés stockées ("lat_lng").
  List<GridCell> get allCollectedCells => _box.keys.map((key) {
        final parts = (key as String).split('_');
        return GridCell(int.parse(parts[0]), int.parse(parts[1]));
      }).toList();

  Future<void> reset() async {
    await _box.clear();
  }
}
