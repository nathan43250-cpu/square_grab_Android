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

/// Écran de visualisation globale des carrés collectés.
/// Affiche une carte interactive avec le quadrillage des zones parcourues et à parcourir.
class MapScreen extends StatefulWidget {
  final StorageService storage;
  final LanguageController languageController;

  const MapScreen({super.key, required this.storage, required this.languageController});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Système de grille globale (200m).
  final GridSystem _gridSystem = const GridSystem(cellSizeMeters: 200);
  
  // Contrôleur de la carte pour gérer les déplacements et le zoom.
  final MapController _mapController = MapController();

  // Seuil de zoom : en dessous de 14, le quadrillage n'est plus calculé/affiché pour la performance.
  static const double _minZoomForGrid = 14;

  // Position GPS actuelle de l'utilisateur.
  LatLng? _currentPosition;
  
  // Liste des cellules actuellement visibles dans la vue de la carte.
  List<GridCell> _visibleGridCells = [];
  
  // Timer pour retarder le calcul du quadrillage pendant le mouvement de la carte (debounce).
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Tente de centrer la carte sur la position actuelle dès l'ouverture.
    _centerOnCurrentPosition();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  /// Récupère la position GPS actuelle et déplace la caméra de la carte.
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
      // Centre la vue sur l'utilisateur avec un zoom de 16.
      _mapController.move(latLng, 16);
    } catch (_) {
      // Échec silencieux si le GPS est inaccessible.
    }
  }

  /// Appelé à chaque mouvement de la carte (pan/zoom).
  /// Calcule quelles cellules de la grille doivent être dessinées.
  void _onMapEvent(MapEvent event) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      final camera = _mapController.camera;
      
      // Si on dézoome trop, on vide la liste pour ne plus rien dessiner.
      if (camera.zoom < _minZoomForGrid) {
        if (_visibleGridCells.isNotEmpty) {
          setState(() => _visibleGridCells = []);
        }
        return;
      }
      
      // Sinon, on calcule les cellules comprises dans les limites visibles.
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

  /// Construit le contenu de l'écran avec la carte et les superpositions.
  Widget _buildContent(BuildContext context) {
    final lang = widget.languageController.current;
    final cells = widget.storage.allCollectedCells;
    final collectedIds = cells.map((c) => c.cell.id).toSet();
    final center = _currentPosition ?? const LatLng(48.8566, 2.3522); // Paris par défaut

    return Scaffold(
      appBar: AppBar(
        title: Text(AppTranslations.tCount('map_title', lang, cells.length)),
      ),
      body: Stack(
        children: [
          // Widget de carte OpenStreetMap
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 16,
              initialRotation: 0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onMapEvent: _onMapEvent,
              onMapReady: () {
                // Initialisation du quadrillage dès que la carte est prête.
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
              // Couche des tuiles de la carte
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.square_grab',
              ),
              // Couche du quadrillage (cases non collectées)
              PolygonLayer(
                polygons: _visibleGridCells
                    .where((cell) => !collectedIds.contains(cell.id))
                    .map((cell) => Polygon(
                          points: _gridSystem.cellPolygon(cell),
                          color: Colors.transparent,
                          borderColor: Colors.grey.withValues(alpha: 0.5),
                          borderStrokeWidth: 0.8,
                        ))
                    .toList(),
              ),
              // Couche des carrés collectés (pleins, avec couleur par mode)
              PolygonLayer(
                polygons: cells
                    .map((c) => Polygon(
                          points: _gridSystem.cellPolygon(c.cell),
                          color: c.mode.color.withValues(alpha: 0.45),
                          borderColor: c.mode.color,
                          borderStrokeWidth: 1.5,
                        ))
                    .toList(),
              ),
              // Marqueur bleu de position actuelle
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
          // Légende flottante en haut à gauche
          Positioned(
            left: 12,
            top: 12,
            child: _Legend(storage: widget.storage, language: lang),
          ),
        ],
      ),
      // Bouton de recentrage, décalé pour ne pas être caché par la barre de navigation
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

/// Affiche une légende translucide détaillant les carrés collectés par mode.
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
            color: scheme.surfaceContainerHigh.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
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
              // Liste des compteurs pour chaque mode de transport
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
                              color: mode.color.withValues(alpha: 0.6),
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
                      // Badge affichant le nombre de carrés
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
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
