import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_fighter/models/combat.dart';
import 'package:quiz_fighter/models/character.dart';
import 'package:quiz_fighter/models/question.dart';

void main() {
  group('CombatState', () {
    test('initializes with correct defaults', () {
      final combat = CombatState();
      expect(combat.playerHp, 500);
      expect(combat.opponentHp, 500);
      expect(combat.playerStreak, 0);
      expect(combat.currentRound, 1);
      expect(combat.isMatchOver, false);
    });

    test('round resets HP and increments round', () {
      final combat = CombatState();
      combat.playerHp = 100;
      combat.opponentHp = 0;
      combat.playerStreak = 5;
      combat.resetRound();
      expect(combat.playerHp, 500);
      expect(combat.opponentHp, 500);
      expect(combat.playerStreak, 0);
      expect(combat.currentRound, 2);
    });

    test('match is over when player wins 2 rounds', () {
      final combat = CombatState();
      combat.playerRoundWins = 2;
      expect(combat.isMatchOver, true);
      expect(combat.playerWonMatch, true);
    });

    test('match is over when opponent wins 2 rounds', () {
      final combat = CombatState();
      combat.opponentRoundWins = 2;
      expect(combat.isMatchOver, true);
      expect(combat.playerWonMatch, false);
    });

    test('accuracy calculation', () {
      final combat = CombatState();
      combat.questionsAnswered = 10;
      combat.correctAnswers = 7;
      expect(combat.accuracy, 0.7);
    });
  });

  group('GameCharacter', () {
    test('roster has 4 characters', () {
      expect(GameCharacter.roster.length, 4);
    });

    test('free characters are Ryo and Tank', () {
      final freeChars =
          GameCharacter.roster.where((c) => !c.isPaid).toList();
      expect(freeChars.length, 2);
      expect(freeChars.map((c) => c.name), containsAll(['Ryo', 'Tank']));
    });

    test('paid characters are Yuki and Iris', () {
      final paidChars =
          GameCharacter.roster.where((c) => c.isPaid).toList();
      expect(paidChars.length, 2);
      expect(paidChars.map((c) => c.name), containsAll(['Yuki', 'Iris']));
    });
  });

  group('AttackType', () {
    test('damage values are correct', () {
      expect(AttackType.punch.damage, 30);
      expect(AttackType.kick.damage, 40);
      expect(AttackType.jumpKick.damage, 50);
      expect(AttackType.suplex.damage, 80);
    });
  });

  group('Difficulty', () {
    test('easy mode shows 2 options', () {
      expect(Difficulty.easy.optionCount, 2);
    });

    test('hard mode shows 4 options', () {
      expect(Difficulty.hard.optionCount, 4);
    });
  });

  group('Question', () {
    test('fromJson parses old format (answer key)', () {
      final json = {
        'question': 'Test question?',
        'options': ['A', 'B', 'C', 'D'],
        'answer': 2,
      };
      final q = Question.fromJson(json, QuizCategory.popCulture);
      expect(q.text, 'Test question?');
      expect(q.options.length, 4);
      expect(q.correctIndex, 2);
      expect(q.category, QuizCategory.popCulture);
    });

    test('fromJson parses new format (correct key)', () {
      final json = {
        'id': 'pc_001',
        'question': 'New format question?',
        'options': ['A', 'B', 'C', 'D'],
        'correct': 1,
        'explanation': 'Some explanation',
      };
      final q = Question.fromJson(json, QuizCategory.popCulture);
      expect(q.text, 'New format question?');
      expect(q.options.length, 4);
      expect(q.correctIndex, 1);
      expect(q.category, QuizCategory.popCulture);
    });
  });

  group('QuizCategory', () {
    test('free categories are popCulture and worldHistory', () {
      final free = QuizCategory.values.where((c) => !c.isPaid).toList();
      expect(free.length, 2);
      expect(free, contains(QuizCategory.popCulture));
      expect(free, contains(QuizCategory.worldHistory));
    });

    test('paid categories count is 6', () {
      final paid = QuizCategory.values.where((c) => c.isPaid).toList();
      expect(paid.length, 6);
    });
  });
}
