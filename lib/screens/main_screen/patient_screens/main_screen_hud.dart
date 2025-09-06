import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hemophilia_manager/screens/main_screen/patient_screens/clinic_locator_screen.dart';
import 'package:hemophilia_manager/screens/main_screen/patient_screens/dashboard_screens.dart/dashboard_screen.dart';
import 'package:hemophilia_manager/screens/main_screen/patient_screens/educ_resources/educational_resources_screen.dart';
import 'package:hemophilia_manager/services/firestore.dart';
import 'package:hemophilia_manager/screens/main_screen/patient_screens/notifications_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hemophilia_manager/screens/main_screen/patient_screens/community/community_screen.dart';
import 'package:hemophilia_manager/widgets/offline_indicator.dart';
import 'package:hemophilia_manager/utils/connectivity_helper.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class MainScreenDisplay extends StatefulWidget {
  const MainScreenDisplay({super.key});

  @override
  State<MainScreenDisplay> createState() => _MainScreenDisplayState();
}

class _MainScreenDisplayState extends State<MainScreenDisplay> {
  int _currentIndex = 0;
  final FirestoreService _firestoreService = FirestoreService();
  final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _setupConnectivityListener();
  }

  void _checkConnectivity() async {
    final isOnline = await ConnectivityHelper.isOnline();
    setState(() {
      _isOnline = isOnline;
    });
  }

  void _setupConnectivityListener() {
    Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final isOnline =
          results.isNotEmpty && results.first != ConnectivityResult.none;
      setState(() {
        _isOnline = isOnline;
      });
    });
  }

  // BOTTOM NAVIGATION BAR ICONS - Now 6 icons
  final iconList = <IconData>[
    FontAwesomeIcons.house,
    FontAwesomeIcons.book,
    FontAwesomeIcons.robot,
    FontAwesomeIcons.houseChimneyMedical,
    FontAwesomeIcons.globe,
    FontAwesomeIcons.solidPaperPlane,
  ];

  // LIST OF DISPLAYED SCREENS - Updated for separate community screen
  final List<Widget> _screens = [
    const Dashboard(), // Index 0
    const EducationalResourcesScreen(), // Index 1
    Container(), // Index 2 - Placeholder for chatbot (opens separately)
    const ClinicLocatorScreen(), // Index 3
    Container(), // Index 4 - Placeholder for community (opens separately)
    Container(), // Index 5 - Placeholder for messages (opens separately)
  ];

  void _onBottomNavTap(int index) {
    // Check if trying to access online-only features while offline
    if (!_isOnline && (index == 2 || index == 3 || index == 4)) {
      _showOfflineDialog(index);
      return;
    }

    if (index == 2) {
      // Chatbot icon - open in separate screen
      Navigator.pushNamed(context, '/chatbot');
    } else if (index == 4) {
      // Community icon - open in separate screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CommunityScreen()),
      );
    } else if (index == 5) {
      // Messages icon - open in separate screen
      Navigator.pushNamed(context, '/messages');
    } else {
      // For other tabs, handle normally
      setState(() {
        _currentIndex = index;
      });
    }
  }

  void _showOfflineDialog(int index) {
    String featureName;
    IconData featureIcon;

    switch (index) {
      case 2:
        featureName = 'Chatbot';
        featureIcon = FontAwesomeIcons.robot;
        break;
      case 3:
        featureName = 'Care Locator';
        featureIcon = FontAwesomeIcons.houseChimneyMedical;
        break;
      case 4:
        featureName = 'Community';
        featureIcon = FontAwesomeIcons.globe;
        break;
      default:
        featureName = 'Feature';
        featureIcon = Icons.wifi_off;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.wifi_off,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Offline Mode',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                featureIcon,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                '$featureName requires an internet connection',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Please check your internet connection and try again.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.redAccent,
              ),
              child: const Text(
                'OK',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

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
        appBar: AppBar(
          toolbarHeight: 70,
          title: const Text(
            'RedSync PH',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.redAccent,
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(20),
            child: OfflineIndicator(),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: StreamBuilder<int>(
                stream: _firestoreService.getUnreadNotificationCount(uid),
                builder: (context, snapshot) {
                  final unreadCount = snapshot.data ?? 0;

                  return Stack(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.redAccent.withOpacity(0.1),
                        child: IconButton(
                          icon: const Icon(
                            FontAwesomeIcons.solidBell,
                            color: Colors.redAccent,
                            size: 18,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const NotificationsScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/settings');
                },
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey.shade200,
                  child: Icon(Icons.person, color: Colors.grey.shade600),
                ),
              ),
            ),
          ],
        ),
        body: _currentIndex == 2 || _currentIndex == 4 || _currentIndex == 5
            ? Container() // Empty container for chatbot, community, and messages placeholders
            : _screens[_currentIndex],
        floatingActionButton: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(
              scale: animation,
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: _currentIndex == 3 // Hide FAB when on clinic locator (index 3)
              ? const SizedBox.shrink(key: ValueKey('hidden'))
              : FloatingActionButton(
                  key: const ValueKey('visible'),
                  heroTag: "main_screen_fab",
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      builder: (context) {
                        return SafeArea(
                          child: Container(
                            constraints: BoxConstraints(
                              maxHeight:
                                  MediaQuery.of(context).size.height * 0.85,
                            ),
                            padding: const EdgeInsets.all(20.0),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(24),
                              ),
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade400,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Quick Actions',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _ActionTile(
                                    label: 'Log New Bleed',
                                    icon: FontAwesomeIcons.droplet,
                                    bgColor: const Color(0xFFE57373),
                                    onTap: () {
                                      Navigator.pop(context);
                                      Navigator.pushNamed(
                                          context, '/log_bleed');
                                    },
                                  ),
                                  const SizedBox(height: 5),
                                  _ActionTile(
                                    label: 'Log New Infusion',
                                    icon: FontAwesomeIcons.syringe,
                                    bgColor: const Color(0xFFBA68C8),
                                    onTap: () {
                                      Navigator.pop(context);
                                      Navigator.pushNamed(
                                        context,
                                        '/log_infusion',
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 5),
                                  _ActionTile(
                                    label: 'Schedule Medication',
                                    icon: FontAwesomeIcons.pills,
                                    bgColor: const Color(0xFF64B5F6),
                                    onTap: () {
                                      Navigator.pop(context);
                                      Navigator.pushNamed(
                                        context,
                                        '/schedule_medication',
                                      ).then((_) {
                                        // After returning from schedule screen, refresh dashboard
                                        setState(() {}); // Triggers rebuild
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 5),
                                  _ActionTile(
                                    label: 'Dosage Calculator',
                                    icon: FontAwesomeIcons.calculator,
                                    bgColor: const Color(0xFF81C784),
                                    onTap: () {
                                      Navigator.pop(context);
                                      Navigator.pushNamed(
                                        context,
                                        '/dose_calculator',
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 5),
                                  _ActionTile(
                                    label: 'Log History',
                                    icon: FontAwesomeIcons.clockRotateLeft,
                                    bgColor: const Color(0xFFFFB74D),
                                    onTap: () {
                                      Navigator.pop(context);
                                      Navigator.pushNamed(
                                        context,
                                        '/log_history',
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 5),
                                  Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.redAccent,
                                        width: 1.5,
                                      ),
                                      color: Colors.white,
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 8,
                                      ),
                                      leading: const Icon(
                                        FontAwesomeIcons.plus,
                                        color: Colors.redAccent,
                                        size: 20,
                                      ),
                                      title: const Text(
                                        'Add Care Provider',
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 16,
                                        ),
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);
                                        Navigator.pushNamed(
                                          context,
                                          '/care_provider',
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  backgroundColor: Colors.redAccent,
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
        ),
        floatingActionButtonLocation:
            _currentIndex == 3 ? null : FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: SafeArea(
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(iconList.length, (index) {
                final isActive = _currentIndex == index;
                final isOnlineFeature = index == 2 ||
                    index == 3 ||
                    index == 4; // Chatbot, Care Locator, Community
                final isDisabled = isOnlineFeature && !_isOnline;

                return GestureDetector(
                  onTap: () => _onBottomNavTap(index),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.redAccent.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          children: [
                            Icon(
                              iconList[index],
                              color: isDisabled
                                  ? Colors.grey.shade400
                                  : (isActive
                                      ? Colors.redAccent
                                      : Colors.grey.shade600),
                              size: 20,
                            ),
                            if (isDisabled)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.orange,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDisabled
                                ? Colors.transparent
                                : (isActive
                                    ? Colors.redAccent
                                    : Colors.transparent),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

// Helper widget for list tiles
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color bgColor;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Icon(icon, color: Colors.white, size: 24),
        title: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        trailing:
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
        onTap: onTap,
      ),
    );
  }
}
