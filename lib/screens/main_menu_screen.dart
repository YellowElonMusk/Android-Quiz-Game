import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    with TickerProviderStateMixin {
  late AnimationController _blinkController;
  late AnimationController _titleController;
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _titleController.dispose();
    _bgController.dispose();
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
    await widget.questionService.loadCategory(category);

    final opponents = GameCharacter.roster
        .where((c) => c.id != player.id)
        .toList();
    final opponent = opponents[Random().nextInt(opponents.length)];

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
        backgroundColor: const Color(0xFF04020C),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFFFF00FF), width: 3),
          borderRadius: BorderRadius.zero,
        ),
        title: Text(
          'GAME OVER',
          style: GoogleFonts.pressStart2p(
            textStyle: const TextStyle(color: Color(0xFFFFFF00), fontSize: 16),
          ),
        ),
        content: Text(
          'FREE RUNS USED UP!\n\nUNLOCK UNLIMITED RUNS + ALL CONTENT FOR \$2.99',
          style: GoogleFonts.pressStart2p(
            textStyle: const TextStyle(
                color: Colors.white70, fontSize: 9, height: 1.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'MAYBE LATER',
              style: GoogleFonts.pressStart2p(
                textStyle:
                    const TextStyle(color: Colors.grey, fontSize: 9),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              widget.storageService.setPaid(true);
              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.black,
                  content: Text(
                    'FULL VERSION UNLOCKED!',
                    style: GoogleFonts.pressStart2p(
                      textStyle: const TextStyle(
                          color: Color(0xFF00FF00), fontSize: 10),
                    ),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              side: const BorderSide(color: Color(0xFFFFFF00), width: 2),
            ),
            child: Text(
              'UNLOCK \$2.99',
              style: GoogleFonts.pressStart2p(
                textStyle: const TextStyle(
                    color: Color(0xFFFFFF00), fontSize: 9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04020C),
      body: Stack(
        children: [
          // Animated background
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: _ArcadeBgPainter(_bgController.value),
              );
            },
          ),
          // Scanlines
          Positioned.fill(
            child: CustomPaint(painter: _MenuScanlinesPainter()),
          ),
          // Neon top border
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 3,
            child: Container(color: const Color(0xFF00FFFF)),
          ),
          // Neon bottom border
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 3,
            child: Container(color: const Color(0xFFFF00FF)),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 1),
                // INSERT COIN blink
                AnimatedBuilder(
                  animation: _blinkController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _blinkController.value > 0.5 ? 1.0 : 0.0,
                      child: child,
                    );
                  },
                  child: Text(
                    '- INSERT COIN -',
                    style: GoogleFonts.pressStart2p(
                      textStyle: const TextStyle(
                        color: Color(0xFFFFFF00),
                        fontSize: 10,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Title
                AnimatedBuilder(
                  animation: _titleController,
                  builder: (context, child) {
                    final scale = 1.0 + _titleController.value * 0.04;
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: Column(
                    children: [
                      Text(
                        'QUIZ',
                        style: GoogleFonts.pressStart2p(
                          textStyle: TextStyle(
                            fontSize: 42,
                            color: const Color(0xFFFFFF00),
                            shadows: [
                              const Shadow(
                                color: Color(0xFFFFFF00),
                                blurRadius: 24,
                              ),
                              Shadow(
                                color: const Color(0xFFFF8000)
                                    .withValues(alpha: 0.7),
                                blurRadius: 48,
                                offset: const Offset(3, 4),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Text(
                        'FIGHTER',
                        style: GoogleFonts.pressStart2p(
                          textStyle: TextStyle(
                            fontSize: 28,
                            color: const Color(0xFF00FFFF),
                            shadows: [
                              const Shadow(
                                color: Color(0xFF00FFFF),
                                blurRadius: 20,
                              ),
                              Shadow(
                                color: const Color(0xFF0080FF)
                                    .withValues(alpha: 0.6),
                                blurRadius: 40,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'STUDY NOTHING. FIGHT EVERYONE.',
                  style: GoogleFonts.pressStart2p(
                    textStyle: const TextStyle(
                      color: Color(0xFFFF00FF),
                      fontSize: 7,
                      letterSpacing: 1,
                    ),
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
                        character: GameCharacter.roster[0],
                        animState: AnimationState.idle,
                        facingRight: true,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'VS',
                        style: GoogleFonts.pressStart2p(
                          textStyle: TextStyle(
                            color: Colors.red,
                            fontSize: 24,
                            shadows: [
                              const Shadow(
                                  color: Colors.redAccent, blurRadius: 16),
                              Shadow(
                                color: Colors.red.withValues(alpha: 0.5),
                                blurRadius: 32,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 140,
                      width: 100,
                      child: FighterWidget(
                        character: GameCharacter.roster[2],
                        animState: AnimationState.idle,
                        facingRight: false,
                      ),
                    ),
                  ],
                ),
                const Spacer(flex: 1),
                // Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      _menuButton('FIGHT!', const Color(0xFFFFFF00),
                          Colors.black, _startGame),
                      const SizedBox(height: 12),
                      _menuButton('SETTINGS', const Color(0xFF00FFFF),
                          Colors.black, _showSettings),
                      if (!widget.storageService.isPaid) ...[
                        const SizedBox(height: 12),
                        _menuButton(
                          'UNLOCK FULL GAME',
                          const Color(0xFFFF00FF),
                          Colors.black,
                          _showPaywall,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (!widget.storageService.isPaid)
                  Text(
                    'FREE RUNS: ${widget.storageService.freeRunsRemaining}',
                    style: GoogleFonts.pressStart2p(
                      textStyle: const TextStyle(
                        color: Color(0xFFFF8000),
                        fontSize: 8,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                // Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _statChip('WINS', '${widget.storageService.totalWins}',
                        const Color(0xFF00FF00)),
                    const SizedBox(width: 32),
                    _statChip('STREAK',
                        '${widget.storageService.highStreak}X',
                        const Color(0xFFFF8000)),
                  ],
                ),
                const Spacer(flex: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuButton(
      String text, Color accentColor, Color textColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: accentColor, width: 3),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.4),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.pressStart2p(
              textStyle: TextStyle(
                color: accentColor,
                fontSize: 14,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.pressStart2p(
            textStyle: TextStyle(color: color, fontSize: 18),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.pressStart2p(
            textStyle:
                const TextStyle(color: Colors.white38, fontSize: 7),
          ),
        ),
      ],
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF04020C),
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: Color(0xFF00FFFF), width: 2),
        borderRadius: BorderRadius.zero,
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SETTINGS',
                    style: GoogleFonts.pressStart2p(
                      textStyle: const TextStyle(
                        color: Color(0xFF00FFFF),
                        fontSize: 14,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _settingsTile(
                    'MUSIC',
                    widget.audioService.musicEnabled,
                    (v) => setSheetState(() => widget.audioService.toggleMusic()),
                  ),
                  _settingsTile(
                    'SOUND FX',
                    widget.audioService.sfxEnabled,
                    (v) => setSheetState(() => widget.audioService.toggleSfx()),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'QuizFighter v1.0 by RadiantBots',
                    style: GoogleFonts.pressStart2p(
                      textStyle: const TextStyle(
                          color: Colors.white24, fontSize: 7),
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

  Widget _settingsTile(
      String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.pressStart2p(
              textStyle: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFFFFF00),
            activeTrackColor:
                const Color(0xFFFFFF00).withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}

// ─── Background painters ──────────────────────────────────────────────────────

class _ArcadeBgPainter extends CustomPainter {
  final double t;
  _ArcadeBgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // Animated star field
    final rand = Random(42);
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 60; i++) {
      final x = rand.nextDouble() * size.width;
      final y = rand.nextDouble() * size.height;
      final twinkle = sin(t * 2 * pi + i * 0.7).abs();
      paint.color =
          Colors.white.withValues(alpha: 0.05 + twinkle * 0.15);
      canvas.drawCircle(Offset(x, y), rand.nextDouble() * 1.5 + 0.5, paint);
    }

    // Bottom grid glow
    final gridPaint = Paint()
      ..color = const Color(0xFF00FFFF).withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (double y = size.height * 0.7; y < size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final vp = Offset(size.width / 2, size.height * 0.7);
    for (int i = 0; i <= 8; i++) {
      final x = size.width * i / 8;
      canvas.drawLine(Offset(x, size.height), vp, gridPaint);
    }
  }

  @override
  bool shouldRepaint(_ArcadeBgPainter old) => old.t != t;
}

class _MenuScanlinesPainter extends CustomPainter {
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
  bool shouldRepaint(_MenuScanlinesPainter old) => false;
}
