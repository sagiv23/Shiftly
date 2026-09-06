import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/job_type.dart';
import '../providers/settings_provider.dart';
import '../providers/shift_provider.dart';
import '../widgets/app_icon.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Break State
  late double _paidMinutes;
  late double _unpaidMinutes;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _paidMinutes = settings.paidBreakDurationMinutes;
    _unpaidMinutes = settings.unpaidBreakDurationMinutes;
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() async {
    final settings = context.read<SettingsProvider>();
    await settings.setBreakDurations(_paidMinutes, _unpaidMinutes);
    await settings.completeOnboarding();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildWelcomePage(),
                  _buildBreakSettingsPage(),
                  _buildJobTypesPage(),
                ],
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const EssentialWorkIcon(size: 120),
          const SizedBox(height: 40),
          const Text(
            'ברוכים הבאים ל-Shiftly',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              fontFamily: 'Arial',
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'האפליקציה שתעזור לך לעקוב אחרי המשמרות, השכר והטיפים שלך בקלות ובדיוק.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontFamily: 'Arial',
            ),
          ),
          const SizedBox(height: 40),
          const Text(
            'בוא נגדיר כמה דברים בסיסיים כדי להתחיל.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'Arial',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakSettingsPage() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.timer_outlined, size: 64, color: Colors.blue),
          const SizedBox(height: 24),
          const Text(
            'הגדרות הפסקה',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'Arial',
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'כמה זמן נמשכת הפסקה בדרך כלל? (ניתן לשנות בכל משמרת)',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontFamily: 'Arial',
            ),
          ),
          const SizedBox(height: 40),
          _buildDurationSlider(
            label: 'הפסקה בתשלום (דקות)',
            value: _paidMinutes,
            onChanged: (val) => setState(() => _paidMinutes = val),
          ),
          const SizedBox(height: 32),
          _buildDurationSlider(
            label: 'הפסקה ללא תשלום (דקות)',
            value: _unpaidMinutes,
            onChanged: (val) => setState(() => _unpaidMinutes = val),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Arial',
              ),
            ),
            Text(
              '${value.toInt()} דק\'',
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: 0,
          max: 120,
          divisions: 24,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildJobTypesPage() {
    final shiftProvider = context.watch<ShiftProvider>();
    final jobTypes = shiftProvider.jobTypes;

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.work_outline, size: 64, color: Colors.blue),
          const SizedBox(height: 24),
          const Text(
            'סוגי משמרות ושכר',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'Arial',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'הגדר את התפקידים השונים שלך ואת השכר לשעה.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontFamily: 'Arial',
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: jobTypes.length,
              itemBuilder: (context, index) {
                final job = jobTypes[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(
                      job.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '₪${job.hourlyRate.toStringAsFixed(2)} לשעה',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _editJobType(job),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            final provider = context.read<ShiftProvider>();
                            final name = job.name;
                            provider.deleteJobType(job.id);

                            final messenger = ScaffoldMessenger.of(context);
                            messenger.clearSnackBars();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('תפקיד "$name" נמחק'),
                                duration: const Duration(milliseconds: 4500),
                                behavior: SnackBarBehavior.floating,
                                action: SnackBarAction(
                                  label: 'ביטול',
                                  onPressed: () => provider.addJobType(job),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          TextButton.icon(
            onPressed: _addNewJobType,
            icon: const Icon(Icons.add),
            label: const Text('הוסף סוג משמרת'),
          ),
        ],
      ),
    );
  }

  void _editJobType(JobType job) {
    final nameController = TextEditingController(text: job.name);
    final rateController = TextEditingController(
      text: job.hourlyRate.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ערוך סוג משמרת'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'שם התפקיד'),
            ),
            TextField(
              controller: rateController,
              decoration: const InputDecoration(labelText: 'שכר לשעה'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () {
              final rate =
                  double.tryParse(rateController.text) ?? job.hourlyRate;
              context.read<ShiftProvider>().updateJobType(
                job.copyWith(name: nameController.text, hourlyRate: rate),
              );
              Navigator.pop(context);
            },
            child: const Text('שמור'),
          ),
        ],
      ),
    );
  }

  void _addNewJobType() {
    final nameController = TextEditingController();
    final rateController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('סוג משמרת חדש'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'שם התפקיד'),
            ),
            TextField(
              controller: rateController,
              decoration: const InputDecoration(labelText: 'שכר לשעה'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final rate = double.tryParse(rateController.text) ?? 0.0;
              final provider = context.read<ShiftProvider>();
              final messenger = ScaffoldMessenger.of(context);

              if (name.isEmpty) {
                messenger.clearSnackBars();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('נא להזין שם לתפקיד'),
                    duration: Duration(milliseconds: 4500),
                  ),
                );
                return;
              }

              final exists = provider.jobTypes.any(
                (j) => j.name.toLowerCase() == name.toLowerCase(),
              );

              if (exists) {
                messenger.clearSnackBars();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('תפקיד בשם זה כבר קיים'),
                    duration: Duration(milliseconds: 4500),
                  ),
                );
                return;
              }

              if (rate < 0) {
                messenger.clearSnackBars();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('השכר לא יכול להיות שלילי'),
                    duration: Duration(milliseconds: 4500),
                  ),
                );
                return;
              }
              provider.addJobType(
                JobType(id: const Uuid().v4(), name: name, hourlyRate: rate),
              );
              Navigator.pop(context);
            },
            child: const Text('הוסף'),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: List.generate(
              3,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index
                      ? Colors.blue
                      : Colors.grey.shade300,
                ),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _nextPage,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _currentPage == 2 ? 'בוא נתחיל!' : 'המשך',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Arial',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
