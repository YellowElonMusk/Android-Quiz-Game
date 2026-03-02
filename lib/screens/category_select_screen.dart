import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/question.dart';
import '../services/storage_service.dart';

const _amber = Color(0xFFFFB800);
const _orange = Color(0xFFFF4500);
const _screenGreen = Color(0xFF39FF14);
const _arcadeBg = Color(0xFF0A0500);

class CategorySelectScreen extends StatefulWidget {
  final StorageService storageService;
  final void Function(QuizCategory category, Difficulty difficulty) onSelect;

  const CategorySelectScreen({
    super.key,
    required this.storageService,
    required this.onSelect,
  });

  @override
  State<CategorySelectScreen> createState() => _CategorySelectScreenState();
}

class _CategorySelectScreenState extends State<CategorySelectScreen> {
  Difficulty _selectedDifficulty = Difficulty.easy;

  static const _categoryIcons = {
    QuizCategory.popCulture: Icons.star,
    QuizCategory.worldHistory: Icons.public,
    QuizCategory.scienceSpace: Icons.rocket_launch,
    QuizCategory.mathematics: Icons.calculate,
    QuizCategory.geography: Icons.map,
    QuizCategory.moviesTv: Icons.movie,
    QuizCategory.music: Icons.music_note,
    QuizCategory.sports: Icons.sports_soccer,
  };

  // Warm arcade cabinet color palette — each stage has its own marquee tint
  static const _categoryColors = [
    Color(0xFFFFB800), // amber
    Color(0xFFFF4500), // blood orange
    Color(0xFF39FF14), // phosphor green
    Color(0xFFFFD700), // gold
    Color(0xFFFF8C00), // dark orange
    Color(0xFFFFA500), // orange
    Color(0xFFFFB800), // amber
    Color(0xFF39FF14), // phosphor green
  ];

  @override
  Widget build(BuildContext context) {
    final isPaid = widget.storageService.isPaid;

    return Scaffold(
      backgroundColor: _arcadeBg,
      body: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0, height: 3,
            child: Container(color: _amber),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: _arcadeBg,
                    border: Border(
                      bottom: BorderSide(color: _amber, width: 2),
                    ),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            border: Border.all(color: _amber, width: 2),
                          ),
                          child: const Icon(Icons.arrow_back,
                              color: _amber, size: 18),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'SELECT STAGE',
                            style: GoogleFonts.blackOpsOne(
                              textStyle: const TextStyle(
                                color: _amber,
                                fontSize: 14,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 30),
                    ],
                  ),
                ),
                // Difficulty selector
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  child: Row(
                    children: Difficulty.values.map((d) {
                      final isSelected = _selectedDifficulty == d;
                      final dColor = d == Difficulty.easy
                          ? _screenGreen
                          : _orange;
                      return Expanded(
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 4),
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedDifficulty = d),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? dColor.withValues(alpha: 0.12)
                                    : Colors.black,
                                border: Border.all(
                                  color: isSelected ? dColor : Colors.white24,
                                  width: isSelected ? 3 : 2,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: dColor.withValues(alpha: 0.3),
                                          blurRadius: 10,
                                        )
                                      ]
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Column(
                                children: [
                                  Text(
                                    d.displayName.toUpperCase(),
                                    style: GoogleFonts.blackOpsOne(
                                      textStyle: TextStyle(
                                        color: isSelected
                                            ? dColor
                                            : Colors.white54,
                                        fontSize: 13,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${d.optionCount} CHOICES',
                                    style: GoogleFonts.vt323(
                                      textStyle: TextStyle(
                                        color: isSelected
                                            ? dColor.withValues(alpha: 0.8)
                                            : Colors.white24,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                // Categories grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.6,
                    ),
                    itemCount: QuizCategory.values.length,
                    itemBuilder: (context, index) {
                      final category = QuizCategory.values[index];
                      final isLocked = category.isPaid && !isPaid;
                      final icon = _categoryIcons[category] ?? Icons.quiz;
                      final color = _categoryColors[
                          index % _categoryColors.length];

                      return GestureDetector(
                        onTap: () {
                          if (isLocked) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.black,
                                content: Text(
                                  'UNLOCK FOR \$2.99!',
                                  style: GoogleFonts.vt323(
                                    textStyle: const TextStyle(
                                        color: _amber, fontSize: 18),
                                  ),
                                ),
                              ),
                            );
                            return;
                          }
                          widget.onSelect(category, _selectedDifficulty);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isLocked
                                ? Colors.black
                                : color.withValues(alpha: 0.07),
                            border: Border.all(
                              color: isLocked
                                  ? Colors.white12
                                  : color.withValues(alpha: 0.5),
                              width: 2,
                            ),
                            boxShadow: isLocked
                                ? null
                                : [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.12),
                                      blurRadius: 8,
                                    ),
                                  ],
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      icon,
                                      size: 28,
                                      color: isLocked
                                          ? Colors.grey[700]
                                          : color,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      category.displayName.toUpperCase(),
                                      style: GoogleFonts.vt323(
                                        textStyle: TextStyle(
                                          color: isLocked
                                              ? Colors.grey[600]
                                              : Colors.white70,
                                          fontSize: 18,
                                        ),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                              if (isLocked)
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Icon(Icons.lock,
                                      color: Colors.grey[500], size: 14),
                                ),
                              if (!isLocked && !category.isPaid)
                                Positioned(
                                  top: 5,
                                  left: 5,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      border: Border.all(
                                          color: _screenGreen, width: 1),
                                    ),
                                    child: Text(
                                      'FREE',
                                      style: GoogleFonts.vt323(
                                        textStyle: const TextStyle(
                                          color: _screenGreen,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
