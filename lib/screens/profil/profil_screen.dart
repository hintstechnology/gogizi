import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/user_profile.dart';
import '../detail_kebutuhan/detail_kebutuhan_screen.dart';

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
          const SnackBar(content: Text('Lengkapi semua data terlebih dahulu')),
        );
        return;
      }

      setState(() {
        _calculatedNeeds = NutritionalNeeds.calculate(profile);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kebutuhan gizi berhasil dihitung'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    }
  }

  void _saveProfile() {
    if (_calculatedNeeds == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hitung kebutuhan gizi terlebih dahulu')),
      );
      return;
    }

    // Simulate save
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profil berhasil disimpan'),
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
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppTheme.primaryOrange.withOpacity(0.2),
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: AppTheme.primaryOrange,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _profile?.name ?? 'Pengguna',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text(
                        _profile?.email ?? 'email@example.com',
                        style: Theme.of(context).textTheme.bodyMedium,
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

              // Age
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Umur',
                  hintText: 'Masukkan umur',
                  prefixIcon: Icon(Icons.cake_outlined),
                  suffixText: 'tahun',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Umur tidak boleh kosong';
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
                      label: const Text('Laki-laki'),
                      selected: _selectedGender == Gender.male,
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
                      label: const Text('Perempuan'),
                      selected: _selectedGender == Gender.female,
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
                  hintText: 'Masukkan tinggi badan',
                  prefixIcon: Icon(Icons.height_outlined),
                  suffixText: 'cm',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Tinggi badan tidak boleh kosong';
                  }
                  final height = double.tryParse(value);
                  if (height == null || height < 100 || height > 250) {
                    return 'Tinggi badan harus antara 100-250 cm';
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
                  hintText: 'Masukkan berat badan',
                  prefixIcon: Icon(Icons.monitor_weight_outlined),
                  suffixText: 'kg',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Berat badan tidak boleh kosong';
                  }
                  final weight = double.tryParse(value);
                  if (weight == null || weight < 30 || weight > 200) {
                    return 'Berat badan harus antara 30-200 kg';
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
                    label: const Text('Rendah'),
                    selected: _selectedActivityLevel == ActivityLevel.low,
                    onSelected: (selected) {
                      setState(() {
                        _selectedActivityLevel =
                            selected ? ActivityLevel.low : null;
                      });
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Sedang'),
                    selected: _selectedActivityLevel == ActivityLevel.medium,
                    onSelected: (selected) {
                      setState(() {
                        _selectedActivityLevel =
                            selected ? ActivityLevel.medium : null;
                      });
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Tinggi'),
                    selected: _selectedActivityLevel == ActivityLevel.high,
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
                  backgroundColor: AppTheme.successGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Simpan Profil'),
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

