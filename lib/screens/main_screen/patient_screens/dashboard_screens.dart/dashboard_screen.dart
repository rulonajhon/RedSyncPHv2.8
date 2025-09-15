import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hemophilia_manager/services/firestore.dart';
import 'package:hemophilia_manager/services/enhanced_medication_service.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with WidgetsBindingObserver {
  final FirestoreService _firestoreService = FirestoreService();
  final EnhancedMedicationService _medicationService =
      EnhancedMedicationService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String _userName = '';
  bool _isLoading = true;
  bool _isGuest = false;
  List<Map<String, dynamic>> _recentActivities = [];
  List<Map<String, dynamic>> _todaysReminders = [];
  int _monthlyActivitiesCount = 0;
  int _weeklyInfusionsCount = 0;
  int _weeklyBleedsCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
    _loadUserData();
    _refreshAllData();
  }

  /// Initialize all required services
  Future<void> _initializeServices() async {
    try {
      print('🔄 Initializing dashboard services...');
      await _medicationService.initialize();
      print('✅ Dashboard services initialized');
    } catch (e) {
      print('⚠️ Error initializing dashboard services: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // App came back to foreground, refresh data
      print('App resumed, refreshing dashboard data...');
      _refreshAllData();
    }
  }

  @override
  void didUpdateWidget(Dashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh data when the widget updates
    print('Dashboard widget updated, refreshing data...');
    _refreshAllData();
  }

  Future<void> _loadUserData() async {
    try {
      // Check if user is a guest
      final guestStatus = await _secureStorage.read(key: 'isGuest');
      setState(() {
        _isGuest = guestStatus == 'true';
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await _firestoreService.getUser(user.uid);
        if (userData != null) {
          setState(() {
            _userName = _isGuest ? 'Guest' : (userData['name'] ?? 'User');
          });
        } else {
          setState(() {
            _userName = _isGuest ? 'Guest' : 'User';
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _userName = 'User';
        _isGuest = false;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRecentActivities() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No user logged in');
        return;
      }

      print('Loading recent activities for user: ${user.uid}');

      // Load all data in parallel for better performance
      // Get more records to ensure we have enough for calculations and display
      // Use force refresh to ensure we get the latest data from server
      final results = await Future.wait([
        _firestoreService.getBleedLogs(user.uid, limit: 20, forceRefresh: true),
        _firestoreService.getDosageCalculationHistory(user.uid, limit: 20),
        _firestoreService.getInfusionLogs(user.uid),
      ]);

      final bleeds = results[0];
      final dosageHistory = results[1];
      final infusionLogs = results[2];

      print(
          'Loaded ${bleeds.length} bleeds, ${dosageHistory.length} calculations, ${infusionLogs.length} infusions');

      // Combine all activities and sort by timestamp
      List<Map<String, dynamic>> allActivities = [];

      // Add bleeds with activity type
      for (var bleed in bleeds) {
        allActivities.add({
          ...bleed,
          'activityType': 'bleed',
          'timestamp': _extractTimestamp(bleed['createdAt']),
        });
      }

      // Add dosage calculations as calculation activities
      for (var dosage in dosageHistory) {
        int timestamp = _extractTimestamp(dosage['createdAt']);
        if (timestamp == 0) {
          timestamp = dosage['timestamp'] ?? 0;
        }
        allActivities.add({
          ...dosage,
          'activityType': 'calculation',
          'timestamp': timestamp,
        });
      }

      // Add infusion logs as infusion activities
      for (var infusion in infusionLogs.take(5)) {
        allActivities.add({
          ...infusion,
          'activityType': 'infusion',
          'timestamp': _extractTimestamp(infusion['createdAt']),
        });
      }

      // Sort by timestamp (most recent first)
      allActivities.sort(
        (a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0),
      );

      // Take only the 5 most recent activities
      _recentActivities = allActivities.take(5).toList();

      print('=== RECENT ACTIVITIES DEBUG ===');
      print('Recent activities count: ${_recentActivities.length}');
      for (int i = 0; i < _recentActivities.length; i++) {
        final activity = _recentActivities[i];
        print(
            'Activity $i: ${activity['activityType']} - date: ${activity['date']} - timestamp: ${activity['timestamp']}');
      }
      print('=== END RECENT ACTIVITIES DEBUG ===');

      // Calculate counts efficiently using the same data
      _calculateCounts(bleeds, infusionLogs);

      setState(() {});
    } catch (e) {
      print('Error loading recent activities: $e');
    }
  }

  void _calculateCounts(
      List<Map<String, dynamic>> bleeds, List<Map<String, dynamic>> infusions) {
    final now = DateTime.now();

    print('=== CALCULATE COUNTS DEBUG ===');
    print('Total bleeds: ${bleeds.length}');
    print('Total infusions: ${infusions.length}');
    print('Current date: ${now.toString()}');

    // Calculate monthly activities (bleeds + infusions from current month)
    final currentMonthBleeds = bleeds.where((bleed) {
      try {
        // Try using createdAt timestamp first (more reliable)
        final createdAt = bleed['createdAt'];
        DateTime bleedDate;

        if (createdAt != null) {
          bleedDate = _timestampToDateTime(createdAt);
          print('Processing bleed with createdAt: $bleedDate');
        } else {
          // Fallback to date string with multiple format support
          final dateStr = bleed['date'] ?? '';
          print('Processing bleed date: "$dateStr" (fallback)');
          if (dateStr.isEmpty) {
            print('  -> Empty date string, skipping');
            return false;
          }
          bleedDate = _parseFlexibleDate(dateStr);
        }

        final isCurrentMonth =
            bleedDate.year == now.year && bleedDate.month == now.month;
        print(
            '  -> Parsed date: $bleedDate, Is current month: $isCurrentMonth');
        return isCurrentMonth;
      } catch (e) {
        print('  -> Error parsing date: $e');
        return false;
      }
    }).length;

    final currentMonthInfusions = infusions.where((infusion) {
      try {
        // Try using createdAt timestamp first (more reliable)
        final createdAt = infusion['createdAt'];
        DateTime infusionDate;

        if (createdAt != null) {
          infusionDate = _timestampToDateTime(createdAt);
        } else {
          // Fallback to date string with multiple format support
          final dateStr = infusion['date'] ?? '';
          if (dateStr.isEmpty) return false;
          infusionDate = _parseFlexibleDate(dateStr);
        }

        return infusionDate.year == now.year && infusionDate.month == now.month;
      } catch (e) {
        print('Error parsing infusion date: $e');
        return false;
      }
    }).length;

    // Calculate weekly infusions (infusions from current week)
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDate =
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    print('Week calculation - Start of week: $startOfWeekDate');

    final currentWeekInfusions = infusions.where((infusion) {
      try {
        // Try using createdAt timestamp first (more reliable)
        final createdAt = infusion['createdAt'];
        DateTime infusionDate;

        if (createdAt != null) {
          infusionDate = _timestampToDateTime(createdAt);
        } else {
          // Fallback to date string with multiple format support
          final dateStr = infusion['date'] ?? '';
          if (dateStr.isEmpty) return false;
          infusionDate = _parseFlexibleDate(dateStr);
        }

        return infusionDate
                .isAfter(startOfWeekDate.subtract(const Duration(days: 1))) &&
            infusionDate.isBefore(now.add(const Duration(days: 1)));
      } catch (e) {
        print('Error parsing infusion date for week: $e');
        return false;
      }
    }).length;

    // Calculate weekly bleeds (bleeds from current week)
    final currentWeekBleeds = bleeds.where((bleed) {
      try {
        // Try using createdAt timestamp first (more reliable)
        final createdAt = bleed['createdAt'];
        DateTime bleedDate;

        if (createdAt != null) {
          bleedDate = _timestampToDateTime(createdAt);
          print('Processing bleed for weekly count with createdAt: $bleedDate');
        } else {
          // Fallback to date string with multiple format support
          final dateStr = bleed['date'] ?? '';
          print('Processing bleed for weekly count: "$dateStr" (fallback)');
          if (dateStr.isEmpty) {
            print('  -> Empty date string for weekly, skipping');
            return false;
          }
          bleedDate = _parseFlexibleDate(dateStr);
        }

        final isCurrentWeek = bleedDate
                .isAfter(startOfWeekDate.subtract(const Duration(days: 1))) &&
            bleedDate.isBefore(now.add(const Duration(days: 1)));
        print('  -> Parsed date: $bleedDate, Is current week: $isCurrentWeek');
        return isCurrentWeek;
      } catch (e) {
        print('  -> Error parsing bleed date for week: $e');
        return false;
      }
    }).length;

    // Update counts
    _monthlyActivitiesCount = currentMonthBleeds + currentMonthInfusions;
    _weeklyInfusionsCount = currentWeekInfusions;
    _weeklyBleedsCount = currentWeekBleeds;

    print('FINAL COUNTS:');
    print(
        '  Monthly activities: $_monthlyActivitiesCount (bleeds: $currentMonthBleeds + infusions: $currentMonthInfusions)');
    print('  Weekly infusions: $_weeklyInfusionsCount');
    print('  Weekly bleeds: $_weeklyBleedsCount');
    print('=== END CALCULATE COUNTS DEBUG ===');
  }

  // Helper method to convert Firestore timestamp to DateTime
  DateTime _timestampToDateTime(dynamic timestamp) {
    if (timestamp == null) throw Exception('Timestamp is null');

    // If it's already a DateTime
    if (timestamp is DateTime) {
      return timestamp;
    }

    // If it's a Firestore Timestamp
    if (timestamp.runtimeType.toString() == 'Timestamp') {
      return (timestamp as dynamic).toDate();
    }

    // If it's milliseconds since epoch
    if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }

    throw Exception('Unknown timestamp type: ${timestamp.runtimeType}');
  }

  // Helper method to parse date strings in various formats
  DateTime _parseFlexibleDate(String dateStr) {
    if (dateStr.isEmpty) {
      throw Exception('Empty date string');
    }

    // Try common date formats
    final formats = [
      'yyyy-MM-dd', // 2025-08-15
      'MMM dd, yyyy', // Aug 15, 2025
      'MMM d, yyyy', // Aug 5, 2025
      'MMMM dd, yyyy', // August 15, 2025
      'MMMM d, yyyy', // August 5, 2025
      'dd/MM/yyyy', // 15/08/2025
      'MM/dd/yyyy', // 08/15/2025
      'dd-MM-yyyy', // 15-08-2025
      'MM-dd-yyyy', // 08-15-2025
    ];

    for (String format in formats) {
      try {
        return DateFormat(format).parse(dateStr);
      } catch (e) {
        // Continue to next format
      }
    }

    // If all formats fail, try the default DateTime.parse
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      throw Exception(
          'Unable to parse date: "$dateStr". Tried formats: ${formats.join(", ")}');
    }
  }

  Future<void> _loadTodaysReminders() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final reminders = await _medicationService.getTodaysReminders(
          user.uid,
        );

        setState(() {
          _todaysReminders = reminders;
        });
      }
    } catch (e) {
      print('Error loading today\'s reminders: $e');
    }
  }

  // Method to refresh all dashboard data - can be called from other screens
  Future<void> _refreshAllData() async {
    print('Refreshing all dashboard data...');
    await Future.wait([
      _loadRecentActivities(), // This now handles all counts efficiently
      _loadTodaysReminders(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final timeOfDay = _getTimeOfDay();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadUserData();
          await _refreshAllData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _getTimeIcon(),
                        color: Colors.redAccent,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$timeOfDay${_isLoading ? '!' : ', $_userName!'}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Here\'s your health summary for today',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Guest Mode Indicator
                if (_isGuest) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Guest Mode',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Data won\'t be saved. Create an account to track your health progress.',
                                style: TextStyle(
                                  color: Colors.blue.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(
                              context,
                              '/register',
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue.shade700,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Quick Stats Section
                _buildQuickStats(),
                const SizedBox(height: 32),

                // Reminders Section
                _buildSection(
                  title: 'Today\'s Reminders',
                  icon: FontAwesomeIcons.clock,
                  children: [
                    if (_todaysReminders.isEmpty)
                      _buildReminderItem(
                        icon: FontAwesomeIcons.calendar,
                        title: 'No Reminders',
                        subtitle: 'No medication reminders scheduled for today',
                        iconColor: Colors.grey,
                      )
                    else
                      ..._todaysReminders.map(
                        (reminder) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildSwipeableMedicationReminder(reminder),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 32),

                // Recent Activity Section
                _buildSection(
                  title: 'Recent Activity',
                  icon: FontAwesomeIcons.clockRotateLeft,
                  children: [
                    if (_recentActivities.isEmpty)
                      _buildEmptyState(
                        icon: FontAwesomeIcons.heart,
                        title: 'No recent activity',
                        subtitle: 'Your logged activities will appear here',
                      )
                    else
                      ..._recentActivities.map(
                        (activity) => Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: _buildActivityItem(
                            icon: _getActivityIcon(activity['activityType']),
                            title: _getActivityTitle(activity['activityType']),
                            subtitle: _getActivitySubtitle(activity),
                            time: _formatActivityTime(activity),
                            iconColor: _getActivityColor(
                              activity['activityType'],
                            ),
                            onTap: () => _showActivityDetails(activity),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(
                  height: 50,
                ), // Add extra spacing at bottom instead of FAB space
              ],
            ),
          ),
        ),
      ),
      // Removed debug floating action button for production release
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatContainer(
            icon: FontAwesomeIcons.droplet,
            value: '$_weeklyBleedsCount',
            label: 'Recent Bleeds',
            color: Colors.red,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatContainer(
            icon: FontAwesomeIcons.syringe,
            value: '$_weeklyInfusionsCount',
            label: 'Infusions This Week',
            color: Colors.purple,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatContainer(
            icon: FontAwesomeIcons.calendar,
            value: '$_monthlyActivitiesCount',
            label: 'Activities This Month',
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildStatContainer({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: Colors.grey.shade700),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildReminderItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    Widget content = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Text(
                time,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ],
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: content,
      );
    }

    return content;
  }

  void _showActivityDetails(Map<String, dynamic> activity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildActivityDetailsContent(activity),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityDetailsContent(Map<String, dynamic> activity) {
    final activityType = activity['activityType'];
    final iconColor = _getActivityColor(activityType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with close button
        Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _getActivityIcon(activityType),
                color: iconColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getActivityTitle(activityType),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatActivityTime(activity),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(
                Icons.close,
                color: Colors.grey.shade600,
              ),
              tooltip: 'Close',
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Details based on activity type
        if (activityType == 'bleed') ..._buildBleedDetails(activity),
        if (activityType == 'infusion') ..._buildInfusionDetails(activity),
        if (activityType == 'calculation')
          ..._buildCalculationDetails(activity),

        const SizedBox(height: 24),
      ],
    );
  }

  List<Widget> _buildBleedDetails(Map<String, dynamic> activity) {
    return [
      _buildDetailRow('Body Region', activity['bodyRegion'] ?? 'Not specified'),
      if (activity['specificRegion'] != null &&
          activity['specificRegion'].toString().isNotEmpty)
        _buildDetailRow('Specific Area', activity['specificRegion']),
      _buildDetailRow('Severity', activity['severity'] ?? 'Not specified'),
      _buildDetailRow('Date', activity['date'] ?? 'Not specified'),
      if (activity['time'] != null && activity['time'].toString().isNotEmpty)
        _buildDetailRow('Time', activity['time']),
      if (activity['notes'] != null && activity['notes'].toString().isNotEmpty)
        _buildDetailRow('Notes', activity['notes']),
      // Legacy fields for backward compatibility
      if (activity['treatment'] != null &&
          activity['treatment'].toString().isNotEmpty)
        _buildDetailRow('Treatment', activity['treatment']),
      if (activity['factor'] != null)
        _buildDetailRow('Factor Type', activity['factor']),
    ];
  }

  List<Widget> _buildInfusionDetails(Map<String, dynamic> activity) {
    return [
      _buildDetailRow('Medication', activity['medication'] ?? 'Not specified'),
      _buildDetailRow(
          'Dose',
          activity['dose'] ??
              (activity['doseIU'] != null
                  ? '${activity['doseIU']} IU'
                  : 'Not specified')),
      if (activity['lotNumber'] != null &&
          activity['lotNumber'].toString().isNotEmpty)
        _buildDetailRow('Lot Number', activity['lotNumber']),
      _buildDetailRow('Date', activity['date'] ?? 'Not specified'),
      if (activity['time'] != null && activity['time'].toString().isNotEmpty)
        _buildDetailRow('Time', activity['time']),
      if (activity['notes'] != null && activity['notes'].toString().isNotEmpty)
        _buildDetailRow('Notes', activity['notes']),
      // Legacy fields for backward compatibility
      if (activity['reason'] != null &&
          activity['reason'].toString().isNotEmpty)
        _buildDetailRow('Reason', activity['reason']),
      if (activity['injectionSite'] != null &&
          activity['injectionSite'].toString().isNotEmpty)
        _buildDetailRow('Injection Site', activity['injectionSite']),
    ];
  }

  List<Widget> _buildCalculationDetails(Map<String, dynamic> activity) {
    return [
      _buildDetailRow(
          'Hemophilia Type', activity['hemophiliaType'] ?? 'Unknown'),
      _buildDetailRow('Calculated Dose',
          '${(activity['calculatedDosage'] ?? 0).round()} IU'),
      if (activity['weight'] != null)
        _buildDetailRow('Weight', '${activity['weight']} kg'),
      if (activity['targetLevel'] != null)
        _buildDetailRow('Target Level', '${activity['targetLevel']}%'),
      if (activity['baselineLevel'] != null)
        _buildDetailRow('Baseline Level', '${activity['baselineLevel']}%'),
      if (activity['bleedSeverity'] != null)
        _buildDetailRow('Bleed Severity', activity['bleedSeverity']),
    ];
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value.isEmpty ? 'Not specified' : value,
                style: TextStyle(
                  fontSize: 16,
                  color: value.isEmpty ? Colors.grey.shade500 : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatActivityTime(Map<String, dynamic> activity) {
    try {
      if (activity['activityType'] == 'bleed') {
        // For bleeds, use the date field
        return activity['date'] ?? 'Unknown';
      } else if (activity['activityType'] == 'infusion') {
        // For infusion logs, use the date field
        return activity['date'] ?? 'Unknown';
      } else {
        // For dosage calculations, format the timestamp
        final timestamp = activity['timestamp'];
        if (timestamp != null) {
          final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
          return '${date.day}/${date.month}/${date.year}';
        }
      }
    } catch (e) {
      print('Error formatting activity time: $e');
    }
    return 'Unknown';
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  IconData _getTimeIcon() {
    final hour = DateTime.now().hour;
    if (hour < 12) return FontAwesomeIcons.sun;
    if (hour < 17) return FontAwesomeIcons.cloudSun;
    return FontAwesomeIcons.moon;
  }

  Widget _buildSwipeableMedicationReminder(Map<String, dynamic> reminder) {
    return Slidable(
      key: ValueKey(reminder['id']),
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => _editMedicationReminder(reminder),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Edit',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => _markMedicationTaken(reminder),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            icon: Icons.check,
            label: 'Done',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      child: _buildMedicationReminderItemWithButton(reminder),
    );
  }

  Widget _buildMedicationReminderItemWithButton(Map<String, dynamic> reminder) {
    final reminderTime = reminder['reminderDateTime'] as DateTime?;
    final isPending = reminder['isPending'] as bool? ?? false;
    final isOverdue = reminder['isOverdue'] as bool? ?? false;

    IconData icon;
    Color iconColor;
    String status;

    if (isOverdue) {
      icon = FontAwesomeIcons.clockRotateLeft;
      iconColor = Colors.red;
      status = 'Overdue';
    } else if (isPending) {
      icon = FontAwesomeIcons.clock;
      iconColor = Colors.orange;
      status = 'Pending';
    } else {
      icon = FontAwesomeIcons.check;
      iconColor = Colors.green;
      status = 'Upcoming';
    }

    final timeString = reminderTime != null
        ? '${reminderTime.hour.toString().padLeft(2, '0')}:${reminderTime.minute.toString().padLeft(2, '0')}'
        : 'Unknown';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOverdue
            ? Colors.red.shade50
            : isPending
                ? Colors.orange.shade50
                : Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue
              ? Colors.red.shade200
              : isPending
                  ? Colors.orange.shade200
                  : Colors.green.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        reminder['medicationName'] ?? 'Unknown Medication',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: iconColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${reminder['dose'] ?? 'Unknown dosage'} • ${reminder['medType'] ?? 'Unknown type'}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Scheduled for $timeString',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.swipe_right,
                            size: 12,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'Edit',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.swipe_left,
                            size: 12,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'Done',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markMedicationTaken(Map<String, dynamic> reminder) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Mark medication as taken using enhanced service
      await _medicationService.markMedicationTaken(user.uid, reminder['id']);

      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Medication marked as taken!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Refresh the reminders list
      await _loadTodaysReminders();
    } catch (e) {
      print('Error marking medication as taken: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to mark medication as taken'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _editMedicationReminder(Map<String, dynamic> reminder) async {
    try {
      // Navigate to edit reminder screen
      final result = await Navigator.pushNamed(
        context,
        '/edit_medication_reminder',
        arguments: {
          'reminder': reminder,
          'medicationId': reminder['id'],
        },
      );

      // If the reminder was updated, refresh the reminders list
      if (result == true) {
        await _loadTodaysReminders();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Reminder updated successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error navigating to edit reminder: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open edit screen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper methods for activity display
  IconData _getActivityIcon(String? activityType) {
    switch (activityType) {
      case 'bleed':
        return FontAwesomeIcons.droplet;
      case 'infusion':
        return FontAwesomeIcons.syringe;
      case 'calculation':
        return FontAwesomeIcons.calculator;
      default:
        return FontAwesomeIcons.question;
    }
  }

  String _getActivityTitle(String? activityType) {
    switch (activityType) {
      case 'bleed':
        return 'Bleed Logged';
      case 'infusion':
        return 'Infusion Logged';
      case 'calculation':
        return 'Dosage Calculated';
      default:
        return 'Unknown Activity';
    }
  }

  String _getActivitySubtitle(Map<String, dynamic> activity) {
    switch (activity['activityType']) {
      case 'bleed':
        return '${activity['bodyRegion'] ?? 'Unknown'} • ${activity['severity'] ?? 'Unknown'}';
      case 'infusion':
        return '${activity['medication'] ?? 'Unknown medication'} • ${activity['doseIU'] ?? '0'} IU';
      case 'calculation':
        final hemophiliaType = activity['hemophiliaType'] ?? 'Factor';
        final calculatedDosage = activity['calculatedDosage'];
        final dosageStr = calculatedDosage != null
            ? '${calculatedDosage.round()} IU'
            : '0 IU';
        return '$hemophiliaType • $dosageStr';
      default:
        return 'No details available';
    }
  }

  Color _getActivityColor(String? activityType) {
    switch (activityType) {
      case 'bleed':
        return Colors.red;
      case 'infusion':
        return Colors.purple;
      case 'calculation':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Helper method to extract timestamp from various Firestore timestamp formats
  int _extractTimestamp(dynamic timestamp) {
    if (timestamp == null) return 0;

    // If it's already a DateTime
    if (timestamp is DateTime) {
      return timestamp.millisecondsSinceEpoch;
    }

    // If it's a Firestore Timestamp
    if (timestamp.runtimeType.toString() == 'Timestamp') {
      return (timestamp as dynamic).toDate().millisecondsSinceEpoch;
    }

    // If it's already milliseconds
    if (timestamp is int) {
      return timestamp;
    }

    return 0;
  }
}
