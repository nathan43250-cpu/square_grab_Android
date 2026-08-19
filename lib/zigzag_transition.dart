import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Composant de transition personnalisé pour basculer entre les pages.
/// Il remplace le changement brusque d'un IndexedStack par une animation de balayage.
/// Concept : il capture une image de l'écran sortant et l'anime pour révéler l'écran entrant.
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
  // Clé pour identifier la zone à capturer en image.
  final GlobalKey _boundaryKey = GlobalKey();
  
  late final AnimationController _controller;
  late final Animation<double> _animation;

  late int _currentIndex;
  bool _forward = true;
  
  // Photo statique de l'ancien écran utilisée pendant la transition.
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
    // Déclenche la transition si l'index change.
    if (widget.index != _currentIndex) {
      _forward = widget.index > _currentIndex;
      _switchWithSnapshot(widget.index);
    }
  }

  /// Procédure de transition :
  /// 1. Capture l'état actuel des pixels via un RenderRepaintBoundary.
  /// 2. Change l'index de l'IndexedStack pour que le nouvel écran commence à se construire dessous.
  /// 3. Anime le retrait de l'image capturée.
  Future<void> _switchWithSnapshot(int newIndex) async {
    ui.Image? image;
    try {
      final boundary =
          _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      image = await boundary?.toImage(
        pixelRatio: MediaQuery.of(context).devicePixelRatio,
      );
    } catch (_) {
      // Si la capture échoue, on change simplement l'index sans animation.
    }

    if (!mounted) return;
    setState(() {
      _snapshot = image;
      _currentIndex = newIndex;
    });

    // Lance l'animation de retrait de la photo.
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
        // La pile d'écrans réelle. Seul l'écran à _currentIndex est "vivant".
        RepaintBoundary(
          key: _boundaryKey,
          child: IndexedStack(index: _currentIndex, children: widget.children),
        ),
        // Superposition de l'image de l'ancien écran qui se réduit.
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

/// Clipper personnalisé qui réduit la largeur visible d'un rectangle.
class _ShrinkWipeClipper extends CustomClipper<Rect> {
  final double progress;     // Progression de l'animation (0.0 à 1.0).
  final bool anchorRight;    // Sens du retrait (vers la gauche ou la droite).

  const _ShrinkWipeClipper({required this.progress, required this.anchorRight});

  @override
  Rect getClip(Size size) {
    final edgeX = size.width * progress;
    if (anchorRight) {
      // L'image se retire de la gauche vers la droite.
      return Rect.fromLTRB(edgeX, 0, size.width, size.height);
    } else {
      // L'image se retire de la droite vers la gauche.
      return Rect.fromLTRB(0, 0, size.width - edgeX, size.height);
    }
  }

  @override
  bool shouldReclip(covariant _ShrinkWipeClipper oldClipper) {
    return oldClipper.progress != progress || oldClipper.anchorRight != anchorRight;
  }
}
