import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/user_profile.dart';
import '../detail_kebutuhan/detail_kebutuhan_screen.dart';
import '../auth/login_screen.dart';

import '../../services/profile_service.dart';
import '../../services/recommendation_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _birthDateController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _phoneController = TextEditingController();

  DateTime? _selectedBirthDate;
  Gender? _selectedGender;
  int _stressLevel = 3;
  ActivityLevel? _selectedActivityLevel;
  UserProfile? _profile;
  NutritionalNeeds? _calculatedNeeds;

  final ProfileService _profileService = ProfileService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final profile = await _profileService.getUserProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
        if (profile != null) {
          _selectedBirthDate = profile.birthDate;
          if (profile.birthDate != null) {
             _birthDateController.text = "${profile.birthDate!.day}/${profile.birthDate!.month}/${profile.birthDate!.year}";
          }
          _heightController.text = profile.height?.toString() ?? '';
          _weightController.text = profile.weight?.toString() ?? '';
          _phoneController.text = profile.phoneNumber ?? '';
          _selectedGender = profile.gender;
          _stressLevel = profile.stressLevel ?? 3;
          _selectedActivityLevel = profile.activityLevel;
          
          if (profile.isComplete) {
             _calculatedNeeds =  NutritionalNeeds.calculate(profile);
          }
        }
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _birthDateController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
        _birthDateController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  void _calculateNeeds() {
    if (_formKey.currentState!.validate()) {
      final profile = UserProfile(
        birthDate: _selectedBirthDate,
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

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
       setState(() => _isLoading = true);
       try {
          final updatedProfile = UserProfile(
            name: _profile?.name,
            email: _profile?.email,
            phoneNumber: _phoneController.text,
            birthDate: _selectedBirthDate,
            gender: _selectedGender,
            height: double.tryParse(_heightController.text),
            weight: double.tryParse(_weightController.text),
            stressLevel: _stressLevel,
            activityLevel: _selectedActivityLevel,
          );

          await _profileService.updateProfile(updatedProfile);
          
          await RecommendationService().generateDailyRecommendations(updatedProfile);
          
          if (mounted) {
             await _loadProfile();
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profil berhasil disimpan! Mantul!'),
                backgroundColor: AppTheme.successGreen,
              ),
            );
          }
       } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal simpan: $e'), backgroundColor: AppTheme.errorRed),
            );
          }
       } finally {
         if (mounted) setState(() => _isLoading = false);
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate age for display
    int? displayAge;
    if (_selectedBirthDate != null) {
      final now = DateTime.now();
      displayAge = now.year - _selectedBirthDate!.year;
      if (now.month < _selectedBirthDate!.month || (now.month == _selectedBirthDate!.month && now.day < _selectedBirthDate!.day)) {
        displayAge--;
      }
    }

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

              // Birth Date Input
              InkWell(
                onTap: () => _selectDate(context),
                child: IgnorePointer(
                  child: TextFormField(
                    controller: _birthDateController,
                    decoration: InputDecoration(
                      labelText: 'Tanggal Lahir',
                      hintText: 'Pilih Tanggal Lahir',
                      prefixIcon: const Icon(Icons.calendar_today),
                      suffixText: displayAge != null ? '$displayAge tahun' : '',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Kapan kamu lahir?';
                      }
                      return null;
                    },
                  ),
                ),
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
                icon: const Icon(Icons.calculate, color: Colors.white),
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
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                  try {
                    await GoogleSignIn().signOut();
                  } catch (_) {} // Ignore if not signed in via Google
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
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
