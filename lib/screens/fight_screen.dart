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

// ─── Palette ─────────────────────────────────────────────────────────────────
const _amber = Color(0xFFFFB800);
const _orange = Color(0xFFFF4500);
const _screenGreen = Color(0xFF39FF14);
const _arcadeBg = Color(0xFF0A0500);

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

  String? _playerGrawlix;
  String? _opponentGrawlix;

  static const _grawlixOptions = [
    '#\$@!', '@&#\$?!', '%#@\$!', '\$#@&!',
    '!@#\$%', '#\$%&!', '@#!\$?', '&%#@!',
  ];

  @override
  void initState() {
    super.initState();
    _combat = CombatState();
    _questions = widget.questionService.getQuestionsForMatch(widget.category);
    _showRoundStart();
  }

  void _showRoundStart() {
    setState(() => _showRoundBanner = true);
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _showRoundBanner = false);
    });
  }

  AttackType _randomAttack() {
    final roll = _random.nextInt(3);
    return [AttackType.punch, AttackType.kick, AttackType.jumpKick][roll];
  }

  AnimationState _attackToAnim(AttackType attack) {
    switch (attack) {
      case AttackType.punch:    return AnimationState.punch;
      case AttackType.kick:     return AnimationState.kick;
      case AttackType.jumpKick: return AnimationState.jumpKick;
      case AttackType.suplex:   return AnimationState.suplex;
    }
  }

  void _onAnswer(int selectedIndex) {
    if (_isPaused || _isAnimating || _questionIndex >= _questions.length) return;
    final question = _questions[_questionIndex];
    final isCorrect = selectedIndex >= 0 && selectedIndex == question.correctIndex;
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
      AttackType attack = (_combat.playerStreak >= 3 && _combat.playerStreak % 3 == 0)
          ? AttackType.suplex
          : _randomAttack();
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
          _combat.opponentHp = (_combat.opponentHp - attack.damage).clamp(0, 500);
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
          _combat.playerHp = (_combat.playerHp - attack.damage).clamp(0, 500);
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

  void _togglePause() => setState(() => _isPaused = !_isPaused);
  void _quitToMenu() =>
      Navigator.of(context).popUntil((route) => route.isFirst);

  void _playAttackSound(AttackType attack) {
    switch (attack) {
      case AttackType.punch:    widget.audioService.playPunch();
      case AttackType.kick:     widget.audioService.playKick();
      case AttackType.jumpKick: widget.audioService.playKick();
      case AttackType.suplex:   widget.audioService.playSuplex();
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

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _arcadeBg,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildTopBar(),
                Expanded(flex: 55, child: _buildArena()),
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
            if (_isPaused) _buildPauseOverlay(),
          ],
        ),
      ),
    );
  }

  // ─── Top bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const BoxDecoration(
        color: _arcadeBg,
        border: Border(bottom: BorderSide(color: _amber, width: 2)),
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
                  style: GoogleFonts.vt323(
                    textStyle:
                        const TextStyle(color: _amber, fontSize: 18),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${_combat.playerRoundWins}  -  ${_combat.opponentRoundWins}',
                  style: GoogleFonts.vt323(
                    textStyle:
                        const TextStyle(color: Colors.white, fontSize: 34),
                  ),
                ),
                if (_combat.playerStreak >= 2)
                  Text(
                    '${_combat.playerStreak}X STREAK',
                    style: GoogleFonts.vt323(
                      textStyle:
                          const TextStyle(color: _orange, fontSize: 18),
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

  // ─── Arena ─────────────────────────────────────────────────────────────────

  Widget _buildArena() {
    return Stack(
      children: [
        // Warm cabinet gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A0A00), Color(0xFF100500), Color(0xFF0A0300)],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),
        // Scanlines
        Positioned.fill(child: CustomPaint(painter: _ScanlinesPainter())),
        // Left amber glow
        Positioned(
          left: 0, top: 0, bottom: 0, width: 3,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  _amber.withValues(alpha: 0.55),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Right orange glow
        Positioned(
          right: 0, top: 0, bottom: 0, width: 3,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  _orange.withValues(alpha: 0.55),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Perspective floor grid
        Positioned(
          bottom: 0, left: 0, right: 0, height: 42,
          child: CustomPaint(painter: _FloorGridPainter()),
        ),
        // Fighters
        Positioned(
          bottom: 22, left: 40,
          child: FighterWidget(
            character: widget.player,
            animState: _playerAnim,
            facingRight: true,
            onAnimationComplete: null,
          ),
        ),
        Positioned(
          bottom: 22, right: 40,
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
            bottom: 150, left: 8,
            child: _buildGrawlixBubble(_playerGrawlix!, true),
          ),
        // Grawlix — opponent
        if (_opponentGrawlix != null)
          Positioned(
            bottom: 150, right: 8,
            child: _buildGrawlixBubble(_opponentGrawlix!, false),
          ),
        // Attack label — solid drop-shadow impact text, no box
        if (_attackLabel != null)
          Positioned(
            top: 14, left: 0, right: 0,
            child: Center(child: _buildAttackLabel()),
          ),
        // Damage number — floats up and fades
        if (_damageLabel != null)
          Positioned(
            top: 62, left: 0, right: 0,
            child: Center(child: _buildDamageLabel()),
          ),
        // Round banner — SF2-style horizontal sweep
        if (_showRoundBanner)
          Positioned.fill(child: _buildRoundBanner()),
        // Pause button — bottom of arena, doesn't touch question panel
        Positioned(
          bottom: 6, right: 8,
          child: GestureDetector(
            onTap: _togglePause,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.85),
                border: Border.all(
                    color: _amber.withValues(alpha: 0.5), width: 1),
              ),
              child: const Icon(Icons.pause, color: _amber, size: 18),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Attack label — no box, solid drop-shadow (real 90s arcade style) ─────

  Widget _buildAttackLabel() {
    return TweenAnimationBuilder<double>(
      key: ValueKey(_attackLabel),
      tween: Tween(begin: 1.6, end: 1.0),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Text(
        _attackLabel!.toUpperCase(),
        style: GoogleFonts.blackOpsOne(
          textStyle: const TextStyle(
            color: _amber,
            fontSize: 32,
            letterSpacing: 2,
            shadows: [
              Shadow(color: _orange, blurRadius: 0, offset: Offset(3, 3)),
              Shadow(color: Colors.black, blurRadius: 0, offset: Offset(5, 5)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Damage number ─────────────────────────────────────────────────────────

  Widget _buildDamageLabel() {
    return TweenAnimationBuilder<double>(
      key: ValueKey(_damageLabel),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, -value * 36),
          child: Opacity(
            opacity: (1.0 - value * 0.9).clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Text(
        _damageLabel!,
        style: GoogleFonts.blackOpsOne(
          textStyle: const TextStyle(
            color: Color(0xFFFF1A00),
            fontSize: 30,
            shadows: [
              Shadow(color: Colors.black, blurRadius: 0, offset: Offset(2, 2)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Round banner — SF2-style horizontal stripe sweep ─────────────────────

  Widget _buildRoundBanner() {
    return TweenAnimationBuilder<double>(
      key: ValueKey(_combat.currentRound),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        final slide = value; // 0 → 1
        return Stack(
          children: [
            // Dark overlay fades in
            Container(color: Colors.black.withValues(alpha: 0.70 * slide)),
            // Top amber bar — slides in from left
            Positioned(
              top: 0, left: 0, right: 0, height: 50,
              child: FractionalTranslation(
                translation: Offset(-(1.0 - slide), 0),
                child: Container(color: _amber),
              ),
            ),
            // Bottom orange bar — slides in from right
            Positioned(
              bottom: 0, left: 0, right: 0, height: 50,
              child: FractionalTranslation(
                translation: Offset(1.0 - slide, 0),
                child: Container(color: _orange),
              ),
            ),
            // Center text — elastic pop-in
            Center(
              child: Transform.scale(
                scale: Curves.elasticOut
                    .transform(slide.clamp(0.0, 1.0))
                    .clamp(0.0, 1.3),
                child: Text(
                  'ROUND ${_combat.currentRound}',
                  style: GoogleFonts.blackOpsOne(
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      letterSpacing: 5,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 0,
                          offset: Offset(4, 4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── Grawlix speech bubble ─────────────────────────────────────────────────

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
            style: GoogleFonts.blackOpsOne(
              textStyle:
                  const TextStyle(color: Colors.black, fontSize: 11),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Pause overlay ─────────────────────────────────────────────────────────

  Widget _buildPauseOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.93),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'PAUSED',
              style: GoogleFonts.blackOpsOne(
                textStyle: TextStyle(
                  color: _amber,
                  fontSize: 40,
                  letterSpacing: 6,
                  shadows: [
                    const Shadow(
                        color: _orange,
                        blurRadius: 0,
                        offset: Offset(4, 4)),
                    Shadow(
                        color: _amber.withValues(alpha: 0.4),
                        blurRadius: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 36),
            _pauseBtn('RESUME', _screenGreen, Colors.black, _togglePause),
            const SizedBox(height: 14),
            // Settings
            Container(
              width: 300,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(
                    color: _amber.withValues(alpha: 0.35), width: 2),
              ),
              child: Column(
                children: [
                  Text(
                    'SETTINGS',
                    style: GoogleFonts.vt323(
                      textStyle: const TextStyle(
                          color: _amber, fontSize: 22, letterSpacing: 3),
                    ),
                  ),
                  const SizedBox(height: 8),
                  StatefulBuilder(
                    builder: (context, setInner) => Column(
                      children: [
                        _arcadeSwitch('MUSIC',
                            widget.audioService.musicEnabled,
                            (v) => setInner(
                                () => widget.audioService.toggleMusic())),
                        _arcadeSwitch('SFX',
                            widget.audioService.sfxEnabled,
                            (v) => setInner(
                                () => widget.audioService.toggleSfx())),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _pauseBtn('QUIT TO MENU', _orange, Colors.white, _quitToMenu),
          ],
        ),
      ),
    );
  }

  Widget _arcadeSwitch(
      String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.vt323(
                  textStyle:
                      const TextStyle(color: Colors.white, fontSize: 20))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: _amber,
            activeTrackColor: _amber.withValues(alpha: 0.35),
          ),
        ],
      ),
    );
  }

  Widget _pauseBtn(
      String text, Color accent, Color textColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: accent, width: 3),
          boxShadow: [
            BoxShadow(color: accent.withValues(alpha: 0.4), blurRadius: 12),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.blackOpsOne(
              textStyle:
                  TextStyle(color: accent, fontSize: 14, letterSpacing: 2),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Painters ────────────────────────────────────────────────────────────────

class _ScanlinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.14)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_ScanlinesPainter old) => false;
}

class _FloorGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFB800).withValues(alpha: 0.14)
      ..strokeWidth = 1;
    for (int i = 0; i <= 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    final vp = Offset(size.width / 2, 0);
    for (int i = 0; i <= 10; i++) {
      final x = size.width * i / 10;
      canvas.drawLine(Offset(x, size.height), vp, paint);
    }
  }

  @override
  bool shouldRepaint(_FloorGridPainter old) => false;
}

class _SpeechBubblePainter extends CustomPainter {
  final bool pointsRight;
  _SpeechBubblePainter({required this.pointsRight});

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final w = size.width;
    final h = size.height;
    const j = 3.0;
    final path = Path();
    path.moveTo(0, 0);
    for (double x = 0; x < w; x += 8) {
      path.lineTo(x + 4, -j);
      path.lineTo(x + 8, 0);
    }
    for (double y = 0; y < h; y += 8) {
      path.lineTo(w + j, y + 4);
      path.lineTo(w, y + 8);
    }
    for (double x = w; x > 0; x -= 8) {
      path.lineTo(x - 4, h + j);
      path.lineTo(x - 8, h);
    }
    for (double y = h; y > 0; y -= 8) {
      path.lineTo(-j, y - 4);
      path.lineTo(0, y - 8);
    }
    path.close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
    final tail = Path();
    if (pointsRight) {
      tail.moveTo(w * 0.6, h);
      tail.lineTo(w * 0.7, h + 12);
      tail.lineTo(w * 0.8, h);
    } else {
      tail.moveTo(w * 0.2, h);
      tail.lineTo(w * 0.3, h + 12);
      tail.lineTo(w * 0.4, h);
    }
    tail.close();
    canvas.drawPath(tail, fill);
    canvas.drawPath(tail, stroke);
    final cover = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    if (pointsRight) {
      canvas.drawLine(Offset(w * 0.6 + 1, h), Offset(w * 0.8 - 1, h), cover);
    } else {
      canvas.drawLine(Offset(w * 0.2 + 1, h), Offset(w * 0.4 - 1, h), cover);
    }
  }

  @override
  bool shouldRepaint(_SpeechBubblePainter old) =>
      old.pointsRight != pointsRight;
}
