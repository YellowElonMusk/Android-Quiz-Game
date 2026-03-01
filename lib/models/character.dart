import 'dart:ui';

enum CharacterId { ryo, yuki, tank, iris }

class GameCharacter {
  final CharacterId id;
  final String name;
  final String hairStyle;
  final Color accentColor;
  final bool isPaid;

  const GameCharacter({
    required this.id,
    required this.name,
    required this.hairStyle,
    required this.accentColor,
    this.isPaid = false,
  });

  static const List<GameCharacter> roster = [
    GameCharacter(
      id: CharacterId.ryo,
      name: 'Ryo',
      hairStyle: 'Pompadour',
      accentColor: Color(0xFFE53935),
    ),
    GameCharacter(
      id: CharacterId.yuki,
      name: 'Yuki',
      hairStyle: 'Double Ponytail',
      accentColor: Color(0xFF1E88E5),
      isPaid: true,
    ),
    GameCharacter(
      id: CharacterId.tank,
      name: 'Tank',
      hairStyle: 'Mohawk',
      accentColor: Color(0xFF43A047),
    ),
    GameCharacter(
      id: CharacterId.iris,
      name: 'Iris',
      hairStyle: 'Afro Puffs',
      accentColor: Color(0xFFFDD835),
      isPaid: true,
    ),
  ];
}
