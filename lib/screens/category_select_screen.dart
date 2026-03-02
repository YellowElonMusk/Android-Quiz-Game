import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/question.dart';
import '../services/storage_service.dart';

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

  static const _categoryColors = [
    Color(0xFFFF00FF),
    Color(0xFF00FFFF),
    Color(0xFF00AAFF),
    Color(0xFFFF8000),
    Color(0xFF00FF00),
    Color(0xFF8800FF),
    Color(0xFFFF0066),
    Color(0xFFFFFF00),
  ];

  @override
  Widget build(BuildContext context) {
    final isPaid = widget.storageService.isPaid;

    return Scaffold(
      backgroundColor: const Color(0xFF04020C),
      body: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0, height: 3,
            child: Container(color: const Color(0xFFFF00FF)),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF04020C),
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFFF00FF), width: 2),
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
                            border: Border.all(
                                color: const Color(0xFFFF00FF), width: 2),
                          ),
                          child: const Icon(Icons.arrow_back,
                              color: Color(0xFFFF00FF), size: 18),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'SELECT STAGE',
                            style: GoogleFonts.pressStart2p(
                              textStyle: const TextStyle(
                                color: Color(0xFFFFFF00),
                                fontSize: 13,
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
                          ? const Color(0xFF00FF00)
                          : const Color(0xFFFF0000);
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
                                    ? dColor.withValues(alpha: 0.15)
                                    : Colors.black,
                                border: Border.all(
                                  color:
                                      isSelected ? dColor : Colors.white24,
                                  width: isSelected ? 3 : 2,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: dColor
                                              .withValues(alpha: 0.3),
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
                                    style: GoogleFonts.pressStart2p(
                                      textStyle: TextStyle(
                                        color: isSelected
                                            ? dColor
                                            : Colors.white54,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${d.optionCount} CHOICES',
                                    style: GoogleFonts.pressStart2p(
                                      textStyle: TextStyle(
                                        color: isSelected
                                            ? dColor.withValues(alpha: 0.8)
                                            : Colors.white24,
                                        fontSize: 7,
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
                      final color = _categoryColors[index % _categoryColors.length];

                      return GestureDetector(
                        onTap: () {
                          if (isLocked) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.black,
                                content: Text(
                                  'UNLOCK FOR \$2.99!',
                                  style: GoogleFonts.pressStart2p(
                                    textStyle: const TextStyle(
                                        color: Color(0xFFFFFF00),
                                        fontSize: 9),
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
                                : color.withValues(alpha: 0.08),
                            border: Border.all(
                              color: isLocked
                                  ? Colors.white12
                                  : color.withValues(alpha: 0.6),
                              width: 2,
                            ),
                            boxShadow: isLocked
                                ? null
                                : [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.15),
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
                                      style: GoogleFonts.pressStart2p(
                                        textStyle: TextStyle(
                                          color: isLocked
                                              ? Colors.grey[600]
                                              : Colors.white,
                                          fontSize: 7,
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
                                          color: const Color(0xFF00FF00),
                                          width: 1),
                                    ),
                                    child: Text(
                                      'FREE',
                                      style: GoogleFonts.pressStart2p(
                                        textStyle: const TextStyle(
                                          color: Color(0xFF00FF00),
                                          fontSize: 6,
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
