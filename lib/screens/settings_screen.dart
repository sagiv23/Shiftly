import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _thresholdController;
  late TextEditingController _durationController;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _thresholdController = TextEditingController(
      text: settings.breakThresholdHours.toString(),
    );
    _durationController = TextEditingController(
      text: settings.breakDurationMinutes.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'הגדרות',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader('ערכת נושא'),
          const SizedBox(height: 12),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('מערכת'),
                icon: Icon(Icons.brightness_auto_rounded),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('יום'),
                icon: Icon(Icons.light_mode_rounded),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('לילה'),
                icon: Icon(Icons.dark_mode_rounded),
              ),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (val) => settings.setThemeMode(val.first),
          ),
          const SizedBox(height: 40),
          _buildSectionHeader('כללי הפסקה אוטומטיים'),
          Text(
            'המערכת תחסיר זמן הפסקה באופן אוטומטי אם משך המשמרת עולה על הסף שנקבע.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _thresholdController,
                    decoration: const InputDecoration(
                      labelText: 'סף שעות להפסקה',
                      prefixIcon: Icon(Icons.timer_outlined),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      labelText: 'זמן הפסקה להחסרה (דקות)',
                      prefixIcon: Icon(Icons.coffee_outlined),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              final threshold =
                  double.tryParse(_thresholdController.text) ?? 9.0;
              final duration =
                  double.tryParse(_durationController.text) ?? 45.0;
              settings.setBreakRules(threshold, duration);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('ההגדרות נשמרו בהצלחה'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.save_rounded),
            label: const Text('שמור הגדרות'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
