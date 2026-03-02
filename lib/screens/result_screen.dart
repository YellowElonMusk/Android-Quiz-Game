import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/character.dart';
import '../services/audio_service.dart';
import '../widgets/confetti_widget.dart';
import '../widgets/fighter_widget.dart';
import '../models/combat.dart';

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
  late AnimationController _shakeController;
  late AnimationController _flashController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    if (!widget.playerWon) {
      _shakeController.forward();
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _flashController.dispose();
    super.dispose();
  }

  double get _accuracy => widget.questionsAnswered > 0
      ? widget.correctAnswers / widget.questionsAnswered
      : 0.0;

  @override
  Widget build(BuildContext context) {
    final winColor = const Color(0xFFFFFF00);
    final loseColor = Colors.red;
    final accentColor = widget.playerWon ? winColor : loseColor;

    return Scaffold(
      backgroundColor: const Color(0xFF04020C),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: widget.playerWon
                    ? [
                        const Color(0xFF0D1A00),
                        const Color(0xFF04020C),
                      ]
                    : [
                        const Color(0xFF1A0000),
                        const Color(0xFF04020C),
                      ],
              ),
            ),
          ),
          // Scanlines
          Positioned.fill(
            child: CustomPaint(painter: _ResultScanlinesPainter()),
          ),
          // Neon top border
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 3,
            child: Container(color: accentColor),
          ),
          // Confetti for victory
          if (widget.playerWon)
            const Positioned.fill(
              child: ConfettiWidget(isPlaying: true),
            ),
          // Content
          SafeArea(
            child: AnimatedBuilder(
              animation: _shakeController,
              builder: (context, child) {
                final shake = !widget.playerWon
                    ? ((_shakeController.value < 0.5)
                            ? _shakeController.value
                            : 1.0 - _shakeController.value) *
                        14
                    : 0.0;
                return Transform.translate(
                  offset: Offset(shake, 0),
                  child: child,
                );
              },
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Title
                      AnimatedBuilder(
                        animation: _flashController,
                        builder: (context, child) {
                          final glow = _flashController.value;
                          return Text(
                            widget.playerWon ? 'WINNER!' : 'K.O.!!',
                            style: GoogleFonts.pressStart2p(
                              textStyle: TextStyle(
                                fontSize: widget.playerWon ? 36 : 48,
                                color: accentColor,
                                shadows: [
                                  Shadow(
                                    color: accentColor
                                        .withValues(alpha: 0.4 + glow * 0.6),
                                    blurRadius: 20 + glow * 30,
                                  ),
                                  Shadow(
                                    color: accentColor
                                        .withValues(alpha: 0.3 + glow * 0.4),
                                    blurRadius: 50 + glow * 50,
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
                            border: Border.all(
                                color: const Color(0xFFFF8000), width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF8000)
                                    .withValues(alpha: 0.5),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                          child: Text(
                            'FLAWLESS VICTORY!',
                            style: GoogleFonts.pressStart2p(
                              textStyle: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFFFF8000),
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      // Character
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
                      const SizedBox(height: 8),
                      Text(
                        (widget.playerWon
                                ? widget.player.name
                                : widget.opponent.name)
                            .toUpperCase(),
                        style: GoogleFonts.pressStart2p(
                          textStyle:
                              TextStyle(color: accentColor, fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Rounds
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          border: Border.all(
                              color: Colors.white24, width: 2),
                        ),
                        child: Text(
                          'ROUNDS  ${widget.playerRoundWins} - ${widget.opponentRoundWins}',
                          style: GoogleFonts.pressStart2p(
                            textStyle: const TextStyle(
                                color: Colors.white70, fontSize: 11),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Stats card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.4),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.1),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _statRow('QUESTIONS',
                                '${widget.questionsAnswered}', accentColor),
                            _statRow('CORRECT',
                                '${widget.correctAnswers}', accentColor),
                            _statRow('ACCURACY',
                                '${(_accuracy * 100).toInt()}%', accentColor),
                            _statRow('BEST STREAK',
                                '${widget.bestStreak}X', accentColor),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildButton(
                            'REMATCH',
                            const Color(0xFF00FFFF),
                            () => Navigator.of(context).pop('rematch'),
                          ),
                          const SizedBox(width: 16),
                          _buildButton(
                            'MENU',
                            const Color(0xFFFF00FF),
                            () => Navigator.of(context)
                                .popUntil((route) => route.isFirst),
                          ),
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

  Widget _statRow(String label, String value, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.pressStart2p(
              textStyle:
                  const TextStyle(color: Colors.white54, fontSize: 8),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.pressStart2p(
              textStyle: TextStyle(color: accentColor, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String text, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: color, width: 3),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 12,
            ),
          ],
        ),
        child: Text(
          text,
          style: GoogleFonts.pressStart2p(
            textStyle: TextStyle(color: color, fontSize: 10, letterSpacing: 1),
          ),
        ),
      ),
    );
  }
}

class _ResultScanlinesPainter extends CustomPainter {
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
  bool shouldRepaint(_ResultScanlinesPainter old) => false;
}
