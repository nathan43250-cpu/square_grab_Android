import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'expedition_screen.dart';
import 'floating_nav_bar.dart';
import 'language_controller.dart';
import 'map_screen.dart';
import 'rules_screen.dart';
import 'settings_screen.dart';
import 'storage_service.dart';
import 'translations.dart';
import 'zigzag_transition.dart';

/// Point d'entrée principal de l'application.
/// Initialise les services nécessaires (port de communication pour les tâches en arrière-plan)
/// et lance l'application.
void main() {
  // Nécessaire pour la communication entre le service en arrière-plan et
  // l'interface principale de l'app (via flutter_foreground_task).
  FlutterForegroundTask.initCommunicationPort();
  runApp(const SquareGrabApp());
}

/// Widget racine de l'application Square Grab.
/// Définit le thème global (sombre avec accents violets) et configure la navigation de base.
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
      // L'écran RootScreen gère le switch entre les différents onglets de l'app.
      home: const RootScreen(),
    );
  }
}

/// Écran principal gérant le cycle de vie du stockage et le basculement entre les vues.
class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  // Instance du service de stockage Hive pour les carrés collectés.
  final StorageService _storage = StorageService();
  
  // Instance du contrôleur de langue pour gérer l'internationalisation.
  final LanguageController _languageController = LanguageController();
  
  // Flag pour savoir si le stockage a fini son initialisation.
  bool _ready = false;
  
  // Index de l'onglet actuellement affiché.
  int _currentIndex = 0;

  // Clé de rafraîchissement incrémentée à chaque nouvelle expédition validée,
  // forçant MapScreen à se reconstruire pour afficher les nouveaux carrés.
  int _mapRefreshKey = 0;

  @override
  void initState() {
    super.initState();
    // Initialisation asynchrone du service de stockage persistant.
    _storage.init().then((_) => setState(() => _ready = true));
  }

  /// Ouvre l'écran des paramètres pour changer la langue de l'application.
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
    // Affiche un indicateur de chargement tant que le stockage n'est pas prêt.
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Définition des écrans correspondant aux 3 onglets.
    final screens = [
      ExpeditionScreen(
        storage: _storage,
        languageController: _languageController,
        // Callback appelé quand une expédition se termine pour notifier la carte.
        onExpeditionCommitted: () => setState(() => _mapRefreshKey++),
      ),
      MapScreen(
        // La ValueKey force la reconstruction complète du widget MapScreen.
        key: ValueKey(_mapRefreshKey),
        storage: _storage,
        languageController: _languageController,
      ),
      const RulesScreen(),
    ];

    // ListenableBuilder réagit automatiquement aux changements dans LanguageController.
    return ListenableBuilder(
      listenable: _languageController,
      builder: (context, _) {
        final lang = _languageController.current;
        return Scaffold(
          // extendBody permet au contenu de passer SOUS la barre de navigation flottante.
          extendBody: true,
          appBar: AppBar(
            title: const Text('Square Grab'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: _openSettings,
              ),
            ],
          ),
          // ZigzagPageSwitcher assure une transition fluide entre les onglets.
          body: ZigzagPageSwitcher(index: _currentIndex, children: screens),
          // Barre de navigation flottante personnalisée.
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
