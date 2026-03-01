enum AttackType {
  punch(30, 'Punch'),
  kick(40, 'Kick'),
  jumpKick(50, 'Jump Kick'),
  suplex(80, 'Suplex');

  final int damage;
  final String displayName;
  const AttackType(this.damage, this.displayName);
}

enum AnimationState {
  idle,
  punch,
  kick,
  jumpKick,
  suplex,
  hitReceived,
  ko,
  victory,
}

class CombatState {
  int playerHp;
  int opponentHp;
  int playerStreak;
  int playerRoundWins;
  int opponentRoundWins;
  int currentRound;
  int questionsAnswered;
  int correctAnswers;
  int bestStreak;
  bool isPlayerTurn;

  CombatState()
      : playerHp = 500,
        opponentHp = 500,
        playerStreak = 0,
        playerRoundWins = 0,
        opponentRoundWins = 0,
        currentRound = 1,
        questionsAnswered = 0,
        correctAnswers = 0,
        bestStreak = 0,
        isPlayerTurn = true;

  void resetRound() {
    playerHp = 500;
    opponentHp = 500;
    playerStreak = 0;
    currentRound++;
  }

  double get playerHpPercent => playerHp / 500.0;
  double get opponentHpPercent => opponentHp / 500.0;
  double get accuracy =>
      questionsAnswered > 0 ? correctAnswers / questionsAnswered : 0.0;

  bool get isMatchOver => playerRoundWins >= 2 || opponentRoundWins >= 2;
  bool get playerWonMatch => playerRoundWins >= 2;
  bool get isRoundOver => playerHp <= 0 || opponentHp <= 0;
  bool get playerWonRound => opponentHp <= 0;
}
