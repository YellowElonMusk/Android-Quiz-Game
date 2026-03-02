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
        // Boxing footwork: step toward/away from opponent with weight-shift bounce
        final t = animProgress;
        final lateralStep = sin(t * 2 * pi) * 10;
        // Bounce twice per lateral cycle (once per step)
        final verticalBounce = -sin(t * 4 * pi).abs() * 6;
        canvas.translate(lateralStep * dir, verticalBounce);
        // Slight forward lean on step toward opponent
        canvas.rotate(sin(t * 2 * pi) * 0.07 * dir);
      case AnimationState.punch:
        // Dramatic lunge forward with big lean
        final extend = sin(animProgress * pi);
        canvas.translate(dir * extend * 18, -extend * 5);
        canvas.rotate(extend * 0.28 * dir);
      case AnimationState.kick:
        final extend = sin(animProgress * pi);
        canvas.translate(dir * extend * 10, -extend * 3);
        canvas.rotate(extend * 0.22 * dir);
      case AnimationState.jumpKick:
        // Big aerial jump
        final jump = -sin(animProgress * pi) * 65;
        final lean = sin(animProgress * pi) * 0.35 * dir;
        canvas.translate(dir * sin(animProgress * pi) * 25, jump);
        canvas.rotate(lean);
      case AnimationState.suplex:
        final grab = sin(animProgress * pi);
        canvas.translate(dir * grab * 30, -grab * 30);
        canvas.rotate(grab * 0.45 * dir);
      case AnimationState.hitReceived:
        // Dramatic stagger with rapid wobble
        final stagger = sin(animProgress * pi) * 22;
        final wobble = sin(animProgress * pi * 4) * 5;
        canvas.translate(-dir * stagger + wobble, -sin(animProgress * pi) * 8);
        canvas.rotate(-sin(animProgress * pi) * 0.28 * dir);
      case AnimationState.ko:
        final fall = animProgress;
        canvas.rotate(fall * (pi / 2) * dir);
        canvas.translate(dir * fall * 18, fall * 35);
      case AnimationState.victory:
        // Fast big bouncy celebration
        final bounce = sin(animProgress * 6 * pi) * 14;
        final lean = sin(animProgress * 3 * pi) * 0.10;
        canvas.translate(0, bounce);
        canvas.rotate(lean);
    }

    _drawBody(canvas, size, dir);
    canvas.restore();
  }

  void _drawBody(Canvas canvas, Size size, double dir) {
    final bodyPaint = Paint()
      ..color = const Color(0xFFF0E0B0) // warm parchment — visible on dark bg
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final headPaint = Paint()
      ..color = const Color(0xFFB89060) // warm tan outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final headFillPaint = Paint()
      ..color = const Color(0xFFF5E6C8) // warm skin fill
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
      ..color = const Color(0xFF2A1A00) // dark brown
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

    // Gloves / accent on hands — slightly bigger
    final glovePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    final handPositions = _getHandPositions(scale, dir);
    for (final pos in handPositions) {
      canvas.drawCircle(pos, 5 * scale, glovePaint);
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
          Rect.fromCircle(
              center: headCenter + Offset(0, -4 * scale), radius: headRadius),
          -pi * 0.9,
          pi * 0.8,
        );
        canvas.drawPath(
            tp, hairPaint..style = PaintingStyle.stroke..strokeWidth = 5 * scale);
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
        // Afro puffs
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
      case AnimationState.idle:
        // Boxing guard: front arm extended, back arm raised near face
        final t = animProgress;
        final frontBob = sin(t * 4 * pi) * 8;
        final backBob = cos(t * 4 * pi) * 6;
        // Front arm in extended guard (toward opponent)
        canvas.drawLine(
          Offset(0, -90 * scale),
          Offset(dir * 22 * scale, (-72 + frontBob) * scale),
          paint,
        );
        // Back arm raised near face
        canvas.drawLine(
          Offset(0, -90 * scale),
          Offset(-dir * 8 * scale, (-90 + backBob) * scale),
          paint,
        );

      case AnimationState.punch:
        // Big lunging punch
        final extend = sin(animProgress * pi);
        canvas.drawLine(
          Offset(0, -90 * scale),
          Offset(dir * (18 + extend * 42) * scale, (-82 + extend * 5) * scale),
          paint,
        );
        // Guard arm pulled back
        canvas.drawLine(
          Offset(0, -90 * scale),
          Offset(-dir * 16 * scale, -72 * scale),
          paint,
        );

      case AnimationState.victory:
        // Both arms raised high, waving
        final wave = sin(animProgress * 6 * pi) * 6;
        canvas.drawLine(
          Offset(0, -90 * scale),
          Offset(-22 * scale, (-118 + wave) * scale),
          paint,
        );
        canvas.drawLine(
          Offset(0, -90 * scale),
          Offset(22 * scale, (-118 - wave) * scale),
          paint,
        );

      case AnimationState.hitReceived:
        // Arms flung back dramatically
        final stagger = sin(animProgress * pi);
        canvas.drawLine(
          Offset(0, -90 * scale),
          Offset(-dir * 30 * scale, (-68 + stagger * 12) * scale),
          paint,
        );
        canvas.drawLine(
          Offset(0, -90 * scale),
          Offset(-dir * 16 * scale, (-60 + stagger * 10) * scale),
          paint,
        );

      case AnimationState.suplex:
        // Both arms extended forward for grab
        final grab = sin(animProgress * pi);
        canvas.drawLine(
          Offset(0, -90 * scale),
          Offset(dir * (15 + grab * 30) * scale, -85 * scale),
          paint,
        );
        canvas.drawLine(
          Offset(0, -90 * scale),
          Offset(dir * (10 + grab * 25) * scale, -75 * scale),
          paint,
        );

      case AnimationState.kick:
      case AnimationState.jumpKick:
        // Guard position during kicks
        canvas.drawLine(
          Offset(0, -90 * scale),
          Offset(dir * 14 * scale, -82 * scale),
          paint,
        );
        canvas.drawLine(
          Offset(0, -90 * scale),
          Offset(-dir * 14 * scale, -80 * scale),
          paint,
        );

      default:
        // KO / default — arms limp
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
      case AnimationState.idle:
        // Boxing stance with alternating weight shift
        final t = animProgress;
        final weightBob = sin(t * 2 * pi) * 4;
        canvas.drawLine(
          Offset(0, -50 * scale),
          Offset(dir * (15 + weightBob) * scale, -8 * scale),
          paint,
        );
        canvas.drawLine(
          Offset(0, -50 * scale),
          Offset(-dir * (12 - weightBob) * scale, -5 * scale),
          paint,
        );

      case AnimationState.kick:
        // One leg extended in big kick
        final extend = sin(animProgress * pi);
        canvas.drawLine(
          Offset(0, -50 * scale),
          Offset(dir * (10 + extend * 45) * scale, (-30 + extend * 10) * scale),
          paint,
        );
        canvas.drawLine(
          Offset(0, -50 * scale),
          Offset(-dir * 14 * scale, -10 * scale),
          paint,
        );

      case AnimationState.jumpKick:
        // Both legs extended in aerial kick
        final extend = sin(animProgress * pi);
        canvas.drawLine(
          Offset(0, -50 * scale),
          Offset(dir * (15 + extend * 45) * scale, -38 * scale),
          paint,
        );
        canvas.drawLine(
          Offset(0, -50 * scale),
          Offset(-dir * (12 + extend * 15) * scale, -35 * scale),
          paint,
        );

      case AnimationState.ko:
        // Collapsed legs
        canvas.drawLine(
          Offset(0, -50 * scale),
          Offset(-20 * scale, 0),
          paint,
        );
        canvas.drawLine(
          Offset(0, -50 * scale),
          Offset(18 * scale, -8 * scale),
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
      case AnimationState.idle:
        final t = animProgress;
        final frontBob = sin(t * 4 * pi) * 8;
        final backBob = cos(t * 4 * pi) * 6;
        return [
          Offset(dir * 22 * scale, (-72 + frontBob) * scale),
          Offset(-dir * 8 * scale, (-90 + backBob) * scale),
        ];
      case AnimationState.punch:
        final extend = sin(animProgress * pi);
        return [
          Offset(dir * (18 + extend * 42) * scale, (-82 + extend * 5) * scale),
          Offset(-dir * 16 * scale, -72 * scale),
        ];
      case AnimationState.victory:
        final wave = sin(animProgress * 6 * pi) * 6;
        return [
          Offset(-22 * scale, (-118 + wave) * scale),
          Offset(22 * scale, (-118 - wave) * scale),
        ];
      case AnimationState.hitReceived:
        final stagger = sin(animProgress * pi);
        return [
          Offset(-dir * 30 * scale, (-68 + stagger * 12) * scale),
          Offset(-dir * 16 * scale, (-60 + stagger * 10) * scale),
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
