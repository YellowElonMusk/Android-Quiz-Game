import 'dart:math';
import 'package:flutter/material.dart';
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
  String? _attackLabel;
  String? _damageLabel;

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
    if (_isAnimating || _questionIndex >= _questions.length) return;

    final question = _questions[_questionIndex];
    final isCorrect =
        selectedIndex >= 0 && selectedIndex == question.correctIndex;

    _combat.questionsAnswered++;

    setState(() {
      _isAnimating = true;
    });

    if (isCorrect) {
      _combat.correctAnswers++;
      _combat.playerStreak++;
      if (_combat.playerStreak > _combat.bestStreak) {
        _combat.bestStreak = _combat.playerStreak;
      }

      // Check for suplex (3 streak)
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
        });
      });

      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        _afterTurn();
      });
    }
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
      // Ran out of questions — re-shuffle
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
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            // Top info bar
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
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black54,
      child: Row(
        children: [
          HpBar(
            percent: _combat.playerHpPercent,
            color: widget.player.accentColor,
            label: widget.player.name,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Round ${_combat.currentRound} of 3',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_combat.playerRoundWins} - ${_combat.opponentRoundWins}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_combat.playerStreak >= 2)
                  Text(
                    'Streak: ${_combat.playerStreak}x',
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
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

  Widget _buildArena() {
    return Stack(
      children: [
        // Background gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF16213E), Color(0xFF0F3460)],
            ),
          ),
        ),
        // Ground line
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Container(
            height: 2,
            color: Colors.white24,
          ),
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
        // Attack label
        if (_attackLabel != null)
          Positioned(
            top: 30,
            left: 0,
            right: 0,
            child: Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 400),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.5 + value * 0.5,
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.yellowAccent, width: 2),
                  ),
                  child: Text(
                    _attackLabel!,
                    style: const TextStyle(
                      color: Colors.yellowAccent,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        // Damage number
        if (_damageLabel != null)
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, -value * 20),
                    child: Opacity(
                      opacity: (1 - value).clamp(0.3, 1.0),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  _damageLabel!,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
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
              duration: const Duration(milliseconds: 600),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.3 + value * 0.7,
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.yellowAccent, width: 3),
                ),
                child: Text(
                  'ROUND ${_combat.currentRound}',
                  style: const TextStyle(
                    color: Colors.yellowAccent,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
