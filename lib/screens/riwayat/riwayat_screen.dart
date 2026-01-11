import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../models/scan_result.dart'; // Ensure this model exists and matches

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  final _supabase = Supabase.instance.client;

  Stream<List<ScanResult>> _getHistoryStream() {
    final user = _supabase.auth.currentUser;
    if (user == null) return Stream.value([]);

    return _supabase
        .from('food_logs')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('eaten_at', ascending: false)
        .map((data) => data.map((row) => _mapDbRowToScanResult(row)).toList());
  }

  ScanResult _mapDbRowToScanResult(Map<String, dynamic> row) {
    // Note: Some nutritional info might be missing if not saved to DB
    // We use safe defaults or 0.0
    final nutritionalInfo = NutritionalInfo(
      calories: (row['calories'] as num?)?.toDouble() ?? 0.0,
      protein: (row['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (row['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (row['fat'] as num?)?.toDouble() ?? 0.0,
      sugar: (row['sugar'] as num?)?.toDouble() ?? 0.0, 
      fiber: (row['fiber'] as num?)?.toDouble() ?? 0.0,
      sodium: (row['sodium'] as num?)?.toDouble() ?? 0.0,
    );

    final label = row['food_name'] ?? 'Unknown';

    // Infer category since we don't store 'is_sweet_drink' in DB anymore
    final isSweetDrink = label.toLowerCase().contains('teh') ||
        (label.toLowerCase().contains('air') && !label.toLowerCase().contains('air dan sejenisnya')) || // air is water
        label.toLowerCase().contains('minuman') ||
        label.toLowerCase().contains('thai') ||
        label.toLowerCase().contains('kopi') ||
        label.toLowerCase().contains('jus') ||
        label.toLowerCase().contains('boba');
        
    final category = isSweetDrink ? FoodCategory.sweetDrink : FoodCategory.food;

    // Re-generate analysis since we don't store it structure
    final riskAnalysis = ScanResult.analyzeRisks(nutritionalInfo);
    final alternatives = ScanResult.generateAlternatives(label, category);

    return ScanResult(
      id: row['id'].toString(),
      label: label,
      confidence: 1.0, 
      category: category,
      nutritionalInfo: nutritionalInfo,
      scannedAt: DateTime.parse(row['eaten_at']),
      imagePath: row['image_proof_url'],
      isSweetDrink: isSweetDrink,
      riskAnalysis: riskAnalysis,
      healthierAlternatives: alternatives,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLightOrange,
      appBar: AppBar(
        title: const Text('Riwayat'),
      ),
      body: StreamBuilder<List<ScanResult>>(
        stream: _getHistoryStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final scans = snapshot.data ?? [];

          if (scans.isEmpty) {
          if (scans.isEmpty) {
            return RefreshIndicator( // Allow refresh even if empty
               onRefresh: () async { setState(() {}); },
               child: SingleChildScrollView(
                 physics: const AlwaysScrollableScrollPhysics(), // Provide physics
                 child: SizedBox(
                   height: MediaQuery.of(context).size.height * 0.7, // Take up space
                   child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: AppTheme.textLight,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada riwayat scan',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppTheme.textLight,
                              ),
                        ),
                      ],
                    ),
                   ),
                 ),
               ),
            );
          }
          }

          // Group by date
          final groupedHistory = <DateTime, List<ScanResult>>{};
          for (var scan in scans) {
            final date = DateTime(
              scan.scannedAt.year,
              scan.scannedAt.month,
              scan.scannedAt.day,
            );
            if (!groupedHistory.containsKey(date)) {
              groupedHistory[date] = [];
            }
            groupedHistory[date]!.add(scan);
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groupedHistory.length,
              itemBuilder: (context, index) {
                final entry = groupedHistory.entries.toList()[index];
                final date = entry.key;
                final groupedScans = entry.value;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ExpansionTile(
                    initiallyExpanded: index == 0,
                    leading: Icon(
                      Icons.calendar_today,
                      color: AppTheme.primaryOrange,
                    ),
                    title: Text(
                      DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    subtitle: Text(
                      '${groupedScans.length} item',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    children: groupedScans.map((scan) => _buildScanItem(scan)).toList(),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildScanItem(ScanResult scan) {
    return ListTile(
      leading: scan.imagePath != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(scan.imagePath!),
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 50,
                    height: 50,
                    color: AppTheme.cardGray,
                    child: Icon(Icons.fastfood, color: AppTheme.textLight),
                  );
                },
              ),
            )
          : Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.cardGray,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.fastfood, color: AppTheme.textLight),
            ),
      title: Text(scan.label),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: scan.category == FoodCategory.food
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  scan.category == FoodCategory.food ? 'Makanan' : 'Minuman',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scan.category == FoodCategory.food
                            ? Colors.blue
                            : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              if (scan.isSweetDrink) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.warningRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Minuman Manis',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.warningRed,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${scan.nutritionalInfo.calories.toInt()} kcal • '
            '${DateFormat('HH:mm').format(scan.scannedAt)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      trailing: Icon(Icons.chevron_right, color: AppTheme.textLight),
      onTap: () {
        _showScanDetail(scan);
      },
    );
  }

  void _showScanDetail(ScanResult scan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              scan.label,
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 16),
            Text(
              'Informasi Gizi',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            _buildDetailRow('Kalori', '${scan.nutritionalInfo.calories.toInt()} kcal'),
            _buildDetailRow('Protein', '${scan.nutritionalInfo.protein.toInt()} g'),
            _buildDetailRow('Karbohidrat', '${scan.nutritionalInfo.carbs.toInt()} g'),
            _buildDetailRow('Lemak', '${scan.nutritionalInfo.fat.toInt()} g'),
            // Only show sugar/sodium if not 0 (since default is 0 and we might not have data)
            if (scan.nutritionalInfo.sugar > 0)
              _buildDetailRow('Gula', '${scan.nutritionalInfo.sugar.toInt()} g'),
            if (scan.nutritionalInfo.sodium > 0)  
              _buildDetailRow('Natrium', '${scan.nutritionalInfo.sodium.toInt()} mg'),
              
            const SizedBox(height: 16),
            Text(
              'Waktu Scan',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('EEEE, d MMMM yyyy HH:mm', 'id_ID').format(scan.scannedAt),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
             SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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

