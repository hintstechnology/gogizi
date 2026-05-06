import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  
  // 1. Initialize Supabase (CRITICAL: Must be first and hardcoded for safety)
  try {
    await Supabase.initialize(
      url: 'https://rrqqaflkcntczqmwpbxf.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJycXFhZmxrY250Y3pxbXdwYnhmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjcwNDc5MjUsImV4cCI6MjA4MjYyMzkyNX0.8BL107ILh4yTzyZxqtUx9BJ0jggahdTD5jCE6XrvNwE',
    );
    debugPrint("Supabase initialized successfully.");
  } catch (e) {
    debugPrint("CRITICAL: Supabase Initialization Failed: $e");
  }

  // 2. Load Env (Secondary)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: Dotenv load failed: $e");
    // Proceed anyway as we hardcoded critical keys
  }

  runApp(const GoGiziApp());
}

class GoGiziApp extends StatelessWidget {
  const GoGiziApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GiziGo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    await Future.delayed(const Duration(seconds: 3)); 
    
    if (!mounted) return;

    bool onboardingCompleted = false;
    bool isLoggedIn = false;

    try {
      final prefs = await SharedPreferences.getInstance();
      onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
      
      try {
        // Check Supabase Session safely
        final session = Supabase.instance.client.auth.currentSession;
        isLoggedIn = session != null;
      } catch (e) {
        debugPrint("Supabase check failed: $e");
        // Treat as not logged in if Supabase fails (e.g. not initialized)
        isLoggedIn = false;
      }
    } catch (e) {
      debugPrint("Pre-check failed: $e");
      // Fallback defaults
    }

    if (!mounted) return;

    if (!onboardingCompleted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    } else if (!isLoggedIn) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLightOrange,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Main App Logo
            Image.asset(
              'assets/images/splash_shortcut.png',
              width: 200, // Slightly larger for splash
              height: 200,
            ),
            const SizedBox(height: 24),
            Text(
              'GiziGo',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppTheme.primaryOrange,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pantau Gizi, Hidup Makin Hepi!',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
            const Spacer(),
            
            // Supported By Section
            Text(
              'Didukung oleh:',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // UB Logo
                Image.asset(
                  'assets/images/ub_logo.png',
                  height: 50,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.school, size: 50, color: Colors.grey),
                ),
                const SizedBox(width: 24),
                // AI Center Logo
                Image.asset(
                  'assets/images/ai_center_logo.png',
                  height: 50,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.computer, size: 50, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Funded by AI Grant 2025 Universitas Brawijaya',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
