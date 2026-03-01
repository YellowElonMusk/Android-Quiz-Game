import 'dart:math';
import 'package:flutter/material.dart';
import '../models/character.dart';
import '../models/combat.dart';

/// Draws matchstick-style fighters using Canvas primitives.
/// Each character is distinguished by hair style and accent color.
class MatchstickPainter extends CustomPainter {
  final CharacterId characterId;
  final Color accentColor;
  final AnimationState animState;
  final double animProgress; // 0.0 -> 1.0
  final bool facingRight;

  MatchstickPainter({
    required this.characterId,
    required this.accentColor,
    required this.animState,
    required this.animProgress,
    this.facingRight = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final dir = facingRight ? 1.0 : -1.0;
    final cx = size.width / 2;
    final cy = size.height;

    canvas.save();
    canvas.translate(cx, cy);

    // Apply animation transforms
    switch (animState) {
      case AnimationState.idle:
        final bounce = sin(animProgress * 2 * pi) * 3;
        canvas.translate(0, bounce);
      case AnimationState.punch:
        // Lean forward
        final lean = sin(animProgress * pi) * 0.15 * dir;
        canvas.rotate(lean);
      case AnimationState.kick:
        final lean = sin(animProgress * pi) * 0.1 * dir;
        canvas.rotate(lean);
      case AnimationState.jumpKick:
        final jump = -sin(animProgress * pi) * 40;
        final lean = sin(animProgress * pi) * 0.2 * dir;
        canvas.translate(dir * sin(animProgress * pi) * 15, jump);
        canvas.rotate(lean);
      case AnimationState.suplex:
        final grab = sin(animProgress * pi);
        canvas.translate(dir * grab * 20, -grab * 20);
        canvas.rotate(grab * 0.3 * dir);
      case AnimationState.hitReceived:
        final stagger = sin(animProgress * pi) * 15;
        canvas.translate(-dir * stagger, 0);
        canvas.rotate(-sin(animProgress * pi) * 0.15 * dir);
      case AnimationState.ko:
        final fall = animProgress;
        canvas.rotate(fall * (pi / 2) * dir);
        canvas.translate(0, fall * 20);
      case AnimationState.victory:
        final bounce = sin(animProgress * 4 * pi) * 8;
        canvas.translate(0, bounce);
    }

    _drawBody(canvas, size, dir);
    canvas.restore();
  }

  void _drawBody(Canvas canvas, Size size, double dir) {
    final bodyPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final headPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final headFillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final hairPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    final scale = size.height / 160;

    // Head
    final headCenter = Offset(0, -120 * scale);
    final headRadius = 14.0 * scale;
    canvas.drawCircle(headCenter, headRadius, headFillPaint);
    canvas.drawCircle(headCenter, headRadius, headPaint);

    // Eyes - small dots
    final eyePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      headCenter + Offset(dir * 4 * scale, -2 * scale),
      2.0 * scale,
      eyePaint,
    );
    canvas.drawCircle(
      headCenter + Offset(dir * 10 * scale, -2 * scale),
      2.0 * scale,
      eyePaint,
    );

    // Hair based on character
    _drawHair(canvas, headCenter, headRadius, scale, dir, hairPaint);

    // Neck
    canvas.drawLine(
      Offset(0, -106 * scale),
      Offset(0, -98 * scale),
      bodyPaint,
    );

    // Torso
    canvas.drawLine(
      Offset(0, -98 * scale),
      Offset(0, -50 * scale),
      bodyPaint,
    );

    // Arms
    _drawArms(canvas, scale, dir, bodyPaint);

    // Legs
    _drawLegs(canvas, scale, dir, bodyPaint);

    // Gloves / accent on hands
    final glovePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    final handPositions = _getHandPositions(scale, dir);
    for (final pos in handPositions) {
      canvas.drawCircle(pos, 4 * scale, glovePaint);
    }
  }

  void _drawHair(Canvas canvas, Offset headCenter, double headRadius,
      double scale, double dir, Paint hairPaint) {
    switch (characterId) {
      case CharacterId.ryo:
        // Pompadour - a swooping arc on top
        final path = Path();
        path.moveTo(headCenter.dx - 12 * scale, headCenter.dy - 8 * scale);
        path.quadraticBezierTo(
          headCenter.dx + dir * 5 * scale,
          headCenter.dy - 32 * scale,
          headCenter.dx + 14 * scale,
          headCenter.dy - 6 * scale,
        );
        path.quadraticBezierTo(
          headCenter.dx + 2 * scale,
          headCenter.dy - 18 * scale,
          headCenter.dx - 12 * scale,
          headCenter.dy - 8 * scale,
        );
        canvas.drawPath(path, hairPaint);

      case CharacterId.yuki:
        // Double ponytail
        // Left ponytail
        final lp = Path();
        lp.moveTo(headCenter.dx - 10 * scale, headCenter.dy - 6 * scale);
        lp.quadraticBezierTo(
          headCenter.dx - 22 * scale,
          headCenter.dy - 16 * scale,
          headCenter.dx - 18 * scale,
          headCenter.dy + 8 * scale,
        );
        lp.quadraticBezierTo(
          headCenter.dx - 14 * scale,
          headCenter.dy - 4 * scale,
          headCenter.dx - 10 * scale,
          headCenter.dy - 6 * scale,
        );
        canvas.drawPath(lp, hairPaint);

        // Right ponytail
        final rp = Path();
        rp.moveTo(headCenter.dx + 10 * scale, headCenter.dy - 6 * scale);
        rp.quadraticBezierTo(
          headCenter.dx + 22 * scale,
          headCenter.dy - 16 * scale,
          headCenter.dx + 18 * scale,
          headCenter.dy + 8 * scale,
        );
        rp.quadraticBezierTo(
          headCenter.dx + 14 * scale,
          headCenter.dy - 4 * scale,
          headCenter.dx + 10 * scale,
          headCenter.dy - 6 * scale,
        );
        canvas.drawPath(rp, hairPaint);

        // Top hair
        final tp = Path();
        tp.addArc(
          Rect.fromCircle(center: headCenter + Offset(0, -4 * scale), radius: headRadius),
          -pi * 0.9,
          pi * 0.8,
        );
        canvas.drawPath(tp, hairPaint..style = PaintingStyle.stroke..strokeWidth = 5 * scale);
        hairPaint.style = PaintingStyle.fill;

      case CharacterId.tank:
        // Mohawk - sharp spikes on top
        final path = Path();
        final baseY = headCenter.dy - headRadius;
        path.moveTo(headCenter.dx - 4 * scale, baseY);
        path.lineTo(headCenter.dx - 2 * scale, baseY - 18 * scale);
        path.lineTo(headCenter.dx + 2 * scale, baseY);
        path.lineTo(headCenter.dx + 4 * scale, baseY - 22 * scale);
        path.lineTo(headCenter.dx + 8 * scale, baseY);
        path.lineTo(headCenter.dx + 6 * scale, baseY - 16 * scale);
        path.lineTo(headCenter.dx + 10 * scale, baseY);
        path.close();
        canvas.drawPath(path, hairPaint);

      case CharacterId.iris:
        // Afro puffs - two circles on each side of head
        canvas.drawCircle(
          headCenter + Offset(-14 * scale, -10 * scale),
          10 * scale,
          hairPaint,
        );
        canvas.drawCircle(
          headCenter + Offset(14 * scale, -10 * scale),
          10 * scale,
          hairPaint,
        );
    }
  }

  void _drawArms(Canvas canvas, double scale, double dir, Paint paint) {
    switch (animState) {
      case AnimationState.punch:
        // Extended punch arm
        final extend = sin(animProgress * pi);
        canvas.drawLine(
          Offset(0, -90 * scale),
          Offset(dir * (20 + extend * 35) * scale, -80 * scale),
          paint,
        );
        // Back arm
        canvas.drawLine(
          Offset(0, -90 * scale),
          Offset(-dir * 18 * scale, -70 * scale),
          paint,
        );

      case AnimationState.victory:
        // Both arms raised
        canvas.drawLine(
          Offset(0, -90 * scale),
          Offset(-20 * scale, -115 * scale),
          paint,
        );
        canvas.drawLine(
          Offset(0, -90 * scale),
          Offset(20 * scale, -115 * scale),
          paint,
        );

      case AnimationState.hitReceived:
        // Arms flail back
        canvas.drawLine(
          Offset(0, -90 * scale),
          Offset(-dir * 25 * scale, -75 * scale),
          paint,
        );
        canvas.drawLine(
          Offset(0, -90 * scale),
          Offset(-dir * 15 * scale, -65 * scale),
          paint,
        );

      case AnimationState.suplex:
        // Both arms extended forward for grab
        final grab = sin(animProgress * pi);
        canvas.drawLine(
          Offset(0, -90 * scale),
          Offset(dir * (15 + grab * 25) * scale, -85 * scale),
          paint,
        );
        canvas.drawLine(
          Offset(0, -90 * scale),
          Offset(dir * (10 + grab * 20) * scale, -75 * scale),
          paint,
        );

      case AnimationState.kick:
      case AnimationState.jumpKick:
        // Guard position
        canvas.drawLine(
          Offset(0, -90 * scale),
          Offset(dir * 15 * scale, -80 * scale),
          paint,
        );
        canvas.drawLine(
          Offset(0, -90 * scale),
          Offset(-dir * 12 * scale, -78 * scale),
          paint,
        );

      default:
        // Idle / KO default arms
        canvas.drawLine(
          Offset(0, -90 * scale),
          Offset(-20 * scale, -65 * scale),
          paint,
        );
        canvas.drawLine(
          Offset(0, -90 * scale),
          Offset(20 * scale, -65 * scale),
          paint,
        );
    }
  }

  void _drawLegs(Canvas canvas, double scale, double dir, Paint paint) {
    switch (animState) {
      case AnimationState.kick:
        // One leg extended in kick
        final extend = sin(animProgress * pi);
        canvas.drawLine(
          Offset(0, -50 * scale),
          Offset(dir * (10 + extend * 35) * scale, -30 * scale),
          paint,
        );
        canvas.drawLine(
          Offset(0, -50 * scale),
          Offset(-dir * 12 * scale, -10 * scale),
          paint,
        );

      case AnimationState.jumpKick:
        // Both legs extended, one forward
        final extend = sin(animProgress * pi);
        canvas.drawLine(
          Offset(0, -50 * scale),
          Offset(dir * (15 + extend * 35) * scale, -40 * scale),
          paint,
        );
        canvas.drawLine(
          Offset(0, -50 * scale),
          Offset(-dir * (10 + extend * 10) * scale, -35 * scale),
          paint,
        );

      default:
        // Standing legs
        canvas.drawLine(
          Offset(0, -50 * scale),
          Offset(-12 * scale, -5 * scale),
          paint,
        );
        canvas.drawLine(
          Offset(0, -50 * scale),
          Offset(12 * scale, -5 * scale),
          paint,
        );
    }
  }

  List<Offset> _getHandPositions(double scale, double dir) {
    switch (animState) {
      case AnimationState.punch:
        final extend = sin(animProgress * pi);
        return [
          Offset(dir * (20 + extend * 35) * scale, -80 * scale),
          Offset(-dir * 18 * scale, -70 * scale),
        ];
      case AnimationState.victory:
        return [
          Offset(-20 * scale, -115 * scale),
          Offset(20 * scale, -115 * scale),
        ];
      default:
        return [
          Offset(-20 * scale, -65 * scale),
          Offset(20 * scale, -65 * scale),
        ];
    }
  }

  @override
  bool shouldRepaint(MatchstickPainter oldDelegate) =>
      oldDelegate.animState != animState ||
      oldDelegate.animProgress != animProgress ||
      oldDelegate.characterId != characterId;
}
