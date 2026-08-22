import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import 'background_service.dart';
import 'expedition_screen.dart';
import 'floating_nav_bar.dart';
import 'language_controller.dart';
import 'map_screen.dart';
import 'rules_screen.dart';
import 'settings_screen.dart';
import 'storage_service.dart';
import 'translations.dart';
import 'zigzag_transition.dart';

/// Nom du "store" de tuiles hors ligne, utilisé partout où une carte est
/// affichée dans l'app (voir expedition_screen.dart et map_screen.dart).
const String offlineMapStoreName = 'squareGrabTiles';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Nécessaire pour la communication entre le service en arrière-plan et
  // l'interface principale de l'app.
  FlutterForegroundTask.initCommunicationPort();

  // Initialise le système de cache des tuiles de carte : chaque zone
  // consultée est automatiquement sauvegardée sur le téléphone, et reste
  // ensuite affichable même sans connexion internet.
  await FMTCObjectBoxBackend().initialise();
  await FMTCStore(offlineMapStoreName).manage.create();

  runApp(const SquareGrabApp());
}

class SquareGrabApp extends StatelessWidget {
  const SquareGrabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Square Grab',
      // Thème sombre par défaut : le violet reste la couleur d'accent,
      // mais avec des surfaces sombres pour un rendu plus moderne.
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurpleAccent,
          brightness: Brightness.dark,
        ),
      ),
      home: const RootScreen(),
    );
  }
}

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  final StorageService _storage = StorageService();
  final LanguageController _languageController = LanguageController();
  bool _ready = false;
  int _currentIndex = 0;

  // Sert à forcer le rafraîchissement de la carte quand une expédition
  // vient d'être validée.
  int _mapRefreshKey = 0;

  @override
  void initState() {
    super.initState();
    Future.wait([_storage.init(), _languageController.init()])
        .then((_) => setState(() => _ready = true));
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(controller: _languageController),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final screens = [
      ExpeditionScreen(
        storage: _storage,
        languageController: _languageController,
        onExpeditionCommitted: () => setState(() => _mapRefreshKey++),
      ),
      MapScreen(
        key: ValueKey(_mapRefreshKey),
        storage: _storage,
        languageController: _languageController,
      ),
      RulesScreen(languageController: _languageController),
    ];

    // ListenableBuilder ici permet à toute cette partie (barre de nav
    // comprise) de se redessiner automatiquement dès que la langue change
    // dans le controller, sans avoir à passer par un setState manuel.
    return ListenableBuilder(
      listenable: _languageController,
      builder: (context, _) {
        final lang = _languageController.current;
        return Scaffold(
          extendBody: true,
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              ZigzagPageSwitcher(index: _currentIndex, children: screens),
              // Bulle flottante pour accéder aux paramètres, à la place
              // de l'ancienne barre de titre supprimée pour laisser plus
              // de place à la carte.
              Positioned(
                top: 12,
                right: 12,
                child: SafeArea(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHigh
                              .withOpacity(0.78),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.settings),
                          onPressed: _openSettings,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: FloatingNavBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            items: [
              NavItem(
                icon: Icons.explore_outlined,
                selectedIcon: Icons.explore,
                label: AppTranslations.t('exp_tab', lang),
              ),
              NavItem(
                icon: Icons.map_outlined,
                selectedIcon: Icons.map,
                label: AppTranslations.t('map_tab', lang),
              ),
              NavItem(
                icon: Icons.menu_book_outlined,
                selectedIcon: Icons.menu_book,
                label: AppTranslations.t('rule_tab', lang),
              ),
            ],
          ),
        );
      },
    );
  }
}
