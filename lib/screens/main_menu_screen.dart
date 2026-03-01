import 'dart:math';
import 'package:flutter/material.dart';
import '../models/character.dart';
import '../models/question.dart';
import '../models/combat.dart';
import '../services/question_service.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';
import '../widgets/fighter_widget.dart';
import 'character_select_screen.dart';
import 'category_select_screen.dart';
import 'fight_screen.dart';

class MainMenuScreen extends StatefulWidget {
  final StorageService storageService;
  final QuestionService questionService;
  final AudioService audioService;

  const MainMenuScreen({
    super.key,
    required this.storageService,
    required this.questionService,
    required this.audioService,
  });

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _titlePulse;

  @override
  void initState() {
    super.initState();
    _titlePulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _titlePulse.dispose();
    super.dispose();
  }

  void _startGame() {
    if (!widget.storageService.canPlay) {
      _showPaywall();
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CharacterSelectScreen(
          storageService: widget.storageService,
          onSelect: (player) => _onCharacterSelected(player),
        ),
      ),
    );
  }

  void _onCharacterSelected(GameCharacter player) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategorySelectScreen(
          storageService: widget.storageService,
          onSelect: (category, difficulty) =>
              _onCategorySelected(player, category, difficulty),
        ),
      ),
    );
  }

  Future<void> _onCategorySelected(
    GameCharacter player,
    QuizCategory category,
    Difficulty difficulty,
  ) async {
    // Load questions for selected category
    await widget.questionService.loadCategory(category);

    // Pick random opponent
    final opponents = GameCharacter.roster
        .where((c) => c.id != player.id)
        .toList();
    final opponent = opponents[Random().nextInt(opponents.length)];

    // Track run usage
    await widget.storageService.useRun();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => FightScreen(
            player: player,
            opponent: opponent,
            category: category,
            difficulty: difficulty,
            questionService: widget.questionService,
            audioService: widget.audioService,
          ),
        ),
      );
    }
  }

  void _showPaywall() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Free Runs Used',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'You\'ve used all 3 free runs!\n\n'
          'Unlock unlimited runs, all characters, and all categories for just \$2.99.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () {
              // In production: trigger Google Play Billing
              // For now, simulate unlock
              widget.storageService.setPaid(true);
              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Full version unlocked!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellowAccent,
              foregroundColor: Colors.black,
            ),
            child: const Text('Unlock \$2.99'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // Title
              AnimatedBuilder(
                animation: _titlePulse,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + _titlePulse.value * 0.05,
                    child: child,
                  );
                },
                child: Column(
                  children: [
                    Text(
                      'QUIZ',
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        color: Colors.yellowAccent,
                        letterSpacing: 8,
                        shadows: [
                          Shadow(
                            color: Colors.yellow.withValues(alpha: 0.5),
                            blurRadius: 30,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'FIGHTER',
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 12,
                        shadows: [
                          Shadow(
                            color: Colors.blueAccent.withValues(alpha: 0.5),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Study nothing. Know everything. Fight anyone.',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const Spacer(flex: 1),
              // Two fighters facing off
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 140,
                    width: 100,
                    child: FighterWidget(
                      character: GameCharacter.roster[0], // Ryo
                      animState: AnimationState.idle,
                      facingRight: true,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'VS',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 140,
                    width: 100,
                    child: FighterWidget(
                      character: GameCharacter.roster[2], // Tank
                      animState: AnimationState.idle,
                      facingRight: false,
                    ),
                  ),
                ],
              ),
              const Spacer(flex: 1),
              // Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    _menuButton('FIGHT', Colors.yellowAccent, Colors.black,
                        _startGame),
                    const SizedBox(height: 12),
                    _menuButton('SETTINGS', Colors.grey[800]!, Colors.white,
                        _showSettings),
                    if (!widget.storageService.isPaid) ...[
                      const SizedBox(height: 12),
                      _menuButton(
                          'UNLOCK FULL GAME',
                          Colors.amber.withValues(alpha: 0.3),
                          Colors.amber,
                          _showPaywall),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (!widget.storageService.isPaid)
                Text(
                  'Free runs remaining: ${widget.storageService.freeRunsRemaining}',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
              // Stats
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _statChip('Wins', '${widget.storageService.totalWins}'),
                    const SizedBox(width: 24),
                    _statChip(
                        'Best Streak', '${widget.storageService.highStreak}x'),
                  ],
                ),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuButton(
      String text, Color bg, Color textColor, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _statChip(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.yellowAccent,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'SETTINGS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SwitchListTile(
                    title: const Text('Music',
                        style: TextStyle(color: Colors.white)),
                    value: widget.audioService.musicEnabled,
                    onChanged: (v) {
                      setSheetState(() {
                        widget.audioService.toggleMusic();
                      });
                    },
                    activeTrackColor: Colors.yellowAccent,
                  ),
                  SwitchListTile(
                    title: const Text('Sound Effects',
                        style: TextStyle(color: Colors.white)),
                    value: widget.audioService.sfxEnabled,
                    onChanged: (v) {
                      setSheetState(() {
                        widget.audioService.toggleSfx();
                      });
                    },
                    activeTrackColor: Colors.yellowAccent,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'QuizFighter v1.0 by RadiantBots',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
