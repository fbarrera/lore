import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/story_service.dart';
import 'services/story_management_service.dart';
import 'services/character_service.dart';
import 'screens/story_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => StoryService()),
        Provider(create: (_) => StoryManagementService()),
        Provider(create: (_) => CharacterService()),
      ],
      child: const LoreweaverApp(),
    ),
  );
}

class LoreweaverApp extends StatelessWidget {
  const LoreweaverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loreweaver',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4), // Deep Purple
          brightness: Brightness.dark,
          surface: const Color(0xFF1C1B1F),
          onSurface: const Color(0xFFE6E1E5),
          primary: const Color(0xFFD0BCFF),
          onPrimary: const Color(0xFF381E72),
        ),
        useMaterial3: true,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: ZoomPageTransitionsBuilder(),
            TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
            TargetPlatform.linux: ZoomPageTransitionsBuilder(),
          },
        ),
        textTheme: GoogleFonts.merriweatherTextTheme(ThemeData.dark().textTheme)
            .apply(
              bodyColor: const Color(0xFFE6E1E5),
              displayColor: const Color(0xFFE6E1E5),
            ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: const Color(0xFF381E72),
            backgroundColor: const Color(0xFFD0BCFF),
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    if (authService.isAuthenticated) {
      return const HomeScreen();
    } else {
      return const LoginScreen();
    }
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Loreweaver',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                await Provider.of<AuthService>(
                  context,
                  listen: false,
                ).signInAnonymously();
              },
              child: const Text('Start Your Journey'),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loreweaver'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthService>(context, listen: false).signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome to Loreweaver'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // For now, we'll use a hardcoded storyId or create a new one.
                // In a real app, you'd fetch the user's stories.
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        const StoryScreen(storyId: 'test-story-123'),
                  ),
                );
              },
              child: const Text('Continue Story'),
            ),
          ],
        ),
      ),
    );
  }
}
