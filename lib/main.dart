import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'background_service.dart';
import 'expedition_screen.dart';
import 'floating_nav_bar.dart';
import 'language_controller.dart';
import 'map_screen.dart';
import 'rules_screen.dart';
import 'settings_screen.dart';
import 'storage_service.dart';
import 'translations.dart';

void main() {
  FlutterForegroundTask.initCommunicationPort();
  runApp(const SquareGrabApp());
}

class SquareGrabApp extends StatelessWidget {
  const SquareGrabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Square Grab',

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
        languageController: _languageController,
        onExpeditionCommitted: () => setState(() => _mapRefreshKey++),
      ),
      MapScreen(
        key: ValueKey(_mapRefreshKey),
        storage: _storage,
        languageController: _languageController,
      ),
      const RulesScreen(),
    ];

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
