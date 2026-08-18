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
  StreamSubscription<Position>? _positionSub;

  // En dessous de ce niveau de zoom, on ne dessine plus le quadrillage fin.
  static const double _minZoomForGrid = 14;

  bool _isRunning = false;
  bool _isLoadingPosition = false;
  final Set<GridCell> _sessionCells = {};
  List<GridCell> _visibleGridCells = [];
  Timer? _gridDebounce;
  LatLng? _currentLatLng;
  Position? _lastPosition;
  double _distanceMeters = 0;
  DateTime? _startedAt;
  String? _errorMessageKey; // on stocke la CLÉ de traduction, pas le texte

  AppLanguage get _lang => widget.languageController.current;

  @override
  void initState() {
    super.initState();
    _loadInitialPosition();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _gridDebounce?.cancel();
    super.dispose();
  }

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

  Future<void> _startExpedition() async {
    final granted = await _ensurePermission();
    if (!granted) return;

    setState(() {
      _isRunning = true;
      _sessionCells.clear();
      _distanceMeters = 0;
      _lastPosition = null;
      _startedAt = DateTime.now();
    });

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionSub = Geolocator.getPositionStream(locationSettings: settings)
        .listen(_onPositionUpdate, onError: (e) {
      setState(() => _errorMessageKey = 'gps_tracking_error');
    });
  }

  void _onPositionUpdate(Position position) {
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
    final cell = _gridSystem.cellForPosition(latLng);

    setState(() {
      _currentLatLng = latLng;
      _sessionCells.add(cell);
    });

    _mapController.move(latLng, _mapController.camera.zoom);
  }

  Future<void> _stopExpedition() async {
    await _positionSub?.cancel();
    _positionSub = null;

    setState(() => _isRunning = false);

    if (_sessionCells.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppTranslations.t('no_squares_snackbar', _lang))),
        );
      }
      return;
    }

    final mode = await _askTransportMode();
    if (mode == null) return;

    final newCount = widget.storage.commitExpedition(_sessionCells, mode);
    widget.onExpeditionCommitted();

    setState(() {
      _sessionCells.clear();
      _distanceMeters = 0;
      _lastPosition = null;
      _startedAt = null;
    });

    if (mounted) {
      final message = AppTranslations.tVars('expedition_result', _lang, {
        'count': newCount.toString(),
        'mode': mode.labelFor(_lang),
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

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

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final hours = d.inHours.toString().padLeft(2, '0');
    return '${hours}h${minutes}min';
  }

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
    // Tout l'écran est enveloppé dans ce ListenableBuilder pour se
    // redessiner automatiquement dès que la langue change.
    return ListenableBuilder(
      listenable: widget.languageController,
      builder: (context, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoadingPosition) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_currentLatLng == null) {
      // Pas de position dispo (permission refusée ou GPS désactivé).
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
              // Quadrillage complet des cases visibles à l'écran (contour seul).
              PolygonLayer(
                polygons: _visibleGridCells
                    .where((cell) =>
                        !_sessionCells.contains(cell) &&
                        !widget.storage.isCollected(cell))
                    .map((cell) => Polygon(
                          points: _gridSystem.cellPolygon(cell),
                          color: Colors.transparent,
                          borderColor: Colors.grey.withOpacity(0.5),
                          borderStrokeWidth: 0.8,
                        ))
                    .toList(),
              ),
              // Carrés déjà collectés lors de précédentes expéditions (pour se repérer).
              PolygonLayer(
                polygons: widget.storage.allCollectedCells
                    .where((c) => !_sessionCells.contains(c.cell))
                    .map((c) => Polygon(
                          points: _gridSystem.cellPolygon(c.cell),
                          color: c.mode.color.withOpacity(0.35),
                          borderColor: c.mode.color,
                          borderStrokeWidth: 1,
                        ))
                    .toList(),
              ),
              // Carrés collectés pendant l'expédition en cours.
              PolygonLayer(
                polygons: _sessionCells
                    .map((cell) => Polygon(
                          points: _gridSystem.cellPolygon(cell),
                          color: Colors.deepPurple.withOpacity(0.45),
                          borderColor: Colors.deepPurple,
                          borderStrokeWidth: 1.5,
                        ))
                    .toList(),
              ),
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
          // Panneau de stats en haut, visible seulement pendant une expédition.
          if (_isRunning)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatChip(
                        icon: Icons.grid_on,
                        label: AppTranslations.tCount(
                            'stat_squares_count', _lang, _sessionCells.length),
                      ),
                      _StatChip(
                        icon: Icons.straighten,
                        label: '${(_distanceMeters / 1000).toStringAsFixed(2)} km',
                      ),
                      if (_startedAt != null)
                        _StatChip(
                          icon: Icons.timer,
                          label: _formatDuration(DateTime.now().difference(_startedAt!)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          // Bouton démarrer/terminer en bas.
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              top: false,
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
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.deepPurple),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
