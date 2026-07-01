import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

/// Small popup that shows briefly after rolling the dice.
/// Auto-dismisses after 1.2 seconds.
class DiceResultModal {
  static void show(BuildContext context, int value, String playerName,
      Color playerColor) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => _DiceResultDialog(
        value: value,
        playerName: playerName,
        playerColor: playerColor,
      ),
    );
    // Auto-dismiss
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    });
  }
}

class _DiceResultDialog extends StatefulWidget {
  final int value;
  final String playerName;
  final Color playerColor;

  const _DiceResultDialog({
    required this.value,
    required this.playerName,
    required this.playerColor,
  });

  @override
  State<_DiceResultDialog> createState() => _DiceResultDialogState();
}

class _DiceResultDialogState extends State<_DiceResultDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final faces = ['', '⚀', '⚁', '⚂', '⚃', '⚄', '⚅'];
    final face = widget.value >= 1 && widget.value <= 6
        ? faces[widget.value]
        : '🎲';

    return FadeTransition(
      opacity: _fade,
      child: Center(
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            width: 200,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.appCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: widget.playerColor.withValues(alpha: 0.6), width: 2),
              boxShadow: [
                BoxShadow(
                  color: widget.playerColor.withValues(alpha: 0.4),
                  blurRadius: 32,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Player initial
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: widget.playerColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    widget.playerName.isNotEmpty
                        ? widget.playerName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(widget.playerName,
                  style: const TextStyle(color: AppColors.textSecondary,
                      fontSize: 12)),
              const SizedBox(height: 16),
              // Dice face unicode
              Text(face,
                  style: const TextStyle(fontSize: 72)),
              const SizedBox(height: 8),
              Text('Rolled ${widget.value}',
                  style: TextStyle(
                      color: widget.playerColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text('Moving ${widget.value} plots forward',
                  style: const TextStyle(
                      color: AppColors.textHint, fontSize: 11)),
            ]),
          ),
        ),
      ),
    );
  }
}