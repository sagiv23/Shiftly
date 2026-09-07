import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
        padding: const EdgeInsets.fromLTRB(
          20,
          20,
          20,
          100,
        ), // Added bottom padding
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
          const SizedBox(height: 32),
          _buildSectionHeader('תזכורות'),
          const SizedBox(height: 12),
          Card(
            child: SwitchListTile(
              title: const Text('תזכורת למשמרת'),
              subtitle: const Text('שלח התראה 4 שעות לפני תחילת המשמרת'),
              secondary: const Icon(Icons.notifications_active_outlined),
              value: settings.shiftRemindersEnabled,
              onChanged: (val) async {
                await settings.setShiftRemindersEnabled(val);
                if (mounted) {
                  context.read<ShiftProvider>().refreshAllReminders();
                }
              },
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
