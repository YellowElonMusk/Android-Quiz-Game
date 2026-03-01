import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final isPaid = widget.storageService.isPaid;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('SELECT CATEGORY'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.yellowAccent,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 3,
        ),
      ),
      body: Column(
        children: [
          // Difficulty selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: Difficulty.values.map((d) {
                final isSelected = _selectedDifficulty == d;
                final label = '${d.displayName} (${d.optionCount} choices)';
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedDifficulty = d),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _difficultyColor(d)
                              : Colors.grey[900],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? _difficultyColor(d)
                                : Colors.white12,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          label,
                          style: TextStyle(
                            color:
                                isSelected ? Colors.white : Colors.white54,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          // Categories grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
              ),
              itemCount: QuizCategory.values.length,
              itemBuilder: (context, index) {
                final category = QuizCategory.values[index];
                final isLocked = category.isPaid && !isPaid;
                final icon = _categoryIcons[category] ?? Icons.quiz;

                return GestureDetector(
                  onTap: () {
                    if (isLocked) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Unlock all categories for \$2.99!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return;
                    }
                    widget.onSelect(category, _selectedDifficulty);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: isLocked
                          ? null
                          : LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                _categoryColor(index).withValues(alpha: 0.6),
                                _categoryColor(index).withValues(alpha: 0.2),
                              ],
                            ),
                      color: isLocked ? Colors.grey[900] : null,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isLocked
                            ? Colors.white12
                            : _categoryColor(index).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                icon,
                                size: 32,
                                color: isLocked
                                    ? Colors.grey[600]
                                    : Colors.white,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                category.displayName,
                                style: TextStyle(
                                  color: isLocked
                                      ? Colors.grey[600]
                                      : Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        if (isLocked)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Icon(
                              Icons.lock,
                              color: Colors.grey[500],
                              size: 18,
                            ),
                          ),
                        if (!isLocked && !category.isPaid)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'FREE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
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
    );
  }

  Color _difficultyColor(Difficulty d) {
    switch (d) {
      case Difficulty.easy:
        return Colors.green;
      case Difficulty.hard:
        return Colors.red;
    }
  }

  Color _categoryColor(int index) {
    const colors = [
      Colors.purple,
      Colors.teal,
      Colors.blue,
      Colors.deepOrange,
      Colors.green,
      Colors.indigo,
      Colors.pink,
      Colors.amber,
    ];
    return colors[index % colors.length];
  }
}
