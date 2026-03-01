import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/question_service.dart';
import 'services/storage_service.dart';
import 'services/audio_service.dart';
import 'screens/main_menu_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode for fighting game layout
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Set system UI style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  final storageService = StorageService();
  await storageService.init();

  final questionService = QuestionService();
  final audioService = AudioService();

  runApp(QuizFighterApp(
    storageService: storageService,
    questionService: questionService,
    audioService: audioService,
  ));
}

class QuizFighterApp extends StatelessWidget {
  final StorageService storageService;
  final QuestionService questionService;
  final AudioService audioService;

  const QuizFighterApp({
    super.key,
    required this.storageService,
    required this.questionService,
    required this.audioService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuizFighter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        primarySwatch: Colors.amber,
        fontFamily: 'Roboto',
      ),
      home: MainMenuScreen(
        storageService: storageService,
        questionService: questionService,
        audioService: audioService,
      ),
    );
  }
}
