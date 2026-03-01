import 'package:flutter/material.dart';
import '../models/character.dart';
import '../models/combat.dart';
import '../game/matchstick_painter.dart';

class FighterWidget extends StatefulWidget {
  final GameCharacter character;
  final AnimationState animState;
  final bool facingRight;
  final VoidCallback? onAnimationComplete;

  const FighterWidget({
    super.key,
    required this.character,
    required this.animState,
    this.facingRight = true,
    this.onAnimationComplete,
  });

  @override
  State<FighterWidget> createState() => _FighterWidgetState();
}

class _FighterWidgetState extends State<FighterWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _getDuration(widget.animState),
    );
    _startAnimation();
  }

  @override
  void didUpdateWidget(FighterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animState != widget.animState) {
      _controller.duration = _getDuration(widget.animState);
      _startAnimation();
    }
  }

  Duration _getDuration(AnimationState state) {
    switch (state) {
      case AnimationState.idle:
        return const Duration(milliseconds: 1200);
      case AnimationState.punch:
        return const Duration(milliseconds: 400);
      case AnimationState.kick:
        return const Duration(milliseconds: 500);
      case AnimationState.jumpKick:
        return const Duration(milliseconds: 600);
      case AnimationState.suplex:
        return const Duration(milliseconds: 800);
      case AnimationState.hitReceived:
        return const Duration(milliseconds: 500);
      case AnimationState.ko:
        return const Duration(milliseconds: 1000);
      case AnimationState.victory:
        return const Duration(milliseconds: 1500);
    }
  }

  void _startAnimation() {
    _controller.reset();
    if (widget.animState == AnimationState.idle ||
        widget.animState == AnimationState.victory) {
      _controller.repeat();
    } else {
      _controller.forward().then((_) {
        widget.onAnimationComplete?.call();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(120, 160),
          painter: MatchstickPainter(
            characterId: widget.character.id,
            accentColor: widget.character.accentColor,
            animState: widget.animState,
            animProgress: _controller.value,
            facingRight: widget.facingRight,
          ),
        );
      },
    );
  }
}
