import 'package:flutter/material.dart';

import 'expedition_screen.dart';
import 'map_screen.dart';
import 'rules_screen.dart';
import 'storage_service.dart';

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
  bool _ready = false;
  int _currentIndex = 0;

  // Sert à forcer le rafraîchissement de la carte quand une expédition
  // vient d'être validée.
  int _mapRefreshKey = 0;

  @override
  void initState() {
    super.initState();
    _storage.init().then((_) => setState(() => _ready = true));
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

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.explore), label: 'EXP'),
          NavigationDestination(icon: Icon(Icons.map), label: 'MAP'),
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'RULE'),
        ],
      ),
    );
  }
}
