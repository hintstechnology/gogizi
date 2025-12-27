import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../theme/app_theme.dart';
import '../../models/daily_history.dart';
import '../../models/scan_result.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  final List<DailyHistory> _history = DailyHistory.dummyHistory;
  String _selectedFilter = 'Semua';

  final List<String> _filters = [
    'Semua',
    'Makanan',
    'Minuman',
    'Minuman Manis',
  ];

  List<ScanResult> get _allScans {
    return _history.expand((day) => day.scanResults).toList();
  }

  List<ScanResult> get _filteredScans {
    switch (_selectedFilter) {
      case 'Makanan':
        return _allScans.where((s) => s.category == FoodCategory.food).toList();
      case 'Minuman':
        return _allScans
            .where((s) => s.category == FoodCategory.drink ||
                s.category == FoodCategory.sweetDrink)
            .toList();
      case 'Minuman Manis':
        return _allScans.where((s) => s.isSweetDrink).toList();
      default:
        return _allScans;
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupedHistory = <DateTime, List<ScanResult>>{};
    for (var scan in _filteredScans) {
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

    return Scaffold(
      backgroundColor: AppTheme.backgroundLightOrange,
      appBar: AppBar(
        title: const Text('Riwayat'),
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // History list
          Expanded(
            child: groupedHistory.isEmpty
                ? Center(
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
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: groupedHistory.length,
                    itemBuilder: (context, index) {
                      final entry = groupedHistory.entries.toList()[index];
                      final date = entry.key;
                      final scans = entry.value;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ExpansionTile(
                          leading: Icon(
                            Icons.calendar_today,
                            color: AppTheme.primaryOrange,
                          ),
                          title: Text(
                            DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date),
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          subtitle: Text(
                            '${scans.length} item',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          children: scans.map((scan) => _buildScanItem(scan)).toList(),
                        ),
                      );
                    },
                  ),
          ),
        ],
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
            _buildDetailRow('Gula', '${scan.nutritionalInfo.sugar.toInt()} g'),
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

