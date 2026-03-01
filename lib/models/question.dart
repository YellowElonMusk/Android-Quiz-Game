enum QuizCategory {
  popCulture('Pop Culture', false),
  worldHistory('World History', false),
  scienceSpace('Science & Space', true),
  mathematics('Mathematics', true),
  geography('Geography', true),
  moviesTv('Movies & TV', true),
  music('Music', true),
  sports('Sports', true);

  final String displayName;
  final bool isPaid;
  const QuizCategory(this.displayName, this.isPaid);
}

enum Difficulty { rookie, veteran, legend }

class Question {
  final String text;
  final List<String> options;
  final int correctIndex;
  final QuizCategory category;
  final Difficulty difficulty;

  const Question({
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.category,
    required this.difficulty,
  });

  factory Question.fromJson(
    Map<String, dynamic> json,
    QuizCategory category, {
    Difficulty? defaultDifficulty,
  }) {
    // Support both "answer" (old format) and "correct" (new format)
    final correctIndex = (json['correct'] ?? json['answer']) as int;

    // Per-question difficulty if present, otherwise fall back to the
    // file-level default (from the wrapper object), or rookie.
    final difficultyStr = json['difficulty'] as String?;
    final difficulty = difficultyStr != null
        ? Difficulty.values.firstWhere(
            (d) => d.name == difficultyStr,
            orElse: () => defaultDifficulty ?? Difficulty.rookie,
          )
        : defaultDifficulty ?? Difficulty.rookie;

    return Question(
      text: json['question'] as String,
      options: List<String>.from(json['options'] as List),
      correctIndex: correctIndex,
      category: category,
      difficulty: difficulty,
    );
  }
}
