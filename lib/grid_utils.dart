import 'dart:math';
import 'package:latlong2/latlong.dart';

/// Représente une cellule de la grille mondiale.
/// [latIndex] et [lngIndex] identifient la cellule de façon unique.
class GridCell {
  final int latIndex;
  final int lngIndex;

  const GridCell(this.latIndex, this.lngIndex);

  /// Identifiant unique utilisé comme clé de stockage.
  String get id => '${latIndex}_$lngIndex';

  @override
  bool operator ==(Object other) =>
      other is GridCell && other.latIndex == latIndex && other.lngIndex == lngIndex;

  @override
  int get hashCode => Object.hash(latIndex, lngIndex);
}

/// Convertit des coordonnées GPS en cellule de grille, et inversement,
/// pour une taille de cellule donnée (en mètres).
class GridSystem {
  final double cellSizeMeters;

  // Rayon moyen de la Terre en mètres.
  static const double _earthRadius = 6371000;

  const GridSystem({this.cellSizeMeters = 100});

  /// Taille d'une cellule en degrés de latitude (constante partout).
  double get _latStepDegrees => (cellSizeMeters / _earthRadius) * (180 / pi);

  /// Taille d'une cellule en degrés de longitude à une latitude donnée
  /// (varie car les méridiens se rapprochent aux pôles).
  double _lngStepDegrees(double latitude) {
    final latRad = latitude * pi / 180;
    final metersPerDegreeLng = (pi / 180) * _earthRadius * cos(latRad);
    return cellSizeMeters / metersPerDegreeLng;
  }

  /// Retourne la cellule correspondant à une position GPS.
  GridCell cellForPosition(LatLng position) {
    final latIndex = (position.latitude / _latStepDegrees).floor();
    final lngStep = _lngStepDegrees(position.latitude);
    final lngIndex = (position.longitude / lngStep).floor();
    return GridCell(latIndex, lngIndex);
  }

  /// Retourne les 4 coins (polygone) d'une cellule, pour l'affichage sur la carte.
  List<LatLng> cellPolygon(GridCell cell) {
    final latStep = _latStepDegrees;
    final southLat = cell.latIndex * latStep;
    final northLat = southLat + latStep;

    // On utilise la latitude sud de la cellule comme référence pour
    // calculer le pas de longitude (suffisant pour des cellules ~100m).
    final lngStep = _lngStepDegrees(southLat);
    final westLng = cell.lngIndex * lngStep;
    final eastLng = westLng + lngStep;

    return [
      LatLng(southLat, westLng),
      LatLng(southLat, eastLng),
      LatLng(northLat, eastLng),
      LatLng(northLat, westLng),
    ];
  }

  /// Centre géographique d'une cellule (utile pour centrer la caméra dessus).
  LatLng cellCenter(GridCell cell) {
    final corners = cellPolygon(cell);
    final lat = (corners[0].latitude + corners[2].latitude) / 2;
    final lng = (corners[0].longitude + corners[2].longitude) / 2;
    return LatLng(lat, lng);
  }
}
