import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shiftly/providers/settings_provider.dart';
import 'package:shiftly/providers/shift_provider.dart';
import 'package:shiftly/theme/app_theme.dart';

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
          AppTheme.spaceSm,
          AppTheme.spaceSm,
          AppTheme.spaceSm,
          100,
        ),
        children: [
          _buildSectionHeader(context, 'ערכת נושא'),
          const SizedBox(height: AppTheme.spaceXs),
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
          const SizedBox(height: AppTheme.spaceLg),
          _buildSectionHeader(context, 'תזכורות'),
          const SizedBox(height: AppTheme.spaceXs),
          Card(
            child: SwitchListTile(
              title: const Text('התראות'),
              subtitle: const Text('אפשר שליחת התראות מהאפליקציה'),
              secondary: Icon(
                Icons.notifications_active_outlined,
                color: AppTheme.primaryDark,
              ),
              value: settings.shiftRemindersEnabled,
              onChanged: (val) async {
                await settings.setShiftRemindersEnabled(val);
                if (!context.mounted) return;
                context.read<ShiftProvider>().refreshAllReminders();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: 0.2,
      ),
    );
  }
}
