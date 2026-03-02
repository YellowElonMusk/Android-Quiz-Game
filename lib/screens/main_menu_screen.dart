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

const _amber = Color(0xFFFFB800);
const _orange = Color(0xFFFF4500);
const _screenGreen = Color(0xFF39FF14);
const _arcadeBg = Color(0xFF0A0500);

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
  late AnimationController _blinkCtrl;
  late AnimationController _titleCtrl;
  late AnimationController _bgCtrl;

  @override
  void initState() {
    super.initState();
    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _titleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _blinkCtrl.dispose();
    _titleCtrl.dispose();
    _bgCtrl.dispose();
    super.dispose();
  }

  void _startGame() {
    if (!widget.storageService.canPlay) { _showPaywall(); return; }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CharacterSelectScreen(
          storageService: widget.storageService,
          onSelect: _onCharacterSelected,
        ),
      ),
    );
  }

  void _onCharacterSelected(GameCharacter player) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategorySelectScreen(
          storageService: widget.storageService,
          onSelect: (cat, diff) => _onCategorySelected(player, cat, diff),
        ),
      ),
    );
  }

  Future<void> _onCategorySelected(
      GameCharacter player, QuizCategory cat, Difficulty diff) async {
    await widget.questionService.loadCategory(cat);
    final opponents =
        GameCharacter.roster.where((c) => c.id != player.id).toList();
    final opponent = opponents[Random().nextInt(opponents.length)];
    await widget.storageService.useRun();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => FightScreen(
            player: player,
            opponent: opponent,
            category: cat,
            difficulty: diff,
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
        backgroundColor: _arcadeBg,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: _orange, width: 3),
          borderRadius: BorderRadius.zero,
        ),
        title: Text(
          'GAME OVER',
          style: GoogleFonts.blackOpsOne(
            textStyle:
                const TextStyle(color: _amber, fontSize: 18, letterSpacing: 2),
          ),
        ),
        content: Text(
          'FREE RUNS USED UP!\n\nUNLOCK UNLIMITED RUNS + ALL CONTENT FOR \$2.99',
          style: GoogleFonts.vt323(
            textStyle: const TextStyle(
                color: Colors.white70, fontSize: 20, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('LATER',
                style: GoogleFonts.vt323(
                    textStyle:
                        const TextStyle(color: Colors.grey, fontSize: 18))),
          ),
          GestureDetector(
            onTap: () {
              widget.storageService.setPaid(true);
              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                backgroundColor: Colors.black,
                content: Text('FULL VERSION UNLOCKED!',
                    style: GoogleFonts.vt323(
                        textStyle: const TextStyle(
                            color: _screenGreen, fontSize: 20))),
              ));
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: _amber, width: 2),
              ),
              child: Text('UNLOCK \$2.99',
                  style: GoogleFonts.vt323(
                      textStyle:
                          const TextStyle(color: _amber, fontSize: 18))),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _arcadeBg,
      body: Stack(
        children: [
          // Animated warm background
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (context, _) => CustomPaint(
              size: Size.infinite,
              painter: _CabinetBgPainter(_bgCtrl.value),
            ),
          ),
          // Scanlines
          Positioned.fill(child: CustomPaint(painter: _ScanlinesPainter())),
          // Amber top strip
          Positioned(
            top: 0, left: 0, right: 0, height: 3,
            child: Container(color: _amber),
          ),
          // Orange bottom strip
          Positioned(
            bottom: 0, left: 0, right: 0, height: 3,
            child: Container(color: _orange),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 1),
                // INSERT COIN — blinks amber
                AnimatedBuilder(
                  animation: _blinkCtrl,
                  builder: (context, child) => Opacity(
                    opacity: _blinkCtrl.value > 0.5 ? 1.0 : 0.0,
                    child: child,
                  ),
                  child: Text(
                    '— INSERT COIN —',
                    style: GoogleFonts.vt323(
                      textStyle: const TextStyle(
                        color: _amber,
                        fontSize: 22,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Title with slow pulse
                AnimatedBuilder(
                  animation: _titleCtrl,
                  builder: (context, child) => Transform.scale(
                    scale: 1.0 + _titleCtrl.value * 0.03,
                    child: child,
                  ),
                  child: Column(
                    children: [
                      Text(
                        'QUIZ',
                        style: GoogleFonts.blackOpsOne(
                          textStyle: TextStyle(
                            fontSize: 52,
                            color: _amber,
                            shadows: [
                              // Solid offset — real arcade marquee style
                              const Shadow(
                                color: _orange,
                                blurRadius: 0,
                                offset: Offset(4, 4),
                              ),
                              const Shadow(
                                color: Colors.black,
                                blurRadius: 0,
                                offset: Offset(7, 7),
                              ),
                              // Soft outer glow
                              Shadow(
                                color: _amber.withValues(alpha: 0.35),
                                blurRadius: 28,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Text(
                        'FIGHTER',
                        style: GoogleFonts.blackOpsOne(
                          textStyle: TextStyle(
                            fontSize: 36,
                            color: Colors.white,
                            shadows: [
                              const Shadow(
                                color: _orange,
                                blurRadius: 0,
                                offset: Offset(3, 3),
                              ),
                              const Shadow(
                                color: Colors.black,
                                blurRadius: 0,
                                offset: Offset(5, 5),
                              ),
                              Shadow(
                                color: _orange.withValues(alpha: 0.3),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'STUDY NOTHING. FIGHT EVERYONE.',
                  style: GoogleFonts.vt323(
                    textStyle: const TextStyle(
                      color: _orange,
                      fontSize: 16,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const Spacer(flex: 1),
                // Fighters
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 140, width: 100,
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
                        style: GoogleFonts.blackOpsOne(
                          textStyle: const TextStyle(
                            color: Color(0xFFFF1A00),
                            fontSize: 28,
                            shadows: [
                              Shadow(
                                  color: Colors.black,
                                  blurRadius: 0,
                                  offset: Offset(3, 3)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 140, width: 100,
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
                      _menuBtn('FIGHT!', _amber, _startGame),
                      const SizedBox(height: 12),
                      _menuBtn('SETTINGS', Colors.white54, _showSettings),
                      if (!widget.storageService.isPaid) ...[
                        const SizedBox(height: 12),
                        _menuBtn('UNLOCK FULL GAME', _orange, _showPaywall),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (!widget.storageService.isPaid)
                  Text(
                    'FREE RUNS: ${widget.storageService.freeRunsRemaining}',
                    style: GoogleFonts.vt323(
                      textStyle:
                          const TextStyle(color: _orange, fontSize: 20),
                    ),
                  ),
                const SizedBox(height: 6),
                // Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _statChip('WINS',
                        '${widget.storageService.totalWins}', _screenGreen),
                    const SizedBox(width: 36),
                    _statChip('STREAK',
                        '${widget.storageService.highStreak}X', _orange),
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

  Widget _menuBtn(String text, Color accent, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: accent, width: 3),
          boxShadow: [
            BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 12),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.blackOpsOne(
              textStyle:
                  TextStyle(color: accent, fontSize: 16, letterSpacing: 2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.vt323(
                textStyle: TextStyle(color: color, fontSize: 36))),
        Text(label,
            style: GoogleFonts.vt323(
                textStyle:
                    const TextStyle(color: Colors.white38, fontSize: 16))),
      ],
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _arcadeBg,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: _amber, width: 2),
        borderRadius: BorderRadius.zero,
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheet) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('SETTINGS',
                    style: GoogleFonts.blackOpsOne(
                      textStyle: const TextStyle(
                          color: _amber, fontSize: 18, letterSpacing: 3),
                    )),
                const SizedBox(height: 20),
                _settingRow('MUSIC', widget.audioService.musicEnabled,
                    (v) => setSheet(() => widget.audioService.toggleMusic())),
                _settingRow('SOUND FX', widget.audioService.sfxEnabled,
                    (v) => setSheet(() => widget.audioService.toggleSfx())),
                const SizedBox(height: 12),
                Text('QuizFighter v1.0 · RadiantBots',
                    style: GoogleFonts.vt323(
                        textStyle: const TextStyle(
                            color: Colors.white24, fontSize: 16))),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _settingRow(
      String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.vt323(
                  textStyle:
                      const TextStyle(color: Colors.white, fontSize: 22))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: _amber,
            activeTrackColor: _amber.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}

// ─── Background painters ──────────────────────────────────────────────────────

/// Warm cabinet background: drifting warm-tinted starfield + amber grid floor
class _CabinetBgPainter extends CustomPainter {
  final double t;
  _CabinetBgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rand = Random(42);
    final paint = Paint()..style = PaintingStyle.fill;

    // Warm starfield — amber-tinted twinkle
    for (int i = 0; i < 50; i++) {
      final x = rand.nextDouble() * size.width;
      final y = rand.nextDouble() * size.height;
      final twinkle = sin(t * 2 * pi + i * 0.9).abs();
      paint.color =
          const Color(0xFFFFB800).withValues(alpha: 0.03 + twinkle * 0.08);
      canvas.drawCircle(
          Offset(x, y), rand.nextDouble() * 1.2 + 0.4, paint);
    }

    // Amber grid floor at bottom
    final gridPaint = Paint()
      ..color = const Color(0xFFFFB800).withValues(alpha: 0.07)
      ..strokeWidth = 1;
    final floorY = size.height * 0.72;
    for (double y = floorY; y < size.height; y += 18) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final vp = Offset(size.width / 2, floorY);
    for (int i = 0; i <= 8; i++) {
      final x = size.width * i / 8;
      canvas.drawLine(Offset(x, size.height), vp, gridPaint);
    }
  }

  @override
  bool shouldRepaint(_CabinetBgPainter old) => old.t != t;
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
