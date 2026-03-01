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

enum Difficulty {
  easy(2, 'Easy'),
  hard(4, 'Hard');

  final int optionCount;
  final String displayName;
  const Difficulty(this.optionCount, this.displayName);
}

class Question {
  final String text;
  final List<String> options;
  final int correctIndex;
  final QuizCategory category;

  const Question({
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.category,
  });

  factory Question.fromJson(Map<String, dynamic> json, QuizCategory category) {
    // Support both "answer" (old format) and "correct" (new format)
    final correctIndex = (json['correct'] ?? json['answer']) as int;

    return Question(
      text: json['question'] as String,
      options: List<String>.from(json['options'] as List),
      correctIndex: correctIndex,
      category: category,
    );
  }
}
