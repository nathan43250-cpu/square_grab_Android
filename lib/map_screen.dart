import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lat long2/lat long.dart';

import 'grid_utils.dart';
import 'storage_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final GridSystem _gridSystem = const GridSystem(cellSizeMeters: 100);
  final StorageService _storage = StorageService();
  final MapController _mapController = MapController();

  StreamSubscription<Position>? _positionSub;
  LatLng? _currentPosition;
  int _score = 0;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _storage.init();
    _score = _storage.totalCollected;
    await _ensureLocationPermission();
    _startTracking();
    setState(() => _ready = true);
  }

  Future<void> _ensureLocationPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      // L'utilisateur doit activer la permission manuellement dans les
      // paramètres système. On pourrait afficher un dialogue ici.
      return;
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      // GPS désactivé sur l'appareil.
      return;
    }
  }

  void _startTracking() {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // recalcul seulement si on bouge d'au moins 5m
    );

    _positionSub = Geolocator.getPositionStream(locationSettings: settings)
        .listen(_onPositionUpdate);
  }

  void _onPositionUpdate(Position position) {
    final latLng = LatLng(position.latitude, position.longitude);
    final cell = _gridSystem.cellForPosition(latLng);

    final isNew = _storage.collect(cell);

    setState(() {
      _currentPosition = latLng;
      if (isNew) _score = _storage.totalCollected;
    });

    // Centre la carte sur le joueur.
    _mapController.move(latLng, _mapController.camera.zoom);
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final start = _currentPosition ?? const LatLng(48.8566, 2.3522); // Paris par défaut

    return Scaffold(
      appBar: AppBar(
        title: Text('Carrés collectés : $_score'),
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: start,
          initialZoom: 17,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.square_grab',
          ),
          PolygonLayer(
            polygons: _storage.allCollectedCells
                .map((cell) => Polygon(
                      points: _gridSystem.cellPolygon(cell),
                      color: Colors.deepPurple.withOpacity(0.35),
                      borderColor: Colors.deepPurple,
                      borderStrokeWidth: 1.5,
                    ))
                .toList(),
          ),
          if (_currentPosition != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: _currentPosition!,
                  width: 20,
                  height: 20,
                  child: const Icon(Icons.my_location, color: Colors.blue),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
