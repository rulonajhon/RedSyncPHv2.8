import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hemophilia_manager/screens/main_screen/healthcare_provider_screen/healthcare_dashboard.dart';
import 'package:hemophilia_manager/screens/main_screen/healthcare_provider_screen/healthcare_patients_list.dart';
import 'package:hemophilia_manager/screens/main_screen/healthcare_provider_screen/healthcare_messages_screen.dart';

class HealthcareMainScreen extends StatefulWidget {
  const HealthcareMainScreen({super.key});

  @override
  State<HealthcareMainScreen> createState() => _HealthcareMainScreenState();
}

class _HealthcareMainScreenState extends State<HealthcareMainScreen> {
  int _currentIndex = 0;

  // BOTTOM NAVIGATION BAR ICONS
  final iconList = <IconData>[
    Icons.dashboard,
    FontAwesomeIcons.peopleGroup,
    FontAwesomeIcons.message,
  ];

  // LIST OF DISPLAYED SCREENS
  final List<Widget> _screens = [
    const HealthcareDashboard(),
    const HealthcarePatientsList(),
    const HealthcareMessagesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.exit_to_app,
                    color: Colors.redAccent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Exit App',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: const Text(
              'Are you sure you want to exit the app?',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Exit',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );

        if (shouldExit == true && context.mounted) {
          // Exit the app
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: _screens[_currentIndex],
        bottomNavigationBar: AnimatedBottomNavigationBar(
          icons: iconList,
          activeIndex: _currentIndex,
          notchSmoothness: NotchSmoothness.softEdge,
          activeColor: Colors.redAccent,
          inactiveColor: Colors.blueGrey,
          gapLocation: GapLocation.none,
          leftCornerRadius: 0,
          rightCornerRadius: 0,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }
}
