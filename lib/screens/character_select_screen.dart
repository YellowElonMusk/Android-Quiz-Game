import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final character = GameCharacter.roster[_selectedIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF04020C),
      body: Stack(
        children: [
          // Neon top border
          Positioned(
            top: 0, left: 0, right: 0, height: 3,
            child: Container(color: const Color(0xFF00FFFF)),
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
                      bottom: BorderSide(color: Color(0xFF00FFFF), width: 2),
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
                                color: const Color(0xFF00FFFF), width: 2),
                          ),
                          child: const Icon(Icons.arrow_back,
                              color: Color(0xFF00FFFF), size: 18),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'SELECT FIGHTER',
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
                const SizedBox(height: 12),
                // Preview
                SizedBox(
                  height: 180,
                  child: FighterWidget(
                    character: character,
                    animState: AnimationState.idle,
                    facingRight: true,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  character.name.toUpperCase(),
                  style: GoogleFonts.pressStart2p(
                    textStyle: TextStyle(
                      color: character.accentColor,
                      fontSize: 16,
                      shadows: [
                        Shadow(
                            color: character.accentColor, blurRadius: 12),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  character.hairStyle.toUpperCase(),
                  style: GoogleFonts.pressStart2p(
                    textStyle: const TextStyle(
                        color: Colors.white38, fontSize: 7),
                  ),
                ),
                const SizedBox(height: 16),
                // Character grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.6,
                    ),
                    itemCount: GameCharacter.roster.length,
                    itemBuilder: (context, index) {
                      final c = GameCharacter.roster[index];
                      final isLocked = c.isPaid && !isPaid;
                      final isSelected = _selectedIndex == index;

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
                                        color: Color(0xFFFFFF00), fontSize: 9),
                                  ),
                                ),
                              ),
                            );
                            return;
                          }
                          setState(() => _selectedIndex = index);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? c.accentColor.withValues(alpha: 0.15)
                                : Colors.black,
                            border: Border.all(
                              color: isLocked
                                  ? Colors.white12
                                  : isSelected
                                      ? c.accentColor
                                      : const Color(0xFF00FFFF)
                                          .withValues(alpha: 0.3),
                              width: isSelected ? 3 : 2,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: c.accentColor
                                          .withValues(alpha: 0.4),
                                      blurRadius: 12,
                                    )
                                  ]
                                : null,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 32,
                                    color: isLocked
                                        ? Colors.grey[700]
                                        : c.accentColor,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    c.name.toUpperCase(),
                                    style: GoogleFonts.pressStart2p(
                                      textStyle: TextStyle(
                                        color: isLocked
                                            ? Colors.grey[600]
                                            : Colors.white,
                                        fontSize: 8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (isLocked)
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Icon(Icons.lock,
                                      color: Colors.grey[500], size: 16),
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
                  padding: const EdgeInsets.all(20),
                  child: GestureDetector(
                    onTap: () {
                      widget.onSelect(GameCharacter.roster[_selectedIndex]);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        border: Border.all(
                            color: const Color(0xFFFFFF00), width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFFF00)
                                .withValues(alpha: 0.4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'FIGHT!',
                          style: GoogleFonts.pressStart2p(
                            textStyle: const TextStyle(
                              color: Color(0xFFFFFF00),
                              fontSize: 16,
                              letterSpacing: 3,
                            ),
                          ),
                        ),
                      ),
                    ),
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
