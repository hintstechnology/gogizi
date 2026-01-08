import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../home/home_screen.dart';
import '../scan/scan_screen.dart';
import '../rekomendasi/rekomendasi_screen.dart';
import '../riwayat/riwayat_screen.dart';
import '../challenge/challenge_screen.dart';
import '../profil/profil_screen.dart';

import 'package:showcaseview/showcaseview.dart';
import '../../services/profile_service.dart' as import_profile_service;

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // Keys for Navbar Showcase
  final GlobalKey _keyHomeNav = GlobalKey();
  final GlobalKey _keyScanNav = GlobalKey();
  final GlobalKey _keyRekomNav = GlobalKey();
  final GlobalKey _keyHistoryNav = GlobalKey();
  final GlobalKey _keyChallengeNav = GlobalKey();
  final GlobalKey _keyProfileNav = GlobalKey();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(
        extraKeys: [
          _keyHomeNav,
          _keyScanNav,
          _keyRekomNav,
          _keyHistoryNav,
          _keyChallengeNav,
          _keyProfileNav
        ],
      ),
      const ScanScreen(),
      const RekomendasiScreen(),
      const RiwayatScreen(),
      const ChallengeScreen(),
      const ProfilScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      builder: (context) => Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) async {
          // Allow navigation to Home (0) and Profile (5) without check
          // to prevent getting stuck if fetch fails.
          if (index == 0 || index == 5) {
            setState(() {
              _currentIndex = index;
            });
            return;
          }

          // Check profile completeness for key features (Scan, Rekomendasi, etc)
          // Showing loading indicator could be nice here, but snackbar sufficient for guard.
          final profile = await import_profile_service.ProfileService().getUserProfile();
          
          if (profile == null || !profile.isComplete) {
             if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Eits, lengkapi data profil dulu ya bestie!')),
               );
               // Redirect to Profile tab
               setState(() {
                 _currentIndex = 5; 
               });
             }
          } else {
             if (mounted) {
               setState(() {
                 _currentIndex = index;
               });
             }
          }
        },
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: Showcase(
              key: _keyHomeNav,
              title: 'Beranda',
              description: 'Balik ke halaman utama kapan aja.',
              child: const Icon(Icons.home),
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Showcase(
              key: _keyScanNav,
              title: 'Scan',
              description: 'Jalan pintas buat scan makananmu!',
              child: const Icon(Icons.qr_code_scanner_outlined),
            ),
            activeIcon: const Icon(Icons.qr_code_scanner),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Showcase(
              key: _keyRekomNav,
              title: 'Menu Sehat',
              description: 'Cari rekomendasi makanan sehat di sini.',
              child: const Icon(Icons.restaurant_menu_outlined),
            ),
            activeIcon: const Icon(Icons.restaurant_menu),
            label: 'Rekomendasi',
          ),
          BottomNavigationBarItem(
            icon: Showcase(
              key: _keyHistoryNav,
              title: 'Riwayat',
              description: 'Cek lagi apa aja yang udah kamu makan.',
              child: const Icon(Icons.history_outlined),
            ),
            activeIcon: const Icon(Icons.history),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Showcase(
              key: _keyChallengeNav,
              title: 'Tantangan',
              description: 'Liat progres tantangan mingguanmu.',
              child: const Icon(Icons.emoji_events_outlined),
            ),
            activeIcon: const Icon(Icons.emoji_events),
            label: 'Tantangan',
          ),
          BottomNavigationBarItem(
            icon: Showcase(
              key: _keyProfileNav,
              title: 'Profil Kamu',
              description: 'Atur data diri dan preferensimu di sini.',
              child: const Icon(Icons.person_outline),
            ),
            activeIcon: const Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    ),
    );
  }
}

