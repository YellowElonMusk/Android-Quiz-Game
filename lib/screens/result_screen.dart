import 'package:flutter/material.dart';
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
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    if (!widget.playerWon) {
      _shakeController.forward();
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  double get _accuracy => widget.questionsAnswered > 0
      ? widget.correctAnswers / widget.questionsAnswered
      : 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: widget.playerWon
                    ? [const Color(0xFF1B4332), const Color(0xFF081C15)]
                    : [const Color(0xFF641220), const Color(0xFF370617)],
              ),
            ),
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
                        10
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
                      Text(
                        widget.playerWon ? 'WINNER!' : 'K.O.',
                        style: TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.w900,
                          color: widget.playerWon
                              ? Colors.yellowAccent
                              : Colors.redAccent,
                          letterSpacing: 6,
                          shadows: [
                            Shadow(
                              color: (widget.playerWon
                                      ? Colors.yellow
                                      : Colors.red)
                                  .withValues(alpha: 0.5),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                      ),
                      if (widget.isPerfect && widget.playerWon) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.amber, width: 2),
                          ),
                          child: const Text(
                            'FLAWLESS',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                              letterSpacing: 4,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      // Character
                      SizedBox(
                        height: 180,
                        child: FighterWidget(
                          character:
                              widget.playerWon ? widget.player : widget.opponent,
                          animState: AnimationState.victory,
                          facingRight: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.playerWon
                            ? widget.player.name
                            : widget.opponent.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Score
                      Text(
                        'Rounds: ${widget.playerRoundWins} - ${widget.opponentRoundWins}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Stats card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: Colors.white12, width: 1),
                        ),
                        child: Column(
                          children: [
                            _statRow('Questions Answered',
                                '${widget.questionsAnswered}'),
                            _statRow('Correct Answers',
                                '${widget.correctAnswers}'),
                            _statRow(
                                'Accuracy', '${(_accuracy * 100).toInt()}%'),
                            _statRow('Best Streak', '${widget.bestStreak}x'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildButton(
                            'REMATCH',
                            Colors.blueAccent,
                            () => Navigator.of(context).pop('rematch'),
                          ),
                          const SizedBox(width: 16),
                          _buildButton(
                            'MENU',
                            Colors.grey[700]!,
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

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
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
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
