import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/user_profile.dart';
import '../detail_kebutuhan/detail_kebutuhan_screen.dart';
import '../auth/login_screen.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _phoneController = TextEditingController();

  Gender? _selectedGender;
  int _stressLevel = 3;
  ActivityLevel? _selectedActivityLevel;
  UserProfile? _profile;
  NutritionalNeeds? _calculatedNeeds;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final profile = UserProfile.dummyProfile;
    setState(() {
      _profile = profile;
      _ageController.text = profile.age?.toString() ?? '';
      _heightController.text = profile.height?.toString() ?? '';
      _weightController.text = profile.weight?.toString() ?? '';
      _phoneController.text = profile.phoneNumber ?? '';
      _selectedGender = profile.gender;
      _stressLevel = profile.stressLevel ?? 3;
      _selectedActivityLevel = profile.activityLevel;
      _calculatedNeeds = profile.nutritionalNeeds;
    });
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _calculateNeeds() {
    if (_formKey.currentState!.validate()) {
      final profile = UserProfile(
        age: int.tryParse(_ageController.text),
        gender: _selectedGender,
        height: double.tryParse(_heightController.text),
        weight: double.tryParse(_weightController.text),
        stressLevel: _stressLevel,
        activityLevel: _selectedActivityLevel,
      );

      if (profile.age == null ||
          profile.gender == null ||
          profile.height == null ||
          profile.weight == null ||
          profile.activityLevel == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lengkapi semua data dulu ya bestie!')),
        );
        return;
      }

      setState(() {
        _calculatedNeeds = NutritionalNeeds.calculate(profile);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sip! Kebutuhan gizi udah dihitung!'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    }
  }

  void _saveProfile() {
    if (_calculatedNeeds == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hitung dulu dong bestie!')),
      );
      return;
    }

    // Simulate save
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profil berhasil disimpan! Mantul!'),
        backgroundColor: AppTheme.successGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLightOrange,
      appBar: AppBar(
        title: const Text('Profil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile header
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                       Image.asset(
                        'assets/images/intip_rb.png',
                        height: 130,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _profile?.name ?? 'Sobat Sehat',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            Text(
                              _profile?.email ?? 'email@example.com',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Profil Kamu Nih Bestie!',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.primaryOrange,
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Form fields
              Text(
                'Data Diri',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),

              // Phone Number
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Nomor HP',
                  hintText: '08xxxxxxxxxx',
                  prefixIcon: const Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 16),

              // Age
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Umur',
                  hintText: 'Berapa tahun nih?',
                  prefixIcon: const Icon(Icons.cake_outlined),
                  suffixText: 'tahun',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Isi dulu umurnya bestie';
                  }
                  final age = int.tryParse(value);
                  if (age == null || age < 10 || age > 100) {
                    return 'Umur harus antara 10-100 tahun';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Gender
              Text(
                'Jenis Kelamin',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Text(
                        'Laki-laki',
                        style: TextStyle(
                          color: _selectedGender == Gender.male
                              ? Colors.white
                              : AppTheme.textDark,
                        ),
                      ),
                      selected: _selectedGender == Gender.male,
                      selectedColor: AppTheme.primaryOrange,
                      onSelected: (selected) {
                        setState(() {
                          _selectedGender = selected ? Gender.male : null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: Text(
                        'Perempuan',
                        style: TextStyle(
                          color: _selectedGender == Gender.female
                              ? Colors.white
                              : AppTheme.textDark,
                        ),
                      ),
                      selected: _selectedGender == Gender.female,
                      selectedColor: AppTheme.primaryOrange,
                      onSelected: (selected) {
                        setState(() {
                          _selectedGender = selected ? Gender.female : null;
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Height
              TextFormField(
                controller: _heightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Tinggi Badan',
                  hintText: 'Tinggi kamu berapa?',
                  prefixIcon: const Icon(Icons.height_outlined),
                  suffixText: 'cm',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Isi tinggi badan dong';
                  }
                  final height = double.tryParse(value);
                  if (height == null || height < 100 || height > 250) {
                    return 'Yang bener dong isinya';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Weight
              TextFormField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Berat Badan',
                  hintText: 'Berat badan?',
                  prefixIcon: const Icon(Icons.monitor_weight_outlined),
                  suffixText: 'kg',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Isi berat badan ya';
                  }
                  final weight = double.tryParse(value);
                  if (weight == null || weight < 30 || weight > 200) {
                    return 'Yang bener dong isinya';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Stress level
              Text(
                'Level Stres (1-5)',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '1',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Expanded(
                    child: Slider(
                      value: _stressLevel.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: _stressLevel.toString(),
                      onChanged: (value) {
                        setState(() {
                          _stressLevel = value.toInt();
                        });
                      },
                    ),
                  ),
                  Text(
                    '5',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              Center(
                child: Text(
                  'Level: $_stressLevel',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primaryOrange,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),

              const SizedBox(height: 16),

              // Activity level
              Text(
                'Tingkat Aktivitas',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(
                      'Rendah',
                      style: TextStyle(
                        color: _selectedActivityLevel == ActivityLevel.low
                            ? Colors.white
                            : AppTheme.textDark,
                      ),
                    ),
                    selected: _selectedActivityLevel == ActivityLevel.low,
                    selectedColor: AppTheme.primaryOrange,
                    onSelected: (selected) {
                      setState(() {
                        _selectedActivityLevel =
                            selected ? ActivityLevel.low : null;
                      });
                    },
                  ),
                  ChoiceChip(
                    label: Text(
                      'Sedang',
                      style: TextStyle(
                        color: _selectedActivityLevel == ActivityLevel.medium
                            ? Colors.white
                            : AppTheme.textDark,
                      ),
                    ),
                    selected: _selectedActivityLevel == ActivityLevel.medium,
                    selectedColor: AppTheme.primaryOrange,
                    onSelected: (selected) {
                      setState(() {
                        _selectedActivityLevel =
                            selected ? ActivityLevel.medium : null;
                      });
                    },
                  ),
                  ChoiceChip(
                    label: Text(
                      'Tinggi',
                      style: TextStyle(
                        color: _selectedActivityLevel == ActivityLevel.high
                            ? Colors.white
                            : AppTheme.textDark,
                      ),
                    ),
                    selected: _selectedActivityLevel == ActivityLevel.high,
                    selectedColor: AppTheme.primaryOrange,
                    onSelected: (selected) {
                      setState(() {
                        _selectedActivityLevel =
                            selected ? ActivityLevel.high : null;
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Calculate button
              ElevatedButton.icon(
                onPressed: _calculateNeeds,
                icon: const Icon(Icons.calculate),
                label: const Text('Hitung Kebutuhan Gizi'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),

              // Results
              if (_calculatedNeeds != null) ...[
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hasil Kebutuhan Gizi',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 16),
                        _buildNutrientRow('Kalori', '${_calculatedNeeds!.calories.toInt()} kcal'),
                        _buildNutrientRow('Protein', '${_calculatedNeeds!.protein.toInt()} g'),
                        _buildNutrientRow('Karbohidrat', '${_calculatedNeeds!.carbs.toInt()} g'),
                        _buildNutrientRow('Lemak', '${_calculatedNeeds!.fat.toInt()} g'),
                        _buildNutrientRow('Serat', '${_calculatedNeeds!.fiber.toInt()} g'),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const DetailKebutuhanScreen(),
                              ),
                            );
                          },
                          child: const Text('Lihat Detail'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Save button
              ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGold,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Simpan Profil'),
              ),

              const SizedBox(height: 16),

              // Logout Button
              OutlinedButton.icon(
                onPressed: () {
                  // Navigate to Login Screen and remove all previous routes
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorRed,
                  side: const BorderSide(color: AppTheme.errorRed),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Keluar'),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutrientRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.primaryOrange,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
