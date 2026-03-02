import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/character.dart';
import '../services/audio_service.dart';
import '../widgets/confetti_widget.dart';
import '../widgets/fighter_widget.dart';
import '../models/combat.dart';

const _amber = Color(0xFFFFB800);
const _orange = Color(0xFFFF4500);
const _screenGreen = Color(0xFF39FF14);
const _arcadeBg = Color(0xFF0A0500);

class ResultScreen extends StatefulWidget {
  final bool playerWon;
  final GameCharacter player;
  final GameCharacter opponent;
  final int questionsAnswered;
  final int correctAnswers;
  final int bestStreak;
  final int playerRoundWins;
  final int opponentRoundWins;
  final bool isPerfect;
  final AudioService audioService;

  const ResultScreen({
    super.key,
    required this.playerWon,
    required this.player,
    required this.opponent,
    required this.questionsAnswered,
    required this.correctAnswers,
    required this.bestStreak,
    required this.playerRoundWins,
    required this.opponentRoundWins,
    required this.isPerfect,
    required this.audioService,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _shakeCtrl;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    if (!widget.playerWon) _shakeCtrl.forward();
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  double get _accuracy => widget.questionsAnswered > 0
      ? widget.correctAnswers / widget.questionsAnswered
      : 0.0;

  @override
  Widget build(BuildContext context) {
    final accent = widget.playerWon ? _amber : _orange;

    return Scaffold(
      backgroundColor: _arcadeBg,
      body: Stack(
        children: [
          // Background gradient — warm win / warm-red loss
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: widget.playerWon
                    ? const [Color(0xFF1A0E00), _arcadeBg]
                    : const [Color(0xFF1A0200), _arcadeBg],
              ),
            ),
          ),
          // Scanlines
          Positioned.fill(child: CustomPaint(painter: _ScanlinesPainter())),
          // Top accent strip
          Positioned(
              top: 0, left: 0, right: 0, height: 3,
              child: Container(color: accent)),
          // Confetti
          if (widget.playerWon)
            const Positioned.fill(child: ConfettiWidget(isPlaying: true)),
          // Content
          SafeArea(
            child: AnimatedBuilder(
              animation: _shakeCtrl,
              builder: (context, child) {
                final shake = !widget.playerWon
                    ? ((_shakeCtrl.value < 0.5
                                ? _shakeCtrl.value
                                : 1.0 - _shakeCtrl.value) *
                            16)
                    : 0.0;
                return Transform.translate(
                    offset: Offset(shake, 0), child: child);
              },
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Title — pulsing drop-shadow
                      AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (context, _) {
                          final g = _pulseCtrl.value;
                          return Text(
                            widget.playerWon ? 'WINNER!' : 'K.O.!!',
                            style: GoogleFonts.blackOpsOne(
                              textStyle: TextStyle(
                                fontSize: widget.playerWon ? 44 : 56,
                                color: accent,
                                shadows: [
                                  Shadow(
                                    color: (widget.playerWon
                                            ? _orange
                                            : const Color(0xFF8B0000)),
                                    blurRadius: 0,
                                    offset: const Offset(4, 4),
                                  ),
                                  Shadow(
                                    color: Colors.black,
                                    blurRadius: 0,
                                    offset: const Offset(7, 7),
                                  ),
                                  Shadow(
                                    color: accent.withValues(
                                        alpha: 0.3 + g * 0.5),
                                    blurRadius: 24 + g * 24,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      if (widget.isPerfect && widget.playerWon) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            border: Border.all(color: _orange, width: 3),
                            boxShadow: [
                              BoxShadow(
                                  color: _orange.withValues(alpha: 0.4),
                                  blurRadius: 14)
                            ],
                          ),
                          child: Text(
                            'FLAWLESS VICTORY!',
                            style: GoogleFonts.blackOpsOne(
                              textStyle: const TextStyle(
                                fontSize: 13,
                                color: _orange,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 180,
                        child: FighterWidget(
                          character: widget.playerWon
                              ? widget.player
                              : widget.opponent,
                          animState: AnimationState.victory,
                          facingRight: true,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        (widget.playerWon
                                ? widget.player.name
                                : widget.opponent.name)
                            .toUpperCase(),
                        style: GoogleFonts.blackOpsOne(
                          textStyle: TextStyle(
                            color: accent,
                            fontSize: 16,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                  color: Colors.black,
                                  blurRadius: 0,
                                  offset: const Offset(2, 2)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Round score
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          border:
                              Border.all(color: Colors.white24, width: 2),
                        ),
                        child: Text(
                          'ROUNDS  ${widget.playerRoundWins} - ${widget.opponentRoundWins}',
                          style: GoogleFonts.vt323(
                            textStyle: const TextStyle(
                                color: Colors.white70, fontSize: 24),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Stats
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          border: Border.all(
                              color: accent.withValues(alpha: 0.35),
                              width: 2),
                        ),
                        child: Column(
                          children: [
                            _statRow('QUESTIONS',
                                '${widget.questionsAnswered}', accent),
                            _statRow('CORRECT',
                                '${widget.correctAnswers}', accent),
                            _statRow('ACCURACY',
                                '${(_accuracy * 100).toInt()}%', accent),
                            _statRow('BEST STREAK',
                                '${widget.bestStreak}X', accent),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _btn('REMATCH', _screenGreen,
                              () => Navigator.of(context).pop('rematch')),
                          const SizedBox(width: 14),
                          _btn('MENU', _orange,
                              () => Navigator.of(context)
                                  .popUntil((r) => r.isFirst)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.vt323(
                  textStyle:
                      const TextStyle(color: Colors.white54, fontSize: 20))),
          Text(value,
              style: GoogleFonts.vt323(
                  textStyle: TextStyle(color: accent, fontSize: 24))),
        ],
      ),
    );
  }

  Widget _btn(String text, Color accent, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: accent, width: 3),
          boxShadow: [
            BoxShadow(
                color: accent.withValues(alpha: 0.35), blurRadius: 12)
          ],
        ),
        child: Text(text,
            style: GoogleFonts.blackOpsOne(
              textStyle: TextStyle(
                  color: accent, fontSize: 12, letterSpacing: 1),
            )),
      ),
    );
  }
}

class _ScanlinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.10)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_ScanlinesPainter old) => false;
}
