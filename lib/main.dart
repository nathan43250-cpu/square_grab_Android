import 'package:flutter/material.dart';

import 'expedition_screen.dart';
import 'language_controller.dart';
import 'map_screen.dart';
import 'rules_screen.dart';
import 'settings_screen.dart';
import 'storage_service.dart';
import 'translations.dart';

void main() {
  runApp(const SquareGrabApp());
}

class SquareGrabApp extends StatelessWidget {
  const SquareGrabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Square Grab',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
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

  int _mapRefreshKey = 0;

  @override
  void initState() {
    super.initState();
    _storage.init().then((_) => setState(() => _ready = true));
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
        onExpeditionCommitted: () => setState(() => _mapRefreshKey++),
      ),
      MapScreen(key: ValueKey(_mapRefreshKey), storage: _storage),
      const RulesScreen(),
    ];

    // ListenableBuilder ici permet à toute cette partie (barre de nav
    // comprise) de se redessiner automatiquement dès que la langue change
    // dans le controller, sans avoir à passer par un setState manuel.
    return ListenableBuilder(
      listenable: _languageController,
      builder: (context, _) {
        final lang = _languageController.current;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Square Grab'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: _openSettings,
              ),
            ],
          ),
          body: IndexedStack(index: _currentIndex, children: screens),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (i) => setState(() => _currentIndex = i),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.explore),
                label: AppTranslations.t('exp_tab', lang),
              ),
              NavigationDestination(
                icon: const Icon(Icons.map),
                label: AppTranslations.t('map_tab', lang),
              ),
              NavigationDestination(
                icon: const Icon(Icons.menu_book),
                label: AppTranslations.t('rule_tab', lang),
              ),
            ],
          ),
        );
      },
    );
  }
}
