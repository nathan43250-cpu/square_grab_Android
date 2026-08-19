import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'background_service.dart';
import 'floating_nav_bar.dart';
import 'grid_utils.dart';
import 'language_controller.dart';
import 'storage_service.dart';
import 'transport_mode.dart';
import 'translations.dart';

/// Écran principal pour le suivi en direct d'une expédition.
/// Gère le flux GPS, le service en arrière-plan et l'affichage des statistiques en temps réel.
class ExpeditionScreen extends StatefulWidget {
  final StorageService storage;
  final LanguageController languageController;
  final VoidCallback onExpeditionCommitted;

  const ExpeditionScreen({
    super.key,
    required this.storage,
    required this.languageController,
    required this.onExpeditionCommitted,
  });

  @override
  State<ExpeditionScreen> createState() => _ExpeditionScreenState();
}

class _ExpeditionScreenState extends State<ExpeditionScreen> {
  final GridSystem _gridSystem = const GridSystem(cellSizeMeters: 200);
  final MapController _mapController = MapController();
  
  // Abonnement au flux de positions GPS.
  StreamSubscription<Position>? _positionSub;

  // Zoom minimum pour afficher le quadrillage (performance).
  static const double _minZoomForGrid = 14;

  // États de l'expédition
  bool _isRunning = false;
  bool _isLoadingPosition = false;
  
  // Ensemble des cellules collectées pendant la session actuelle.
  final Set<GridCell> _sessionCells = {};
  
  // Cellules du quadrillage à dessiner (non collectées).
  List<GridCell> _visibleGridCells = [];
  Timer? _gridDebounce;

  // Stats de l'expédition
  LatLng? _currentLatLng;
  Position? _lastPosition;
  double _distanceMeters = 0;
  DateTime? _startedAt;
  
  // Clé de traduction pour le message d'erreur si le GPS échoue.
  String? _errorMessageKey;

  AppLanguage get _lang => widget.languageController.current;

  @override
  void initState() {
    super.initState();
    // Prépare le service de premier plan pour le suivi hors-app.
    ExpeditionForegroundService.init();
    _loadInitialPosition();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _gridDebounce?.cancel();
    // Sécurité : arrête le service si on quitte l'app pendant un suivi.
    if (_isRunning) {
      ExpeditionForegroundService.stop();
    }
    super.dispose();
  }

  /// Tente de récupérer la position initiale pour centrer la carte au démarrage.
  Future<void> _loadInitialPosition() async {
    setState(() => _isLoadingPosition = true);
    try {
      final granted = await _ensurePermission();
      if (!granted) {
        setState(() => _isLoadingPosition = false);
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLatLng = LatLng(position.latitude, position.longitude);
        _isLoadingPosition = false;
      });
    } catch (e) {
      setState(() {
        _errorMessageKey = 'position_error';
        _isLoadingPosition = false;
      });
    }
  }

  /// Vérifie et demande les permissions GPS nécessaires.
  Future<bool> _ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      setState(() => _errorMessageKey = 'gps_disabled_error');
      return false;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      setState(() => _errorMessageKey = 'permission_denied_error');
      return false;
    }
    setState(() => _errorMessageKey = null);
    return true;
  }

  /// Démarre une nouvelle session de suivi.
  Future<void> _startExpedition() async {
    final granted = await _ensurePermission();
    if (!granted) return;

    // Demande l'autorisation d'afficher des notifications (Android 13+).
    await ExpeditionForegroundService.requestPermissions();

    setState(() {
      _isRunning = true;
      _sessionCells.clear();
      _distanceMeters = 0;
      _lastPosition = null;
      _startedAt = DateTime.now();
    });

    // Lance la notification persistante en arrière-plan.
    await ExpeditionForegroundService.start(
      title: AppTranslations.t('notification_title', _lang),
      text: AppTranslations.tCount('notification_text', _lang, 0),
    );

    // Écoute les changements de position GPS en haute précision.
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Met à jour tous les 5 mètres.
    );

    _positionSub = Geolocator.getPositionStream(locationSettings: settings)
        .listen(_onPositionUpdate, onError: (e) {
      setState(() => _errorMessageKey = 'gps_tracking_error');
    });
  }

  /// Traite chaque mise à jour de position reçue du GPS.
  void _onPositionUpdate(Position position) {
    // Calcul de la distance parcourue.
    if (_lastPosition != null) {
      _distanceMeters += Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );
    }
    _lastPosition = position;

    final latLng = LatLng(position.latitude, position.longitude);
    
    // Identification de la cellule actuelle.
    final cell = _gridSystem.cellForPosition(latLng);
    final isNewCell = !_sessionCells.contains(cell);

    setState(() {
      _currentLatLng = latLng;
      _sessionCells.add(cell);
    });

    // Mise à jour de la notification seulement si on change de carré.
    if (isNewCell) {
      ExpeditionForegroundService.updateText(
        AppTranslations.tCount('notification_text', _lang, _sessionCells.length),
      );
    }

    // Centrage automatique de la carte sur la position actuelle.
    _mapController.move(latLng, _mapController.camera.zoom);
  }

  /// Termine l'expédition, demande le mode de transport et enregistre les résultats.
  Future<void> _stopExpedition() async {
    await _positionSub?.cancel();
    _positionSub = null;
    await ExpeditionForegroundService.stop();

    setState(() => _isRunning = false);

    // Si aucun carré n'a été parcouru, on annule.
    if (_sessionCells.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppTranslations.t('no_squares_snackbar', _lang))),
        );
      }
      return;
    }

    // Demande à l'utilisateur comment il s'est déplacé.
    final mode = await _askTransportMode();
    if (mode == null) return; // Annulation si aucun mode choisi.

    // Enregistrement définitif dans Hive.
    final newCount = widget.storage.commitExpedition(_sessionCells, mode);
    widget.onExpeditionCommitted();

    setState(() {
      _sessionCells.clear();
      _distanceMeters = 0;
      _lastPosition = null;
      _startedAt = null;
    });

    // Message de succès avec le bilan.
    if (mounted) {
      final message = AppTranslations.tVars('expedition_result', _lang, {
        'count': newCount.toString(),
        'mode': mode.labelFor(_lang),
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  /// Affiche une feuille modale pour choisir le mode de transport.
  Future<TransportMode?> _askTransportMode() {
    return showModalBottomSheet<TransportMode>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppTranslations.t('transport_prompt_title', _lang),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                for (final mode in TransportMode.values)
                  ListTile(
                    leading: Icon(mode.icon, color: mode.color),
                    title: Text(mode.labelFor(_lang)),
                    onTap: () => Navigator.of(context).pop(mode),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Formate une durée en format lisible (00h00min).
  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final hours = d.inHours.toString().padLeft(2, '0');
    return '${hours}h${minutes}min';
  }

  /// Gère le calcul du quadrillage lors des mouvements de la carte.
  void _onMapEvent(MapEvent event) {
    _gridDebounce?.cancel();
    _gridDebounce = Timer(const Duration(milliseconds: 150), () {
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

  /// Construit la vue de l'expédition (Carte + Stats + Bouton).
  Widget _buildContent(BuildContext context) {
    if (_isLoadingPosition) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Écran d'erreur si la localisation ne fonctionne pas.
    if (_currentLatLng == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  AppTranslations.t(_errorMessageKey ?? 'location_off_title', _lang),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadInitialPosition,
                  child: Text(AppTranslations.t('retry_button', _lang)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Carte plein écran
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLatLng!,
              initialZoom: 17,
              initialRotation: 0,
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
              // Quadrillage des cases vides
              PolygonLayer(
                polygons: _visibleGridCells
                    .where((cell) =>
                        !_sessionCells.contains(cell) &&
                        !widget.storage.isCollected(cell))
                    .map((cell) => Polygon(
                          points: _gridSystem.cellPolygon(cell),
                          color: Colors.transparent,
                          borderColor: Colors.grey.withValues(alpha: 0.5),
                          borderStrokeWidth: 0.8,
                        ))
                    .toList(),
              ),
              // Carrés déjà possédés (historique)
              PolygonLayer(
                polygons: widget.storage.allCollectedCells
                    .where((c) => !_sessionCells.contains(c.cell))
                    .map((c) => Polygon(
                          points: _gridSystem.cellPolygon(c.cell),
                          color: c.mode.color.withValues(alpha: 0.35),
                          borderColor: c.mode.color,
                          borderStrokeWidth: 1,
                        ))
                    .toList(),
              ),
              // Carrés de la session en cours (violet)
              PolygonLayer(
                polygons: _sessionCells
                    .map((cell) => Polygon(
                          points: _gridSystem.cellPolygon(cell),
                          color: Colors.deepPurple.withValues(alpha: 0.45),
                          borderColor: Colors.deepPurple,
                          borderStrokeWidth: 1.5,
                        ))
                    .toList(),
              ),
              // Marqueur GPS
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLatLng!,
                    width: 24,
                    height: 24,
                    child: const Icon(Icons.my_location, color: Colors.blue, size: 24),
                  ),
                ],
              ),
            ],
          ),
          
          // Panneau de statistiques flottant (visible seulement si expédition en cours)
          if (_isRunning)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: SafeArea(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHigh
                            .withValues(alpha: 0.78),
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
                      child: Wrap(
                        alignment: WrapAlignment.spaceEvenly,
                        runSpacing: 6,
                        spacing: 16,
                        children: [
                          _StatChip(
                            icon: Icons.grid_on,
                            label: AppTranslations.tCount(
                                'stat_squares_count', _lang, _sessionCells.length),
                          ),
                          _StatChip(
                            icon: Icons.emoji_events_outlined,
                            label: AppTranslations.tCount(
                                'stat_total_squares', _lang, widget.storage.totalCollected),
                          ),
                          _StatChip(
                            icon: Icons.straighten,
                            label: '${(_distanceMeters / 1000).toStringAsFixed(2)} km',
                          ),
                          if (_startedAt != null)
                            _StatChip(
                              icon: Icons.timer,
                              label: _formatDuration(
                                  DateTime.now().difference(_startedAt!)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          
          // Bouton d'action principal en bas
          Positioned(
            left: 16,
            right: 16,
            bottom: floatingNavBarClearance,
            child: SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isRunning ? _stopExpedition : _startExpedition,
                icon: Icon(_isRunning ? Icons.stop : Icons.play_arrow),
                label: Text(AppTranslations.t(
                    _isRunning ? 'stop_expedition' : 'start_expedition', _lang)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRunning ? Colors.redAccent : null,
                  elevation: 4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Petit composant pour afficher une icône et une valeur dans le panneau de stats.
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: scheme.primary),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
      ],
    );
  }
}
