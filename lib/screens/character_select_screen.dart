import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/character.dart';
import '../models/combat.dart';
import '../services/storage_service.dart';
import '../widgets/fighter_widget.dart';

const _amber = Color(0xFFFFB800);
const _orange = Color(0xFFFF4500);
const _arcadeBg = Color(0xFF0A0500);

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
      backgroundColor: _arcadeBg,
      body: Stack(
        children: [
          Positioned(
              top: 0, left: 0, right: 0, height: 3,
              child: Container(color: _amber)),
          SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: _arcadeBg,
                    border: Border(
                        bottom: BorderSide(color: _amber, width: 2)),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            border: Border.all(color: _amber, width: 2),
                          ),
                          child: const Icon(Icons.arrow_back,
                              color: _amber, size: 18),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text('SELECT FIGHTER',
                              style: GoogleFonts.blackOpsOne(
                                textStyle: const TextStyle(
                                    color: _amber,
                                    fontSize: 14,
                                    letterSpacing: 2),
                              )),
                        ),
                      ),
                      const SizedBox(width: 30),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
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
                  style: GoogleFonts.blackOpsOne(
                    textStyle: TextStyle(
                      color: _amber,
                      fontSize: 18,
                      letterSpacing: 3,
                      shadows: const [
                        Shadow(
                            color: _orange,
                            blurRadius: 0,
                            offset: Offset(2, 2)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  character.hairStyle.toUpperCase(),
                  style: GoogleFonts.vt323(
                    textStyle: const TextStyle(
                        color: Colors.white38, fontSize: 18),
                  ),
                ),
                const SizedBox(height: 14),
                // Character grid
                Expanded(
                  child: GridView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
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
                                content: Text('UNLOCK FOR \$2.99!',
                                    style: GoogleFonts.vt323(
                                        textStyle: const TextStyle(
                                            color: _amber, fontSize: 18))),
                              ),
                            );
                            return;
                          }
                          setState(() => _selectedIndex = index);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 130),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _amber.withValues(alpha: 0.10)
                                : Colors.black,
                            border: Border.all(
                              color: isLocked
                                  ? Colors.white12
                                  : isSelected
                                      ? _amber
                                      : _amber.withValues(alpha: 0.25),
                              width: isSelected ? 3 : 2,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: _amber.withValues(alpha: 0.35),
                                      blurRadius: 10,
                                    )
                                  ]
                                : null,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 32,
                                    color: isLocked
                                        ? Colors.grey[700]
                                        : isSelected
                                            ? _amber
                                            : _amber.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    c.name.toUpperCase(),
                                    style: GoogleFonts.vt323(
                                      textStyle: TextStyle(
                                        color: isLocked
                                            ? Colors.grey[600]
                                            : isSelected
                                                ? _amber
                                                : Colors.white70,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (isLocked)
                                Positioned(
                                  top: 5, right: 5,
                                  child: Icon(Icons.lock,
                                      color: Colors.grey[500], size: 14),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Confirm
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: GestureDetector(
                    onTap: () =>
                        widget.onSelect(GameCharacter.roster[_selectedIndex]),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        border: Border.all(color: _amber, width: 3),
                        boxShadow: [
                          BoxShadow(
                              color: _amber.withValues(alpha: 0.4),
                              blurRadius: 14)
                        ],
                      ),
                      child: Center(
                        child: Text('FIGHT!',
                            style: GoogleFonts.blackOpsOne(
                              textStyle: const TextStyle(
                                  color: _amber,
                                  fontSize: 18,
                                  letterSpacing: 4),
                            )),
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
