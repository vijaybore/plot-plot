import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Compact DiceWidget – sits in the main-road header strip
// ─────────────────────────────────────────────────────────────────────────────
class DiceWidget extends StatefulWidget {
  final int value;
  final bool isRolling;
  final VoidCallback onRoll;
  final bool canRoll;

  const DiceWidget({
    super.key,
    required this.value,
    required this.isRolling,
    required this.onRoll,
    required this.canRoll,
  });

  @override
  State<DiceWidget> createState() => _DiceWidgetState();
}

class _DiceWidgetState extends State<DiceWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _shake;
  late Animation<double> _bounce;
  int _display = 1;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _display = widget.value;
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _shake = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _bounce = Tween<double>(begin: 1, end: 1.15)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.bounceOut));
  }

  @override
  void didUpdateWidget(DiceWidget old) {
    super.didUpdateWidget(old);
    if (widget.isRolling && !old.isRolling) _animate();
    if (!widget.isRolling) setState(() => _display = widget.value);
  }

  void _animate() {
    _ctrl.reset();
    _ctrl.forward();
    int t = 0;
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 70));
      if (!mounted) return false;
      setState(() => _display = _rng.nextInt(6) + 1);
      return ++t < 10 && widget.isRolling;
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) => Transform.translate(
            offset: Offset(sin(_shake.value * pi * 8) * 4, 0),
            child: Transform.scale(scale: _bounce.value, child: child),
          ),
          child: GestureDetector(
            onTap: widget.canRoll && !widget.isRolling ? widget.onRoll : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52, height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Colors.white, Color(0xFFF0EEE8)],
                ),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: widget.canRoll ? AppColors.primary : const Color(0xFFCCCCCC),
                  width: widget.canRoll ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.canRoll
                        ? AppColors.primary.withValues(alpha: 0.6)
                        : Colors.black26,
                    blurRadius: widget.canRoll ? 16 : 4,
                    spreadRadius: widget.canRoll ? 2 : 0,
                  ),
                  const BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4, offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: CustomPaint(
                  size: const Size(36, 36),
                  painter: _PipPainter(_display),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          widget.isRolling ? '...' : (widget.canRoll ? 'Dice' : '${widget.value}'),
          style: TextStyle(
            color: widget.canRoll ? AppColors.accent : AppColors.textSecondary,
            fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Floating full-screen dice button (shown at bottom when it's your turn)
// ─────────────────────────────────────────────────────────────────────────────
class FloatingDiceButton extends StatefulWidget {
  final int value;
  final bool isRolling;
  final VoidCallback onRoll;
  final bool canRoll;
  final String currentPlayerName;
  final Color currentPlayerColor;

  const FloatingDiceButton({
    super.key,
    required this.value,
    required this.isRolling,
    required this.onRoll,
    required this.canRoll,
    required this.currentPlayerName,
    required this.currentPlayerColor,
  });

  @override
  State<FloatingDiceButton> createState() => _FloatingDiceButtonState();
}

class _FloatingDiceButtonState extends State<FloatingDiceButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }

  @override
  void dispose() { _pulse.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (!widget.canRoll || widget.isRolling) {
      return const SizedBox.shrink();
    }
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) => Transform.scale(
        scale: 1.0 + _pulse.value * 0.06,
        child: child,
      ),
      child: GestureDetector(
        onTap: widget.onRoll,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.currentPlayerColor, AppColors.primary],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: widget.currentPlayerColor.withValues(alpha: 0.6),
                blurRadius: 18, spreadRadius: 2,
              ),
            ],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('🎲', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ROLL DICE',
                  style: TextStyle(color: Colors.white,
                      fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                Text('${widget.currentPlayerName}\'s turn',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 9)),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  BottomBarDice — a decorative isometric "3D" die that sits centered in the
//  dark bottom control bar. Purely presentational (the real roll happens via
//  DiceWidget / FloatingDiceButton on the board) — it gives the bottom bar a
//  tactile, physical focal point between the two player boxes.
//  Faces shown: TOP = 1 pip, LEFT side = 3 pips, RIGHT side = 2 pips.
// ─────────────────────────────────────────────────────────────────────────────
class BottomBarDice extends StatefulWidget {
  const BottomBarDice({super.key});

  @override
  State<BottomBarDice> createState() => _BottomBarDiceState();
}

class _BottomBarDiceState extends State<BottomBarDice>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bob;

  @override
  void initState() {
    super.initState();
    _bob = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
  }

  @override
  void dispose() { _bob.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bob,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, -2 * _bob.value),
        child: child,
      ),
      child: SizedBox(
        width: 46,
        height: 50,
        child: CustomPaint(painter: _IsoDiePainter()),
      ),
    );
  }
}

class _IsoDiePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cx = w / 2;
    // Isometric cube: top diamond + two side parallelograms.
    final top    = Offset(cx, 0);
    final left   = Offset(0, h * 0.30);
    final right  = Offset(w, h * 0.30);
    final center = Offset(cx, h * 0.55);
    final bottomL = Offset(0, h * 0.30 + h * 0.45);
    final bottomR = Offset(w, h * 0.30 + h * 0.45);
    final bottomC = Offset(cx, h);

    // Soft ground shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, h + 2), width: w * 0.8, height: 6),
      shadowPaint,
    );

    // TOP face (lightest — catches the light) — shows 1 pip
    final topPath = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(right.dx, right.dy)
      ..lineTo(center.dx, center.dy)
      ..lineTo(left.dx, left.dy)
      ..close();
    canvas.drawPath(topPath, Paint()..color = const Color(0xFFFDFDF7));
    canvas.drawPath(topPath, Paint()
      ..color = const Color(0xFFCFCABF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);
    _pip(canvas, Offset(cx, h * 0.27), 2.6);

    // LEFT face (mid tone) — shows 3 pips
    final leftPath = Path()
      ..moveTo(left.dx, left.dy)
      ..lineTo(center.dx, center.dy)
      ..lineTo(bottomC.dx, bottomC.dy)
      ..lineTo(bottomL.dx, bottomL.dy)
      ..close();
    canvas.drawPath(leftPath, Paint()..color = const Color(0xFFE3DECF));
    canvas.drawPath(leftPath, Paint()
      ..color = const Color(0xFFB8B2A0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);
    final lc = Offset((left.dx + center.dx + bottomC.dx + bottomL.dx) / 4,
        (left.dy + center.dy + bottomC.dy + bottomL.dy) / 4);
    _pip(canvas, Offset(lc.dx - w * 0.09, lc.dy - h * 0.09), 2.2);
    _pip(canvas, lc, 2.2);
    _pip(canvas, Offset(lc.dx + w * 0.09, lc.dy + h * 0.09), 2.2);

    // RIGHT face (darkest — shadow side) — shows 2 pips
    final rightPath = Path()
      ..moveTo(right.dx, right.dy)
      ..lineTo(bottomR.dx, bottomR.dy)
      ..lineTo(bottomC.dx, bottomC.dy)
      ..lineTo(center.dx, center.dy)
      ..close();
    canvas.drawPath(rightPath, Paint()..color = const Color(0xFFC9C3B2));
    canvas.drawPath(rightPath, Paint()
      ..color = const Color(0xFF9C9686)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);
    final rc = Offset((right.dx + bottomR.dx + bottomC.dx + center.dx) / 4,
        (right.dy + bottomR.dy + bottomC.dy + center.dy) / 4);
    _pip(canvas, Offset(rc.dx - w * 0.08, rc.dy - h * 0.06), 2.2);
    _pip(canvas, Offset(rc.dx + w * 0.08, rc.dy + h * 0.06), 2.2);
  }

  void _pip(Canvas canvas, Offset o, double r) {
    canvas.drawCircle(o.translate(0.4, 0.5), r,
        Paint()..color = Colors.black.withValues(alpha: 0.35));
    canvas.drawCircle(o, r, Paint()..color = const Color(0xFF2A2A2A));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Classic pip painter
// ─────────────────────────────────────────────────────────────────────────────
class _PipPainter extends CustomPainter {
  final int value;
  _PipPainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    // Shadow pip
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
    // Main pip
    final main = Paint()..color = const Color(0xFFD32F2F);

    final r = size.width * 0.105;
    for (final o in _positions(size)) {
      canvas.drawCircle(o.translate(0.5, 0.8), r, shadow);
      canvas.drawCircle(o, r, main);
    }
  }

  List<Offset> _positions(Size s) {
    final l = s.width * 0.27;
    final c = s.width * 0.50;
    final r = s.width * 0.73;
    final t = s.height * 0.27;
    final m = s.height * 0.50;
    final b = s.height * 0.73;
    return switch (value) {
      1 => [Offset(c, m)],
      2 => [Offset(l, t), Offset(r, b)],
      3 => [Offset(l, t), Offset(c, m), Offset(r, b)],
      4 => [Offset(l, t), Offset(r, t), Offset(l, b), Offset(r, b)],
      5 => [Offset(l, t), Offset(r, t), Offset(c, m), Offset(l, b), Offset(r, b)],
      6 => [Offset(l, t), Offset(r, t), Offset(l, m), Offset(r, m), Offset(l, b), Offset(r, b)],
      _ => [],
    };
  }

  @override
  bool shouldRepaint(_PipPainter o) => o.value != value;
}
