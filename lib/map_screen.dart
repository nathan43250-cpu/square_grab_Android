import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'floating_nav_bar.dart';
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

  // En dessous de ce niveau de zoom, on ne dessine plus le quadrillage fin :
  // ça ne serait de toute façon pas lisible, et ça évite le lag au dézoom.
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
      // Le "initialCenter" de FlutterMap ne s'applique qu'à la création du
      // widget : comme la position arrive de façon asynchrone après coup,
      // il faut recentrer la caméra manuellement une fois qu'on l'a.
      _mapController.move(latLng, 16);
    } catch (_) {
      // Pas grave si ça échoue, on garde le centre par défaut.
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
    // Enveloppe tout l'écran pour qu'il se redessine dès que la langue change.
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
              initialRotation: 0,
              // Désactive la rotation : la carte reste toujours orientée nord.
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
              // Quadrillage complet des cases visibles (non collectées = juste contour).
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
              // Cases déjà collectées, colorées par mode de transport.
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
            top: 12,
            child: _Legend(storage: widget.storage, language: lang),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: floatingNavBarClearance - 72),
        child: FloatingActionButton(
          onPressed: _centerOnCurrentPosition,
          child: const Icon(Icons.my_location),
        ),
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
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh.withOpacity(0.78),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppTranslations.t('legend_title', language).toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              for (final mode in TransportMode.values)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: mode.color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: mode.color.withOpacity(0.6),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        mode.labelFor(language),
                        style: TextStyle(fontSize: 13, color: scheme.onSurface),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${storage.countForMode(mode)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
