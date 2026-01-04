import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/user_profile.dart'; // Reusing existing model structure
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // Mock data for the admin dashboard
  final List<UserProfile> _registeredUsers = [
    UserProfile(
      id: 'u001',
      name: 'Budi Santoso',
      email: 'budi.santoso@mhs.university.ac.id',
      age: 21,
      gender: Gender.male,
      height: 172,
      weight: 68,
      activityLevel: ActivityLevel.medium,
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
      phoneNumber: '081234567801',
    ),
    UserProfile(
      id: 'u002',
      name: 'Siti Aminah',
      email: 'siti.aminah@mhs.university.ac.id',
      age: 20,
      gender: Gender.female,
      height: 160,
      weight: 52,
      activityLevel: ActivityLevel.low,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      phoneNumber: '081234567802',
    ),
    UserProfile(
      id: 'u003',
      name: 'Rizky Pratama',
      email: 'rizky.p@mhs.university.ac.id',
      age: 22,
      gender: Gender.male,
      height: 178,
      weight: 85,
      activityLevel: ActivityLevel.high,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      phoneNumber: '081234567803',
    ),
    UserProfile(
      id: 'u004',
      name: 'Dewi Lestari',
      email: 'dewi.lestari@mhs.university.ac.id',
      age: 19,
      gender: Gender.female,
      height: 158,
      weight: 48,
      activityLevel: ActivityLevel.medium,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      phoneNumber: '081234567804',
    ),
     UserProfile(
      id: 'u005',
      name: 'Ahmad Faisal',
      email: 'ahmad.faisal@mhs.university.ac.id',
      age: 23,
      gender: Gender.male,
      height: 165,
      weight: 70,
      activityLevel: ActivityLevel.low,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      phoneNumber: '081234567805',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryOrange,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryOrange,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Validasi logout simpel
              Navigator.of(context).pushReplacementNamed('/'); 
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCards(),
            const SizedBox(height: 24),
            Text(
              'Daftar Anak Muda Terdaftar',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildUserList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildCard(
            title: 'Total Pengguna',
            value: _registeredUsers.length.toString(),
            icon: Icons.people,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildCard(
            title: 'Aktif Hari Ini',
            value: '3', // Dummy
            icon: Icons.access_time,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _registeredUsers.length,
      itemBuilder: (context, index) {
        final user = _registeredUsers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryOrange.withOpacity(0.1),
              child: Text(
                user.name?[0] ?? '?',
                style: TextStyle(color: AppTheme.primaryOrange),
              ),
            ),
            title: Text(user.name ?? 'Unknown'),
            subtitle: Text(user.email ?? '-'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserDetailScreen(user: user),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class UserDetailScreen extends StatelessWidget {
  final UserProfile user;

  const UserDetailScreen({super.key, required this.user});

  double _calculateBMI() {
    if (user.height == null || user.weight == null) return 0;
    final heightInMeters = user.height! / 100;
    return user.weight! / (heightInMeters * heightInMeters);
  }

  String _getBMIStatus(double bmi) {
    if (bmi < 18.5) return 'Kurang';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Berlebih';
    return 'Obesitas';
  }

  @override
  Widget build(BuildContext context) {
    final bmi = _calculateBMI();
    final bmiStatus = _getBMIStatus(bmi);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(user.name ?? 'Detail User'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryOrange,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryOrange,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.primaryOrange.withOpacity(0.2),
                    child: Text(
                      user.name?[0] ?? '?',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryOrange,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.name ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user.email ?? '-',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  if (user.phoneNumber != null)
                    Text(
                      user.phoneNumber!,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  Text(
                    'Bergabung sejak: ${DateFormat('d MMM yyyy').format(user.createdAt ?? DateTime.now())}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Stats Grid
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    'Berat',
                    '${user.weight} kg',
                    Icons.monitor_weight_outlined,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCard(
                    'Tinggi',
                    '${user.height} cm',
                    Icons.height,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
             Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    'BMI',
                    bmi.toStringAsFixed(1),
                    Icons.accessibility_new,
                    _getBMIColor(bmi),
                    subtitle: bmiStatus,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCard(
                    'Aktivitas',
                    user.activityLevel.toString().split('.').last.toUpperCase(),
                    Icons.directions_run,
                    Colors.purple,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            
            // Achievements / Progress Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pencapaian & Monitoring',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildAchievementRow(
                    'Konsistensi Tracking',
                    0.8,
                    '80%',
                    'Sangat Baik',
                  ),
                  const SizedBox(height: 16),
                  _buildAchievementRow(
                    'Kepatuhan Kalori',
                    0.65,
                    '65%',
                    'Perlu ditingkatkan',
                  ),
                  const SizedBox(height: 16),
                  _buildAchievementRow(
                    'Asupan Air',
                    0.9,
                    '90%',
                    'Excellent',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return Colors.blue; 
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color color, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
             subtitle ?? label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementRow(String label, double progress, String progressText, String status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(status, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[200],
          color: AppTheme.primaryOrange,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
