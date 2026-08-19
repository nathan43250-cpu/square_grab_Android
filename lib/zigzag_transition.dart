import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Remplace un IndexedStack classique par une version animée : quand
/// [index] change, une "photo" figée de l'ancien écran balaie l'écran
/// pour se retirer et révéler le nouvel écran (déjà en train de charger
/// juste en dessous, ce qui évite tout temps mort à la fin du balayage).
///
/// Contrairement à une v1 naïve, on ne garde JAMAIS deux écrans lourds
/// (avec leurs cartes OpenStreetMap actives) montés en même temps — un
/// seul écran vivant à la fois, plus une image statique par-dessus
/// pendant la transition seulement. Beaucoup plus léger.
class ZigzagPageSwitcher extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;

  const ZigzagPageSwitcher({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<ZigzagPageSwitcher> createState() => _ZigzagPageSwitcherState();
}

class _ZigzagPageSwitcherState extends State<ZigzagPageSwitcher>
    with SingleTickerProviderStateMixin {
  final GlobalKey _boundaryKey = GlobalKey();
  late final AnimationController _controller;
  late final Animation<double> _animation;

  late int _currentIndex;
  bool _forward = true;
  ui.Image? _snapshot;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
  }

  @override
  void didUpdateWidget(covariant ZigzagPageSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != _currentIndex) {
      _forward = widget.index > _currentIndex;
      _switchWithSnapshot(widget.index);
    }
  }

  /// Capture l'écran actuel en image, PUIS bascule immédiatement l'écran
  /// vivant vers le nouvel onglet (qui commence donc son chargement tout
  /// de suite, caché sous la photo pendant que celle-ci glisse et se
  /// retire progressivement).
  Future<void> _switchWithSnapshot(int newIndex) async {
    ui.Image? image;
    try {
      final boundary =
          _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      image = await boundary?.toImage(
        pixelRatio: MediaQuery.of(context).devicePixelRatio,
      );
    } catch (_) {
      // En cas d'échec (rare), on bascule quand même, juste sans transition visuelle.
    }

    if (!mounted) return;
    setState(() {
      _snapshot = image;
      _currentIndex = newIndex;
    });

    _controller.forward(from: 0).whenComplete(() {
      if (mounted) setState(() => _snapshot = null);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _snapshot?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Le seul écran réellement "vivant" à tout instant : déjà sur le
        // nouvel onglet dès le début de la transition.
        RepaintBoundary(
          key: _boundaryKey,
          child: IndexedStack(index: _currentIndex, children: widget.children),
        ),
        // La photo de l'ancien écran, qui se retire progressivement.
        if (_snapshot != null)
          AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              return ClipRect(
                clipper: _ShrinkWipeClipper(
                  progress: _animation.value,
                  anchorRight: _forward,
                ),
                child: RawImage(
                  image: _snapshot,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              );
            },
          ),
      ],
    );
  }
}

/// Rétrécit progressivement le rectangle visible de la photo, ancré soit
/// à droite (elle se retire vers la gauche), soit à gauche (elle se
/// retire vers la droite), selon [anchorRight].
class _ShrinkWipeClipper extends CustomClipper<Rect> {
  final double progress;
  final bool anchorRight;

  const _ShrinkWipeClipper({required this.progress, required this.anchorRight});

  @override
  Rect getClip(Size size) {
    final edgeX = size.width * progress;
    if (anchorRight) {
      return Rect.fromLTRB(edgeX, 0, size.width, size.height);
    } else {
      return Rect.fromLTRB(0, 0, size.width - edgeX, size.height);
    }
  }

  @override
  bool shouldReclip(covariant _ShrinkWipeClipper oldClipper) {
    return oldClipper.progress != progress || oldClipper.anchorRight != anchorRight;
  }
}
