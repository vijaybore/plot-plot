import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

/// A real 3D cube dice — six faces, each with proper pip dots, that
/// tumbles through multiple rotations before settling on the rolled
/// value. Built with Flutter's Matrix4/Transform (no external 3D
/// package needed), the same "CSS-cube" trick used for flip-card and
/// rotating-cube effects.
///
/// Usage: bump [rollTrigger] (any changing int, e.g. a roll counter)
/// every time a new roll starts, and pass the final [value] (1-6) —
/// the cube will tumble and land showing that face, Ludo-style.
class Dice3D extends StatefulWidget {
  final int value;
  final int rollTrigger;
  final double size;
  final bool disabled;

  const Dice3D({
    super.key,
    required this.value,
    required this.rollTrigger,
    this.size = 56,
    this.disabled = false,
  });

  @override
  State<Dice3D> createState() => _Dice3DState();
}

class _Dice3DState extends State<Dice3D> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _rx;
  late Animation<double> _ry;
  double _fromRx = 0, _fromRy = 0;

  // Rotation (rx, ry) that brings each face value to front-facing.
  static const Map<int, (double, double)> _target = {
    1: (0, 0),
    6: (0, math.pi),
    2: (0, math.pi / 2),
    5: (0, -math.pi / 2),
    3: (-math.pi / 2, 0),
    4: (math.pi / 2, 0),
  };

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
    _setupAnim(widget.value);
  }

  void _setupAnim(int value) {
    final target = _target[value] ?? (0, 0);
    // A couple of extra full spins on top of the target angle so it
    // visibly tumbles before settling, like a physical die.
    final toRx = _fromRx + (2 * math.pi * 2) + target.$1;
    final toRy = _fromRy + (2 * math.pi * 3) + target.$2;
    _rx = Tween<double>(begin: _fromRx, end: toRx)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ry = Tween<double>(begin: _fromRy, end: toRy)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void didUpdateWidget(covariant Dice3D old) {
    super.didUpdateWidget(old);
    if (widget.rollTrigger != old.rollTrigger) {
      _fromRx = _rx.value;
      _fromRy = _ry.value;
      _setupAnim(widget.value);
      _ctrl.forward(from: 0);
    } else if (widget.value != old.value) {
      // Value corrected without a new roll trigger (rare) — snap setup.
      _setupAnim(widget.value);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    // Explicit fixed size on the outermost widget — this is deliberate.
    // The previous version returned a bare Stack with no size of its own,
    // trusting it to size itself from its non-positioned child. That's
    // supposed to work, but in this widget's actual parent chain
    // (Container with no width/height, inside a Row/header strip) it was
    // collapsing to zero and rendering nothing. An explicit SizedBox root
    // can't collapse regardless of what constraints the parent hands down.
    return SizedBox(
      width: s,
      height: s * 1.14, // a bit of extra room below for the contact shadow
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) {
          final cubeRx = _rx.value, cubeRy = _ry.value;
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // Soft contact shadow so the cube reads as sitting on a
              // surface rather than floating flat against the background.
              Positioned(
                bottom: 0,
                child: Container(
                  width: s * 0.78,
                  height: s * 0.16,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(s),
                    gradient: RadialGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.black.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0025)
                    ..rotateX(cubeRx)
                    ..rotateY(cubeRy),
                  child: SizedBox(
                    width: s,
                    height: s,
                    child: Stack(children: [
                      _face(1, s, rx: 0, ry: 0, cubeRx: cubeRx, cubeRy: cubeRy),
                      _face(6, s, rx: 0, ry: math.pi, cubeRx: cubeRx, cubeRy: cubeRy),
                      _face(2, s, rx: 0, ry: math.pi / 2, cubeRx: cubeRx, cubeRy: cubeRy),
                      _face(5, s, rx: 0, ry: -math.pi / 2, cubeRx: cubeRx, cubeRy: cubeRy),
                      _face(3, s, rx: -math.pi / 2, ry: 0, cubeRx: cubeRx, cubeRy: cubeRy),
                      _face(4, s, rx: math.pi / 2, ry: 0, cubeRx: cubeRx, cubeRy: cubeRy),
                    ]),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Flutter's Transform/Stack paints every child in code order regardless
  /// of true 3D depth — it does not hide faces pointing away from the
  /// viewer on its own. Without this, faces on the back of the cube can
  /// paint over the front face and the number becomes unreadable or wrong.
  /// This computes each face's outward normal after the cube's current
  /// rotation and skips painting it once it's facing away (dot product
  /// with the viewer direction turns negative).
  bool _isFacingViewer(double rx, double ry, double cubeRx, double cubeRy) {
    final composite = Matrix4.identity()
      ..rotateX(cubeRx)
      ..rotateY(cubeRy)
      ..rotateX(rx)
      ..rotateY(ry);
    final normal = composite.transform3(Vector3(0, 0, 1));
    return normal.z > 0;
  }

  Widget _face(int value, double s,
      {required double rx, required double ry, required double cubeRx, required double cubeRy}) {
    if (!_isFacingViewer(rx, ry, cubeRx, cubeRy)) {
      return const SizedBox.shrink();
    }
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..rotateX(rx)
        ..rotateY(ry)
        ..translateByDouble(0.0, 0.0, s / 2, 1.0),
      child: Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.disabled
                ? const [Color(0xFF5A5A5A), Color(0xFF3A3A3A)]
                : const [Color(0xFFFFFFFF), Color(0xFFE9E9E9)],
            stops: const [0.0, 1.0],
          ),
          borderRadius: BorderRadius.circular(s * 0.18),
          border: Border.all(color: Colors.black.withValues(alpha: 0.12), width: 1),
          boxShadow: const [
            BoxShadow(color: Colors.black38, blurRadius: 5, offset: Offset(0, 2)),
          ],
        ),
        padding: EdgeInsets.all(s * 0.14),
        child: Stack(children: [
          // Faint diagonal gloss streak for a glossy, polished-plastic feel.
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(s * 0.14),
              child: Opacity(
                opacity: widget.disabled ? 0.0 : 0.5,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: FractionallySizedBox(
                    widthFactor: 0.7,
                    heightFactor: 0.35,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(s * 0.5),
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.55),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          _Pips(value: value, dotColor: widget.disabled ? Colors.white70 : const Color(0xFF1A1A1A)),
        ]),
      ),
    );
  }
}

/// Standard 3x3 pip layout for a die face, 1 through 6.
class _Pips extends StatelessWidget {
  final int value;
  final Color dotColor;
  const _Pips({required this.value, required this.dotColor});

  // Grid positions (row, col) in a 3x3 grid used by each face value.
  static const Map<int, List<(int, int)>> _layout = {
    1: [(1, 1)],
    2: [(0, 0), (2, 2)],
    3: [(0, 0), (1, 1), (2, 2)],
    4: [(0, 0), (0, 2), (2, 0), (2, 2)],
    5: [(0, 0), (0, 2), (1, 1), (2, 0), (2, 2)],
    6: [(0, 0), (0, 2), (1, 0), (1, 2), (2, 0), (2, 2)],
  };

  @override
  Widget build(BuildContext context) {
    final active = _layout[value] ?? const [(1, 1)];
    return LayoutBuilder(builder: (context, constraints) {
      final dot = constraints.maxWidth / 4.6;
      return GridView.count(
        crossAxisCount: 3,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(9, (i) {
          final r = i ~/ 3, c = i % 3;
          final on = active.contains((r, c));
          return Center(
            child: on
                ? Container(
                    width: dot,
                    height: dot,
                    decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                  )
                : const SizedBox.shrink(),
          );
        }),
      );
    });
  }
}