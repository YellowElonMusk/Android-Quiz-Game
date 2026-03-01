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

  factory Question.fromJson(Map<String, dynamic> json, QuizCategory category) {
    return Question(
      text: json['question'] as String,
      options: List<String>.from(json['options'] as List),
      correctIndex: json['answer'] as int,
      category: category,
      difficulty: Difficulty.values.firstWhere(
        (d) => d.name == (json['difficulty'] as String? ?? 'rookie'),
        orElse: () => Difficulty.rookie,
      ),
    );
  }
}
