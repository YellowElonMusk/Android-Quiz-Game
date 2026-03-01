import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../models/question.dart';

class QuestionService {
  final Map<QuizCategory, List<Question>> _questions = {};
  final Random _random = Random();

  Future<void> loadCategory(QuizCategory category) async {
    if (_questions.containsKey(category)) return;

    final fileName = _categoryToFileName(category);
    final jsonString = await rootBundle.loadString('assets/questions/$fileName');
    final decoded = json.decode(jsonString);

    List<dynamic> jsonList;

    if (decoded is List) {
      // Old format: flat array of question objects
      jsonList = decoded;
    } else if (decoded is Map<String, dynamic>) {
      // New format: wrapper object with "questions" array
      jsonList = decoded['questions'] as List<dynamic>;
    } else {
      jsonList = [];
    }

    _questions[category] = jsonList
        .map((q) => Question.fromJson(q as Map<String, dynamic>, category))
        .toList();
  }

  String _categoryToFileName(QuizCategory category) {
    switch (category) {
      case QuizCategory.popCulture:
        return 'pop_culture.json';
      case QuizCategory.worldHistory:
        return 'world_history.json';
      case QuizCategory.scienceSpace:
        return 'science_space.json';
      case QuizCategory.mathematics:
        return 'mathematics.json';
      case QuizCategory.geography:
        return 'geography.json';
      case QuizCategory.moviesTv:
        return 'movies_tv.json';
      case QuizCategory.music:
        return 'music.json';
      case QuizCategory.sports:
        return 'sports.json';
    }
  }

  /// Returns a shuffled list of questions for a match.
  /// Difficulty controls how many options are shown (2 or 4),
  /// not which questions are picked.
  List<Question> getQuestionsForMatch(
    QuizCategory category, {
    int count = 30,
  }) {
    final categoryQuestions = _questions[category] ?? [];
    if (categoryQuestions.isEmpty) return [];

    final shuffled = List<Question>.from(categoryQuestions);
    shuffled.shuffle(_random);
    return shuffled.take(count).toList();
  }
}
