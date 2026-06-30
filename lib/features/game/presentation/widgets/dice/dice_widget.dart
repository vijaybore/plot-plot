import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

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
  int _display = 1;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _display = widget.value;
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _shake = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
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
      await Future.delayed(const Duration(milliseconds: 80));
      if (!mounted) return false;
      setState(() => _display = _rng.nextInt(6) + 1);
      return ++t < 8 && widget.isRolling;
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      AnimatedBuilder(
        animation: _shake,
        builder: (_, child) => Transform.translate(
          offset: Offset(sin(_shake.value * pi * 6) * 5, 0),
          child: child,
        ),
        child: GestureDetector(
          onTap: widget.canRoll && !widget.isRolling ? widget.onRoll : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFF0F0F0)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.canRoll ? AppColors.primary : Colors.black12,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary
                      .withValues(alpha: widget.canRoll ? 0.7 : 0.15),
                  blurRadius: widget.canRoll ? 24 : 6,
                  spreadRadius: widget.canRoll ? 4 : 0,
                ),
                const BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: CustomPaint(
                size: const Size(54, 54),
                painter: _DotPainter(_display),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
      if (widget.canRoll && !widget.isRolling)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  blurRadius: 10)
            ],
          ),
          child: const Text(
            'ROLL DICE',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 1.5),
          ),
        )
      else if (widget.isRolling)
        const Text('Rolling...',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11))
      else
        const Text('Wait...',
            style: TextStyle(color: AppColors.textHint, fontSize: 11)),
    ]);
  }
}

class _DotPainter extends CustomPainter {
  final int value;
  _DotPainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFFE74C3C);
    final r = size.width * 0.11;
    for (final o in _pos(size)) {
      canvas.drawCircle(o, r, p);
    }
  }

  List<Offset> _pos(Size s) {
    final l = s.width * 0.28, c = s.width * 0.5, r = s.width * 0.72;
    final t = s.height * 0.28, m = s.height * 0.5, b = s.height * 0.72;
    switch (value) {
      case 1:
        return [Offset(c, m)];
      case 2:
        return [Offset(l, t), Offset(r, b)];
      case 3:
        return [Offset(l, t), Offset(c, m), Offset(r, b)];
      case 4:
        return [Offset(l, t), Offset(r, t), Offset(l, b), Offset(r, b)];
      case 5:
        return [
          Offset(l, t),
          Offset(r, t),
          Offset(c, m),
          Offset(l, b),
          Offset(r, b)
        ];
      case 6:
        return [
          Offset(l, t),
          Offset(r, t),
          Offset(l, m),
          Offset(r, m),
          Offset(l, b),
          Offset(r, b)
        ];
      default:
        return [];
    }
  }

  @override
  bool shouldRepaint(_DotPainter o) => o.value != value;
}