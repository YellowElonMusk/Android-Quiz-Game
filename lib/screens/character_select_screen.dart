import 'package:flutter/material.dart';
import '../models/character.dart';
import '../models/combat.dart';
import '../services/storage_service.dart';
import '../widgets/fighter_widget.dart';

class CharacterSelectScreen extends StatefulWidget {
  final StorageService storageService;
  final ValueChanged<GameCharacter> onSelect;

  const CharacterSelectScreen({
    super.key,
    required this.storageService,
    required this.onSelect,
  });

  @override
  State<CharacterSelectScreen> createState() => _CharacterSelectScreenState();
}

class _CharacterSelectScreenState extends State<CharacterSelectScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isPaid = widget.storageService.isPaid;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('SELECT FIGHTER'),
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
          const SizedBox(height: 16),
          // Preview of selected character
          SizedBox(
            height: 200,
            child: FighterWidget(
              character: GameCharacter.roster[_selectedIndex],
              animState: AnimationState.idle,
              facingRight: true,
            ),
          ),
          Text(
            GameCharacter.roster[_selectedIndex].name,
            style: TextStyle(
              color: GameCharacter.roster[_selectedIndex].accentColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            GameCharacter.roster[_selectedIndex].hairStyle,
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 32),
          // Character grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.4,
              ),
              itemCount: GameCharacter.roster.length,
              itemBuilder: (context, index) {
                final character = GameCharacter.roster[index];
                final isLocked = character.isPaid && !isPaid;
                final isSelected = _selectedIndex == index;

                return GestureDetector(
                  onTap: () {
                    if (isLocked) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Unlock all characters for \$2.99!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return;
                    }
                    setState(() => _selectedIndex = index);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? character.accentColor.withValues(alpha: 0.2)
                          : Colors.grey[900],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? character.accentColor
                            : Colors.white12,
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person,
                              size: 40,
                              color: isLocked
                                  ? Colors.grey[600]
                                  : character.accentColor,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              character.name,
                              style: TextStyle(
                                color: isLocked
                                    ? Colors.grey[600]
                                    : Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (isLocked)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Icon(
                              Icons.lock,
                              color: Colors.grey[500],
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Confirm button
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onSelect(GameCharacter.roster[_selectedIndex]);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellowAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'FIGHT!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
