import 'dart:math';
import 'package:latlong2/latlong.dart';

/// Représente une cellule de la grille mondiale, indexée dans l'espace
/// de projection Web Mercator (le même système que les tuiles de la carte).
class GridCell {
  final int xIndex;
  final int yIndex;

  const GridCell(this.xIndex, this.yIndex);

  /// Identifiant unique utilisé comme clé de stockage.
  String get id => '${xIndex}_$yIndex';

  @override
  bool operator ==(Object other) =>
      other is GridCell && other.xIndex == xIndex && other.yIndex == yIndex;

  @override
  int get hashCode => Object.hash(xIndex, yIndex);
}

class _MercatorPoint {
  final double x;
  final double y;
  const _MercatorPoint(this.x, this.y);
}

/// Convertit des coordonnées GPS en cellule de grille, et inversement.
///
/// Important : la grille est calculée directement dans l'espace de
/// projection Web Mercator (EPSG:3857) — le même système utilisé par les
/// tuiles OpenStreetMap affichées sur la carte. Ça garantit que les cases
/// sont de vrais carrés parfaitement alignés à l'écran, sans le moindre
/// décalage entre elles, peu importe la latitude. La contrepartie (mineure,
/// invisible à l'usage normal) : la taille réelle en mètres se déforme
/// légèrement en s'approchant des pôles, exactement comme le fait la carte
/// elle-même.
class GridSystem {
  final double cellSizeMeters;

  // Rayon utilisé par la projection Web Mercator (sphère, pas l'ellipsoïde).
  static const double _earthRadius = 6378137;

  const GridSystem({this.cellSizeMeters = 200});

  _MercatorPoint _toMercator(LatLng point) {
    final lngRad = point.longitude * pi / 180;
    final latRad = point.latitude * pi / 180;
    final x = _earthRadius * lngRad;
    final y = _earthRadius * log(tan(pi / 4 + latRad / 2));
    return _MercatorPoint(x, y);
  }

  LatLng _fromMercator(double x, double y) {
    final lng = (x / _earthRadius) * 180 / pi;
    final lat = (2 * atan(exp(y / _earthRadius)) - pi / 2) * 180 / pi;
    return LatLng(lat, lng);
  }

  /// Retourne la cellule correspondant à une position GPS.
  GridCell cellForPosition(LatLng position) {
    final m = _toMercator(position);
    return GridCell((m.x / cellSizeMeters).floor(), (m.y / cellSizeMeters).floor());
  }

  /// Retourne les 4 coins (polygone) d'une cellule, pour l'affichage sur la carte.
  List<LatLng> cellPolygon(GridCell cell) {
    final x0 = cell.xIndex * cellSizeMeters;
    final y0 = cell.yIndex * cellSizeMeters;
    final x1 = x0 + cellSizeMeters;
    final y1 = y0 + cellSizeMeters;

    return [
      _fromMercator(x0, y0),
      _fromMercator(x1, y0),
      _fromMercator(x1, y1),
      _fromMercator(x0, y1),
    ];
  }

  /// Centre géographique d'une cellule.
  LatLng cellCenter(GridCell cell) {
    final x = cell.xIndex * cellSizeMeters + cellSizeMeters / 2;
    final y = cell.yIndex * cellSizeMeters + cellSizeMeters / 2;
    return _fromMercator(x, y);
  }

  /// Retourne toutes les cellules couvrant une zone visible, délimitée par
  /// son coin sud-ouest et son coin nord-est.
  /// [maxCells] protège contre un calcul (et un rendu) trop lourd si on est
  /// trop dézoomé — au-delà, on retourne une liste vide plutôt que de lagger.
  List<GridCell> cellsInBounds(LatLng southWest, LatLng northEast, {int maxCells = 800}) {
    final swM = _toMercator(southWest);
    final neM = _toMercator(northEast);

    final xMin = (min(swM.x, neM.x) / cellSizeMeters).floor();
    final xMax = (max(swM.x, neM.x) / cellSizeMeters).floor();
    final yMin = (min(swM.y, neM.y) / cellSizeMeters).floor();
    final yMax = (max(swM.y, neM.y) / cellSizeMeters).floor();

    final xCount = xMax - xMin + 1;
    final yCount = yMax - yMin + 1;
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
