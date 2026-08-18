import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'grid_utils.dart';
import 'language_controller.dart';
import 'storage_service.dart';
import 'transport_mode.dart';
import 'translations.dart';

class MapScreen extends StatefulWidget {
  final StorageService storage;
  final LanguageController languageController;

  const MapScreen({super.key, required this.storage, required this.languageController});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final GridSystem _gridSystem = const GridSystem(cellSizeMeters: 200);
  final MapController _mapController = MapController();

  static const double _minZoomForGrid = 14;

  LatLng? _currentPosition;
  List<GridCell> _visibleGridCells = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _centerOnCurrentPosition();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _centerOnCurrentPosition() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() => _currentPosition = latLng);
      _mapController.move(latLng, 16);
    } catch (_) {
    }
  }

  void _onMapEvent(MapEvent event) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      final camera = _mapController.camera;
      if (camera.zoom < _minZoomForGrid) {
        if (_visibleGridCells.isNotEmpty) {
          setState(() => _visibleGridCells = []);
        }
        return;
      }
      final bounds = camera.visibleBounds;
      setState(() {
        _visibleGridCells = _gridSystem.cellsInBounds(bounds.southWest, bounds.northEast);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.languageController,
      builder: (context, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final lang = widget.languageController.current;
    final cells = widget.storage.allCollectedCells;
    final collectedIds = cells.map((c) => c.cell.id).toSet();
    final center = _currentPosition ?? const LatLng(48.8566, 2.3522);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppTranslations.tCount('map_title', lang, cells.length)),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 16,
              initialRotation: 0, .
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onMapEvent: _onMapEvent,
              onMapReady: () {
                final camera = _mapController.camera;
                if (camera.zoom >= _minZoomForGrid) {
                  _visibleGridCells = _gridSystem.cellsInBounds(
                    camera.visibleBounds.southWest,
                    camera.visibleBounds.northEast,
                  );
                }
                setState(() {});
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.square_grab',
              ),
              PolygonLayer(
                polygons: _visibleGridCells
                    .where((cell) => !collectedIds.contains(cell.id))
                    .map((cell) => Polygon(
                          points: _gridSystem.cellPolygon(cell),
                          color: Colors.transparent,
                          borderColor: Colors.grey.withOpacity(0.5),
                          borderStrokeWidth: 0.8,
                        ))
                    .toList(),
              ),
              PolygonLayer(
                polygons: cells
                    .map((c) => Polygon(
                          points: _gridSystem.cellPolygon(c.cell),
                          color: c.mode.color.withOpacity(0.45),
                          borderColor: c.mode.color,
                          borderStrokeWidth: 1.5,
                        ))
                    .toList(),
              ),
              if (_currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentPosition!,
                      width: 24,
                      height: 24,
                      child: const Icon(Icons.my_location, color: Colors.blue, size: 24),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: _Legend(storage: widget.storage, language: lang),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _centerOnCurrentPosition,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final StorageService storage;
  final AppLanguage language;

  const _Legend({required this.storage, required this.language});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final mode in TransportMode.values)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 12, height: 12, color: mode.color),
                  const SizedBox(width: 6),
                  Text('${mode.labelFor(language)} (${storage.countForMode(mode)})',
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
