import 'dart:math';
import 'package:flutter/material.dart';

class ConfettiWidget extends StatefulWidget {
  final bool isPlaying;

  const ConfettiWidget({super.key, required this.isPlaying});

  @override
  State<ConfettiWidget> createState() => _ConfettiWidgetState();
}

class _ConfettiWidgetState extends State<ConfettiWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_ConfettiPiece> _pieces;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _pieces = List.generate(60, (_) => _ConfettiPiece(_random));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    if (widget.isPlaying) _controller.repeat();
  }

  @override
  void didUpdateWidget(ConfettiWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isPlaying && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isPlaying) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_pieces, _controller.value),
        );
      },
    );
  }
}

class _ConfettiPiece {
  final double x; // 0-1 horizontal position
  final double speed; // fall speed multiplier
  final double size;
  final Color color;
  final double rotation;
  final double wobble;

  _ConfettiPiece(Random r)
      : x = r.nextDouble(),
        speed = 0.3 + r.nextDouble() * 0.7,
        size = 4 + r.nextDouble() * 6,
        color = [
          Colors.red,
          Colors.yellow,
          Colors.blue,
          Colors.green,
          Colors.purple,
          Colors.orange,
        ][r.nextInt(6)],
        rotation = r.nextDouble() * pi * 2,
        wobble = r.nextDouble() * 20;
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiPiece> pieces;
  final double progress;

  _ConfettiPainter(this.pieces, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final piece in pieces) {
      final y = (progress * piece.speed * 1.5 % 1.0) * size.height;
      final x = piece.x * size.width +
          sin(progress * pi * 4 + piece.rotation) * piece.wobble;
      final paint = Paint()..color = piece.color;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * pi * 2 * piece.speed + piece.rotation);
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset.zero, width: piece.size, height: piece.size * 0.6),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
