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
      appBar: AppBar(title: const Text('הגדרות')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'ערכת נושא',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('מערכת'),
                icon: Icon(Icons.brightness_auto),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('יום'),
                icon: Icon(Icons.light_mode),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('לילה'),
                icon: Icon(Icons.dark_mode),
              ),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (val) => settings.setThemeMode(val.first),
          ),
          const SizedBox(height: 32),
          const Text(
            'כללי הפסקה אוטומטיים',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Text(
            'המערכת תחסיר זמן הפסקה באופן אוטומטי אם משך המשמרת עולה על הסף שנקבע.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _thresholdController,
            decoration: const InputDecoration(
              labelText: 'סף שעות להפסקה',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _durationController,
            decoration: const InputDecoration(
              labelText: 'זמן הפסקה להחסרה (דקות)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final threshold =
                  double.tryParse(_thresholdController.text) ?? 9.0;
              final duration =
                  double.tryParse(_durationController.text) ?? 45.0;
              settings.setBreakRules(threshold, duration);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('ההגדרות נשמרו')));
            },
            child: const Text('שמור הגדרות'),
          ),
        ],
      ),
    );
  }
}
