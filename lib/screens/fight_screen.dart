import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/character.dart';
import '../models/combat.dart';
import '../models/question.dart';
import '../services/question_service.dart';
import '../services/audio_service.dart';
import '../widgets/fighter_widget.dart';
import '../widgets/hp_bar.dart';
import '../widgets/question_panel.dart';
import 'result_screen.dart';

class FightScreen extends StatefulWidget {
  final GameCharacter player;
  final GameCharacter opponent;
  final QuizCategory category;
  final Difficulty difficulty;
  final QuestionService questionService;
  final AudioService audioService;

  const FightScreen({
    super.key,
    required this.player,
    required this.opponent,
    required this.category,
    required this.difficulty,
    required this.questionService,
    required this.audioService,
  });

  @override
  State<FightScreen> createState() => _FightScreenState();
}

class _FightScreenState extends State<FightScreen> {
  late CombatState _combat;
  late List<Question> _questions;
  int _questionIndex = 0;
  final Random _random = Random();

  AnimationState _playerAnim = AnimationState.idle;
  AnimationState _opponentAnim = AnimationState.idle;

  bool _isAnimating = false;
  bool _showRoundBanner = true;
  bool _isPaused = false;
  String? _attackLabel;
  String? _damageLabel;

  // Grawlix state
  String? _playerGrawlix;
  String? _opponentGrawlix;

  static const _grawlixOptions = [
    '#\$@!',
    '@&#\$?!',
    '%#@\$!',
    '\$#@&!',
    '!@#\$%',
    '#\$%&!',
    '@#!\$?',
    '&%#@!',
  ];

  @override
  void initState() {
    super.initState();
    _combat = CombatState();
    _questions = widget.questionService.getQuestionsForMatch(widget.category);
    _showRoundStart();
  }

  void _showRoundStart() {
    setState(() {
      _showRoundBanner = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showRoundBanner = false;
        });
      }
    });
  }

  AttackType _randomAttack() {
    final roll = _random.nextInt(3);
    return [AttackType.punch, AttackType.kick, AttackType.jumpKick][roll];
  }

  AnimationState _attackToAnim(AttackType attack) {
    switch (attack) {
      case AttackType.punch:
        return AnimationState.punch;
      case AttackType.kick:
        return AnimationState.kick;
      case AttackType.jumpKick:
        return AnimationState.jumpKick;
      case AttackType.suplex:
        return AnimationState.suplex;
    }
  }

  void _onAnswer(int selectedIndex) {
    if (_isPaused || _isAnimating || _questionIndex >= _questions.length) return;

    final question = _questions[_questionIndex];
    final isCorrect =
        selectedIndex >= 0 && selectedIndex == question.correctIndex;

    _combat.questionsAnswered++;

    setState(() {
      _isAnimating = true;
      _playerGrawlix = null;
      _opponentGrawlix = null;
    });

    if (isCorrect) {
      _combat.correctAnswers++;
      _combat.playerStreak++;
      if (_combat.playerStreak > _combat.bestStreak) {
        _combat.bestStreak = _combat.playerStreak;
      }

      AttackType attack;
      if (_combat.playerStreak >= 3 && _combat.playerStreak % 3 == 0) {
        attack = AttackType.suplex;
      } else {
        attack = _randomAttack();
      }

      widget.audioService.playCorrect();

      setState(() {
        _playerAnim = _attackToAnim(attack);
        _attackLabel = attack.displayName;
        _damageLabel = '-${attack.damage}';
      });

      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        _playAttackSound(attack);
        setState(() {
          _opponentAnim = AnimationState.hitReceived;
          _combat.opponentHp =
              (_combat.opponentHp - attack.damage).clamp(0, 500);
          _opponentGrawlix = _maybeGrawlix();
          _playerGrawlix = null;
        });
      });

      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        _afterTurn();
      });
    } else {
      _combat.playerStreak = 0;
      widget.audioService.playWrong();

      final attack = _randomAttack();
      setState(() {
        _opponentAnim = _attackToAnim(attack);
        _attackLabel = '${attack.displayName}!';
        _damageLabel = '-${attack.damage}';
      });

      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        _playAttackSound(attack);
        setState(() {
          _playerAnim = AnimationState.hitReceived;
          _combat.playerHp =
              (_combat.playerHp - attack.damage).clamp(0, 500);
          _playerGrawlix = _maybeGrawlix();
          _opponentGrawlix = null;
        });
      });

      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        _afterTurn();
      });
    }
  }

  String? _maybeGrawlix() {
    if (_random.nextBool()) {
      return _grawlixOptions[_random.nextInt(_grawlixOptions.length)];
    }
    return null;
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void _quitToMenu() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _playAttackSound(AttackType attack) {
    switch (attack) {
      case AttackType.punch:
        widget.audioService.playPunch();
      case AttackType.kick:
        widget.audioService.playKick();
      case AttackType.jumpKick:
        widget.audioService.playKick();
      case AttackType.suplex:
        widget.audioService.playSuplex();
    }
  }

  void _afterTurn() {
    if (!mounted) return;

    if (_combat.isRoundOver) {
      _handleRoundEnd();
      return;
    }

    setState(() {
      _playerAnim = AnimationState.idle;
      _opponentAnim = AnimationState.idle;
      _isAnimating = false;
      _attackLabel = null;
      _damageLabel = null;
      _questionIndex++;
    });

    if (_questionIndex >= _questions.length) {
      _questions = widget.questionService.getQuestionsForMatch(widget.category);
      _questionIndex = 0;
    }
  }

  void _handleRoundEnd() {
    if (_combat.playerWonRound) {
      _combat.playerRoundWins++;
      widget.audioService.playVictory();
      setState(() {
        _playerAnim = AnimationState.victory;
        _opponentAnim = AnimationState.ko;
      });
    } else {
      _combat.opponentRoundWins++;
      widget.audioService.playKo();
      setState(() {
        _playerAnim = AnimationState.ko;
        _opponentAnim = AnimationState.victory;
      });
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      if (_combat.isMatchOver) {
        _goToResult();
      } else {
        _combat.resetRound();
        setState(() {
          _playerAnim = AnimationState.idle;
          _opponentAnim = AnimationState.idle;
          _isAnimating = false;
          _attackLabel = null;
          _damageLabel = null;
          _playerGrawlix = null;
          _opponentGrawlix = null;
        });
        _showRoundStart();
      }
    });
  }

  void _goToResult() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          playerWon: _combat.playerWonMatch,
          player: widget.player,
          opponent: widget.opponent,
          questionsAnswered: _combat.questionsAnswered,
          correctAnswers: _combat.correctAnswers,
          bestStreak: _combat.bestStreak,
          playerRoundWins: _combat.playerRoundWins,
          opponentRoundWins: _combat.opponentRoundWins,
          isPerfect: _combat.accuracy == 1.0,
          audioService: widget.audioService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04020C),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top info bar — no pause button, just HP bars and round info
                _buildTopBar(),
                // Fight arena
                Expanded(
                  flex: 55,
                  child: _buildArena(),
                ),
                // Question panel
                if (!_showRoundBanner &&
                    !_combat.isRoundOver &&
                    _questionIndex < _questions.length)
                  Expanded(
                    flex: 45,
                    child: QuestionPanel(
                      question: _questions[_questionIndex],
                      onAnswer: _onAnswer,
                      difficulty: widget.difficulty,
                      paused: _isPaused,
                    ),
                  ),
              ],
            ),
            // Pause overlay
            if (_isPaused) _buildPauseOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildPauseOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.92),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'GAME\nPAUSED',
              textAlign: TextAlign.center,
              style: GoogleFonts.pressStart2p(
                textStyle: const TextStyle(
                  color: Color(0xFFFFFF00),
                  fontSize: 22,
                  letterSpacing: 4,
                  height: 1.6,
                  shadows: [
                    Shadow(
                      color: Color(0xFFFFFF00),
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            _pauseMenuButton('RESUME', const Color(0xFF00FF00), Colors.black, () {
              _togglePause();
            }),
            const SizedBox(height: 16),
            // Settings
            Container(
              width: 300,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(
                    color: const Color(0xFF00FFFF).withValues(alpha: 0.4),
                    width: 2),
              ),
              child: Column(
                children: [
                  Text(
                    'SETTINGS',
                    style: GoogleFonts.pressStart2p(
                      textStyle: const TextStyle(
                        color: Color(0xFF00FFFF),
                        fontSize: 10,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  StatefulBuilder(
                    builder: (context, setInnerState) {
                      return Column(
                        children: [
                          _arcadeSwitchTile(
                            'MUSIC',
                            widget.audioService.musicEnabled,
                            (v) => setInnerState(
                                () => widget.audioService.toggleMusic()),
                          ),
                          _arcadeSwitchTile(
                            'SFX',
                            widget.audioService.sfxEnabled,
                            (v) => setInnerState(
                                () => widget.audioService.toggleSfx()),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _pauseMenuButton(
                'QUIT TO MENU', Colors.red, Colors.white, _quitToMenu),
          ],
        ),
      ),
    );
  }

  Widget _arcadeSwitchTile(
      String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.pressStart2p(
              textStyle: const TextStyle(color: Colors.white, fontSize: 9),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFFFFF00),
            activeTrackColor: const Color(0xFFFFFF00).withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }

  Widget _pauseMenuButton(
      String text, Color bg, Color textColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: bg, width: 3),
          boxShadow: [
            BoxShadow(
              color: bg.withValues(alpha: 0.5),
              blurRadius: 12,
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.pressStart2p(
              textStyle: TextStyle(
                color: bg,
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const BoxDecoration(
        color: Color(0xFF04020C),
        border: Border(
          bottom: BorderSide(color: Color(0xFF00FFFF), width: 2),
        ),
      ),
      child: Row(
        children: [
          HpBar(
            percent: _combat.playerHpPercent,
            color: widget.player.accentColor,
            label: widget.player.name,
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'RND ${_combat.currentRound}/3',
                  style: GoogleFonts.pressStart2p(
                    textStyle: const TextStyle(
                      color: Color(0xFF00FFFF),
                      fontSize: 7,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_combat.playerRoundWins} - ${_combat.opponentRoundWins}',
                  style: GoogleFonts.pressStart2p(
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (_combat.playerStreak >= 2)
                  Text(
                    '${_combat.playerStreak}X!',
                    style: GoogleFonts.pressStart2p(
                      textStyle: const TextStyle(
                        color: Color(0xFFFF8000),
                        fontSize: 7,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          HpBar(
            percent: _combat.opponentHpPercent,
            color: widget.opponent.accentColor,
            label: widget.opponent.name,
            alignRight: true,
          ),
        ],
      ),
    );
  }

  Widget _buildGrawlixBubble(String text, bool pointsRight) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 250),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.4 + value * 0.6,
          child: Opacity(opacity: value, child: child),
        );
      },
      child: CustomPaint(
        painter: _SpeechBubblePainter(pointsRight: pointsRight),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            text,
            style: GoogleFonts.pressStart2p(
              textStyle: const TextStyle(
                color: Colors.black,
                fontSize: 10,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArena() {
    return Stack(
      children: [
        // Background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0D0528),
                Color(0xFF1A0A3E),
                Color(0xFF0A0A14),
              ],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
        ),
        // Scanlines overlay
        Positioned.fill(
          child: CustomPaint(painter: _ScanlinesPainter()),
        ),
        // Neon side glow — left (cyan)
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: 3,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  const Color(0xFF00FFFF).withValues(alpha: 0.7),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Neon side glow — right (magenta)
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: 3,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  const Color(0xFFFF00FF).withValues(alpha: 0.7),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Perspective grid floor
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 40,
          child: CustomPaint(painter: _FloorGridPainter()),
        ),
        // Fighters
        Positioned(
          bottom: 22,
          left: 40,
          child: FighterWidget(
            character: widget.player,
            animState: _playerAnim,
            facingRight: true,
            onAnimationComplete: null,
          ),
        ),
        Positioned(
          bottom: 22,
          right: 40,
          child: FighterWidget(
            character: widget.opponent,
            animState: _opponentAnim,
            facingRight: false,
            onAnimationComplete: null,
          ),
        ),
        // Grawlix — player
        if (_playerGrawlix != null)
          Positioned(
            bottom: 150,
            left: 8,
            child: _buildGrawlixBubble(_playerGrawlix!, true),
          ),
        // Grawlix — opponent
        if (_opponentGrawlix != null)
          Positioned(
            bottom: 150,
            right: 8,
            child: _buildGrawlixBubble(_opponentGrawlix!, false),
          ),
        // Attack label — large neon pop
        if (_attackLabel != null)
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 300),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.3 + value * 0.7,
                    child: Opacity(opacity: value, child: child),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border.all(
                        color: const Color(0xFFFFFF00), width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFFF00).withValues(alpha: 0.6),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Text(
                    _attackLabel!,
                    style: GoogleFonts.pressStart2p(
                      textStyle: const TextStyle(
                        color: Color(0xFFFFFF00),
                        fontSize: 14,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        // Damage number — big red pop
        if (_damageLabel != null)
          Positioned(
            top: 72,
            left: 0,
            right: 0,
            child: Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 700),
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, -value * 28),
                    child: Opacity(
                      opacity: (1 - value).clamp(0.2, 1.0),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  _damageLabel!,
                  style: GoogleFonts.pressStart2p(
                    textStyle: TextStyle(
                      color: Colors.red,
                      fontSize: 26,
                      shadows: [
                        const Shadow(
                            color: Colors.redAccent, blurRadius: 12),
                        Shadow(
                            color: Colors.red.withValues(alpha: 0.5),
                            blurRadius: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        // Round banner
        if (_showRoundBanner)
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.2 + value * 0.8,
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 48, vertical: 22),
                decoration: BoxDecoration(
                  color: Colors.black,
                  border:
                      Border.all(color: const Color(0xFFFFFF00), width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFFF00).withValues(alpha: 0.6),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  'ROUND ${_combat.currentRound}',
                  style: GoogleFonts.pressStart2p(
                    textStyle: const TextStyle(
                      color: Color(0xFFFFFF00),
                      fontSize: 24,
                      letterSpacing: 4,
                      shadows: [
                        Shadow(
                          color: Color(0xFFFFFF00),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        // Pause button — bottom-right of arena, doesn't touch question panel
        Positioned(
          bottom: 6,
          right: 8,
          child: GestureDetector(
            onTap: _togglePause,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                border: Border.all(
                  color: const Color(0xFF00FFFF).withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.pause,
                color: Color(0xFF00FFFF),
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Painters ────────────────────────────────────────────────────────────────

/// Scanlines overlay for CRT effect
class _ScanlinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_ScanlinesPainter old) => false;
}

/// Perspective grid floor
class _FloorGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00FFFF).withValues(alpha: 0.18)
      ..strokeWidth = 1;

    // Horizontal lines
    for (int i = 0; i <= 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Converging vertical lines (perspective vanishing point at top center)
    final vp = Offset(size.width / 2, 0);
    const numLines = 10;
    for (int i = 0; i <= numLines; i++) {
      final x = size.width * i / numLines;
      canvas.drawLine(Offset(x, size.height), vp, paint);
    }
  }

  @override
  bool shouldRepaint(_FloorGridPainter old) => false;
}

/// Comic-book style jagged speech bubble painter.
class _SpeechBubblePainter extends CustomPainter {
  final bool pointsRight;

  _SpeechBubblePainter({required this.pointsRight});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final w = size.width;
    final h = size.height;
    const jaggedness = 3.0;

    final path = Path();
    path.moveTo(0, 0);
    for (double x = 0; x < w; x += 8) {
      path.lineTo(x + 4, -jaggedness);
      path.lineTo(x + 8, 0);
    }
    for (double y = 0; y < h; y += 8) {
      path.lineTo(w + jaggedness, y + 4);
      path.lineTo(w, y + 8);
    }
    for (double x = w; x > 0; x -= 8) {
      path.lineTo(x - 4, h + jaggedness);
      path.lineTo(x - 8, h);
    }
    for (double y = h; y > 0; y -= 8) {
      path.lineTo(-jaggedness, y - 4);
      path.lineTo(0, y - 8);
    }
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);

    final tailPath = Path();
    if (pointsRight) {
      tailPath.moveTo(w * 0.6, h);
      tailPath.lineTo(w * 0.7, h + 12);
      tailPath.lineTo(w * 0.8, h);
    } else {
      tailPath.moveTo(w * 0.2, h);
      tailPath.lineTo(w * 0.3, h + 12);
      tailPath.lineTo(w * 0.4, h);
    }
    tailPath.close();
    canvas.drawPath(tailPath, paint);
    canvas.drawPath(tailPath, borderPaint);

    final coverPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    if (pointsRight) {
      canvas.drawLine(
          Offset(w * 0.6 + 1, h), Offset(w * 0.8 - 1, h), coverPaint);
    } else {
      canvas.drawLine(
          Offset(w * 0.2 + 1, h), Offset(w * 0.4 - 1, h), coverPaint);
    }
  }

  @override
  bool shouldRepaint(_SpeechBubblePainter oldDelegate) =>
      oldDelegate.pointsRight != pointsRight;
}
