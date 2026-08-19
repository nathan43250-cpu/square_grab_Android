import 'dart:math';
import 'package:latlong2/latlong.dart';

/// Représente une cellule unique de la grille globale.
/// Identifiée par ses index X et Y basés sur la projection Mercator.
class GridCell {
  final int xIndex;
  final int yIndex;

  const GridCell(this.xIndex, this.yIndex);

  /// Identifiant textuel unique (format "x_y") utilisé comme clé de stockage.
  String get id => '${xIndex}_$yIndex';

  @override
  bool operator ==(Object other) =>
      other is GridCell && other.xIndex == xIndex && other.yIndex == yIndex;

  @override
  int get hashCode => Object.hash(xIndex, yIndex);
}

/// Point intermédiaire en coordonnées cartésiennes Mercator (en mètres).
class _MercatorPoint {
  final double x;
  final double y;
  const _MercatorPoint(this.x, this.y);
}

/// Gère le découpage du monde en une grille régulière de carrés.
/// Utilise une approximation de la projection Spherical Mercator (Web Mercator).
class GridSystem {
  /// Taille des côtés des carrés, par défaut 200 mètres.
  final double cellSizeMeters;

  /// Rayon moyen de la Terre en mètres.
  static const double _earthRadius = 6378137;

  const GridSystem({this.cellSizeMeters = 200});

  /// Convertit des coordonnées GPS (Lat, Lng) en position Mercator plane (x, y).
  _MercatorPoint _toMercator(LatLng point) {
    final lngRad = point.longitude * pi / 180;
    final latRad = point.latitude * pi / 180;
    final x = _earthRadius * lngRad;
    // Projection de latitude utilisant la formule standard Web Mercator.
    final y = _earthRadius * log(tan(pi / 4 + latRad / 2));
    return _MercatorPoint(x, y);
  }

  /// Inverse la projection : convertit du Mercator plan (x, y) vers des coordonnées GPS.
  LatLng _fromMercator(double x, double y) {
    final lng = (x / _earthRadius) * 180 / pi;
    final lat = (2 * atan(exp(y / _earthRadius)) - pi / 2) * 180 / pi;
    return LatLng(lat, lng);
  }

  /// Identifie dans quelle cellule se trouve une position GPS donnée.
  GridCell cellForPosition(LatLng position) {
    final m = _toMercator(position);
    return GridCell((m.x / cellSizeMeters).floor(), (m.y / cellSizeMeters).floor());
  }

  /// Calcule les 4 points GPS qui forment les limites d'une cellule.
  /// Utile pour dessiner le polygone sur la carte.
  List<LatLng> cellPolygon(GridCell cell) {
    final x0 = cell.xIndex * cellSizeMeters;
    final y0 = cell.yIndex * cellSizeMeters;
    final x1 = x0 + cellSizeMeters;
    final y1 = y0 + cellSizeMeters;

    return [
      _fromMercator(x0, y0), // Bas gauche
      _fromMercator(x1, y0), // Bas droite
      _fromMercator(x1, y1), // Haut droite
      _fromMercator(x0, y1), // Haut gauche
    ];
  }

  /// Calcule le centre exact d'une cellule en coordonnées GPS.
  LatLng cellCenter(GridCell cell) {
    final x = cell.xIndex * cellSizeMeters + cellSizeMeters / 2;
    final y = cell.yIndex * cellSizeMeters + cellSizeMeters / 2;
    return _fromMercator(x, y);
  }

  /// Liste toutes les cellules présentes dans un rectangle défini par deux coins (Sud-Ouest, Nord-Est).
  /// [maxCells] permet de brider le calcul pour éviter des gels d'interface si le zoom est trop faible.
  List<GridCell> cellsInBounds(LatLng southWest, LatLng northEast, {int maxCells = 800}) {
    final swM = _toMercator(southWest);
    final neM = _toMercator(northEast);

    final xMin = (min(swM.x, neM.x) / cellSizeMeters).floor();
    final xMax = (max(swM.x, neM.x) / cellSizeMeters).floor();
    final yMin = (min(swM.y, neM.y) / cellSizeMeters).floor();
    final yMax = (max(swM.y, neM.y) / cellSizeMeters).floor();

    final xCount = xMax - xMin + 1;
    final yCount = yMax - yMin + 1;
    
    // Sécurité anti-lag : si trop de cellules à générer, on renvoie vide.
    if (xCount <= 0 || yCount <= 0 || xCount * yCount > maxCells) {
      return [];
    }

    final cells = <GridCell>[];
    for (var xi = xMin; xi <= xMax; xi++) {
      for (var yi = yMin; yi <= yMax; yi++) {
        cells.add(GridCell(xi, yi));
      }
    }
    return cells;
  }
}
