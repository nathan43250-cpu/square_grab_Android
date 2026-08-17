import 'dart:math';
import 'package:latlong2/latlong.dart';

class GridCell {
  final int xIndex;
  final int yIndex;

  const GridCell(this.xIndex, this.yIndex);

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

class GridSystem {
  final double cellSizeMeters;

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

  GridCell cellForPosition(LatLng position) {
    final m = _toMercator(position);
    return GridCell((m.x / cellSizeMeters).floor(), (m.y / cellSizeMeters).floor());
  }

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

  LatLng cellCenter(GridCell cell) {
    final x = cell.xIndex * cellSizeMeters + cellSizeMeters / 2;
    final y = cell.yIndex * cellSizeMeters + cellSizeMeters / 2;
    return _fromMercator(x, y);
  }

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
