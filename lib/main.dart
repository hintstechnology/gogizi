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
  
  // Load Env
  await dotenv.load(fileName: ".env");
  
  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

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
    await Future.delayed(const Duration(seconds: 3)); // Increased duration slightly to view logos
    
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
    
    // Check Supabase Session
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session != null;

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
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
