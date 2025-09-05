import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/offline_service.dart';
import '../../../services/firestore.dart';
import '../../../widgets/offline_indicator.dart';

class LogHistoryScreen extends StatefulWidget {
  const LogHistoryScreen({super.key});

  @override
  State<LogHistoryScreen> createState() => _LogHistoryScreenState();
}

class _LogHistoryScreenState extends State<LogHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OfflineService _offlineService = OfflineService();
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _bleedLogs = [];
  List<Map<String, dynamic>> _infusionLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void didUpdateWidget(LogHistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload data when widget updates
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Initialize offline service
        await _offlineService.initialize();

        // Load both offline and online data
        await Future.wait([
          _loadOfflineData(),
          _loadOnlineData(user.uid),
        ]);
      }
    } catch (e) {
      // Handle errors silently for production
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadOfflineData() async {
    try {
      // Load offline bleed logs
      final offlineBleedLogs = await _offlineService.getBleedLogs();

      // Load offline infusion logs
      final offlineInfusionLogs = await _offlineService.getInfusionLogs();

      // Convert offline models to display format
      final formattedBleedLogs = offlineBleedLogs
          .map((log) => {
                'id': log.id,
                'date': log.date,
                'time': log.time,
                'bodyRegion': log.bodyRegion,
                'severity': log.severity,
                'specificRegion': log.specificRegion,
                'notes': log.notes,
                'createdAt': log.createdAt,
                'isOffline': true,
                'needsSync': log.needsSync,
                'syncStatus': log.needsSync ? 'pending' : 'synced',
                'syncedAt': log.syncedAt,
              })
          .toList();

      final formattedInfusionLogs = offlineInfusionLogs
          .map((log) => {
                'id': log.id,
                'date': log.date,
                'time': log.time,
                'medication': log.medication,
                'doseIU': log.doseIU,
                'notes': log.notes,
                'createdAt': log.createdAt,
                'isOffline': true,
                'needsSync': log.needsSync,
                'syncStatus': log.needsSync ? 'pending' : 'synced',
                'syncedAt': log.syncedAt,
              })
          .toList();

      setState(() {
        // Initialize with offline data (online data will be added later)
        _bleedLogs = formattedBleedLogs;
        _infusionLogs = formattedInfusionLogs;
      });
    } catch (e) {
      // Handle errors silently for production
    }
  }

  Future<void> _loadOnlineData(String uid) async {
    try {
      // Load bleed logs from Firestore
      final onlineBleedLogs =
          await _firestoreService.getBleedLogs(uid, limit: 100);

      // Load infusion logs from Firestore
      final onlineInfusionLogs = await _firestoreService.getInfusionLogs(uid);

      // Convert to unified format and mark as online data
      final formattedOnlineBleedLogs = onlineBleedLogs
          .map((log) => {
                ...log,
                'isOffline': false,
                'needsSync': false,
                'syncStatus': 'synced',
              })
          .toList();

      final formattedOnlineInfusionLogs = onlineInfusionLogs
          .map((log) => {
                ...log,
                'isOffline': false,
                'needsSync': false,
                'syncStatus': 'synced',
              })
          .toList();

      setState(() {
        // Merge online data with existing offline data
        _bleedLogs.addAll(formattedOnlineBleedLogs);
        _infusionLogs.addAll(formattedOnlineInfusionLogs);

        // Remove duplicates (in case same log exists both offline and online)
        _bleedLogs = _removeDuplicateLogs(_bleedLogs);
        _infusionLogs = _removeDuplicateLogs(_infusionLogs);

        // Sort by date (most recent first)
        _bleedLogs.sort((a, b) => _compareLogDates(b, a));
        _infusionLogs.sort((a, b) => _compareLogDates(b, a));
      });
    } catch (e) {
      // Handle errors silently for production
    }
  }

  List<Map<String, dynamic>> _removeDuplicateLogs(
      List<Map<String, dynamic>> logs) {
    final seen = <String>{};
    return logs.where((log) {
      final id = log['id'] as String;
      // Remove 'offline_' prefix if present to match with synced version
      final cleanId = id.startsWith('offline_') ? id.substring(8) : id;
      if (seen.contains(cleanId)) {
        return false;
      }
      seen.add(cleanId);
      return true;
    }).toList();
  }

  int _compareLogDates(Map<String, dynamic> a, Map<String, dynamic> b) {
    try {
      // Use createdAt if available, otherwise use date + time
      DateTime dateA;
      DateTime dateB;

      if (a['createdAt'] != null) {
        dateA = a['createdAt'] is DateTime
            ? a['createdAt']
            : DateTime.parse(a['createdAt'].toString());
      } else {
        dateA = DateTime.parse('${a['date']} ${a['time'] ?? '00:00'}');
      }

      if (b['createdAt'] != null) {
        dateB = b['createdAt'] is DateTime
            ? b['createdAt']
            : DateTime.parse(b['createdAt'].toString());
      } else {
        dateB = DateTime.parse('${b['date']} ${b['time'] ?? '00:00'}');
      }

      return dateA.compareTo(dateB);
    } catch (e) {
      return 0;
    }
  }

  /// Force sync and refresh all data
  Future<void> _forceRefresh() async {
    try {
      // Force sync with online database
      await _offlineService.syncAllData();

      // Reload all data
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data refreshed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error refreshing data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Log History',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh data',
            onPressed: _forceRefresh,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          tabs: const [
            Tab(text: 'Bleeding Episodes'),
            Tab(text: 'Infusion Taken'),
          ],
        ),
      ),
      // TODO: Add a calendar icon and if opened, show a calendar view of logs
      body: Column(
        children: [
          const OfflineIndicator(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Bleeding Episodes tab: show Hive logs
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.bloodtype,
                              color: Colors.redAccent, size: 28),
                          SizedBox(width: 12),
                          Text(
                            'Bleeding Episodes',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Track and monitor your bleeding episodes',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.redAccent,
                                ),
                              )
                            : _bleedLogs.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.history,
                                          size: 80,
                                          color: Colors.grey.shade400,
                                        ),
                                        const SizedBox(height: 24),
                                        Text(
                                          'No bleeding episodes yet',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Your bleeding episodes will appear here',
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 16,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  )
                                : RefreshIndicator(
                                    onRefresh: _loadData,
                                    child: ListView.separated(
                                      itemCount: _bleedLogs.length,
                                      separatorBuilder: (context, index) =>
                                          Container(
                                        height: 1,
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        color: Colors.grey.shade200,
                                      ),
                                      itemBuilder: (context, index) {
                                        final log = _bleedLogs[index];

                                        return GestureDetector(
                                          onTap: () =>
                                              _showBleedingEpisodeDetails(log),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                              horizontal: 20,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 48,
                                                  height: 48,
                                                  decoration: BoxDecoration(
                                                    color: _getSeverityColor(
                                                      log['severity'] ?? 'Mild',
                                                    ).withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: Icon(
                                                    Icons.bloodtype,
                                                    color: _getSeverityColor(
                                                      log['severity'] ?? 'Mild',
                                                    ),
                                                    size: 24,
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              log['bodyRegion'] ??
                                                                  'Unknown',
                                                              style:
                                                                  const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 16,
                                                                color: Colors
                                                                    .black87,
                                                              ),
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              maxLines: 1,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                            decoration:
                                                                BoxDecoration(
                                                              color:
                                                                  _getSeverityColor(
                                                                log['severity'] ??
                                                                    'Mild',
                                                              ).withValues(
                                                                      alpha:
                                                                          0.1),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          6),
                                                            ),
                                                            child: Text(
                                                              log['severity'] ??
                                                                  'Mild',
                                                              style: TextStyle(
                                                                color:
                                                                    _getSeverityColor(
                                                                  log['severity'] ??
                                                                      'Mild',
                                                                ),
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          _buildSyncStatusIndicator(
                                                              log),
                                                        ],
                                                      ),
                                                      if (log['specificRegion'] !=
                                                              null &&
                                                          log['specificRegion']
                                                              .toString()
                                                              .isNotEmpty)
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(top: 4),
                                                          child: Text(
                                                            log['specificRegion'],
                                                            style: TextStyle(
                                                              color: Colors.grey
                                                                  .shade600,
                                                              fontSize: 14,
                                                            ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            maxLines: 2,
                                                          ),
                                                        ),
                                                      const SizedBox(height: 8),
                                                      Row(
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .calendar_today,
                                                            size: 16,
                                                            color: Colors
                                                                .grey.shade600,
                                                          ),
                                                          const SizedBox(
                                                              width: 4),
                                                          Text(
                                                            log['date'] ??
                                                                _formatDate(
                                                                  log['createdAt'],
                                                                ),
                                                            style: TextStyle(
                                                              color: Colors.grey
                                                                  .shade600,
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 16),
                                                          Icon(
                                                            Icons.access_time,
                                                            size: 16,
                                                            color: Colors
                                                                .grey.shade600,
                                                          ),
                                                          const SizedBox(
                                                              width: 4),
                                                          Text(
                                                            log['time'] ??
                                                                _formatTime(
                                                                  log['createdAt'],
                                                                ),
                                                            style: TextStyle(
                                                              color: Colors.grey
                                                                  .shade600,
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      if (log['notes'] !=
                                                              null &&
                                                          log['notes']
                                                              .toString()
                                                              .isNotEmpty)
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(top: 8),
                                                          child: Row(
                                                            children: [
                                                              Icon(
                                                                Icons.note,
                                                                size: 16,
                                                                color: Colors
                                                                    .grey
                                                                    .shade600,
                                                              ),
                                                              const SizedBox(
                                                                  width: 4),
                                                              Expanded(
                                                                child: Text(
                                                                  log['notes'],
                                                                  style:
                                                                      TextStyle(
                                                                    color: Colors
                                                                        .grey
                                                                        .shade600,
                                                                    fontSize:
                                                                        14,
                                                                    fontStyle:
                                                                        FontStyle
                                                                            .italic,
                                                                  ),
                                                                  maxLines: 2,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.chevron_right,
                                                  color: Colors.grey.shade400,
                                                  size: 20,
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                      ),
                    ],
                  ),
                ),
                // Infusion Taken tab
                _buildInfusionTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "log_history_fab", // Unique tag to avoid conflicts
        foregroundColor: Colors.white,
        tooltip: 'Add New Log',
        onPressed: () {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) {
              return Container(
                padding: const EdgeInsets.all(12),
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
                      'Add New Log',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildActionTile(
                      icon: Icons.bloodtype,
                      title: 'Log New Bleeding Episode',
                      subtitle: 'Record a new bleeding incident',
                      color: Colors.redAccent,
                      onTap: () async {
                        Navigator.pop(context);
                        await Navigator.pushNamed(context, '/log_bleed');
                        // Refresh data when returning from adding a new log
                        _loadData();
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildActionTile(
                      icon: Icons.medical_services,
                      title: 'Log New Infusion Taken',
                      subtitle: 'Record treatment administration',
                      color: Colors.green,
                      onTap: () async {
                        Navigator.pop(context);
                        await Navigator.pushNamed(context, '/log_infusion');
                        // Refresh data when returning from adding a new log
                        _loadData();
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          );
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        backgroundColor: Colors.amber,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildInfusionTab() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.medical_services, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Text(
                'Infusion Taken',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Track your treatment history',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.green))
                : _infusionLogs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 80,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No infusion logs yet',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your infusion treatment history will appear here',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.separated(
                          itemCount: _infusionLogs.length,
                          separatorBuilder: (context, index) => Container(
                            height: 1,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            color: Colors.grey.shade200,
                          ),
                          itemBuilder: (context, index) {
                            final log = _infusionLogs[index];
                            return GestureDetector(
                              onTap: () => _showInfusionDetails(log),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 20,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.green.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.medical_services,
                                        color: Colors.green,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  '${log['medication'] ?? 'Unknown Medication'}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ),
                                              _buildSyncStatusIndicator(log),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Dose: ${log['doseIU'] ?? '0'} IU',
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.access_time,
                                                size: 16,
                                                color: Colors.grey.shade600,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${log['time'] ?? 'N/A'}',
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Icon(
                                                Icons.calendar_today,
                                                size: 16,
                                                color: Colors.grey.shade600,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${log['date'] ?? 'N/A'}',
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey.shade400,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
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
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
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
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'mild':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'severe':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic timestamp) {
    try {
      if (timestamp != null) {
        DateTime date;
        if (timestamp is int) {
          date = DateTime.fromMillisecondsSinceEpoch(timestamp);
        } else if (timestamp.toDate != null) {
          date = timestamp.toDate();
        } else {
          return 'Unknown';
        }
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      // Handle error silently
    }
    return 'Unknown';
  }

  String _formatTime(dynamic timestamp) {
    try {
      if (timestamp != null) {
        DateTime date;
        if (timestamp is int) {
          date = DateTime.fromMillisecondsSinceEpoch(timestamp);
        } else if (timestamp.toDate != null) {
          date = timestamp.toDate();
        } else {
          return 'Unknown';
        }
        return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      // Handle error silently
    }
    return 'Unknown';
  }

  void _showBleedingEpisodeDetails(Map<String, dynamic> log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getSeverityColor(log['severity'] ?? 'Mild')
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.bloodtype,
                      color: _getSeverityColor(log['severity'] ?? 'Mild'),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bleeding Episode',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          log['bodyRegion'] ?? 'Unknown Region',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.grey.shade600),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailSection(
                      title: 'Location Details',
                      icon: Icons.location_on,
                      items: [
                        {
                          'label': 'Body Region',
                          'value': log['bodyRegion'] ?? 'Not specified'
                        },
                        if (log['specificRegion'] != null &&
                            log['specificRegion'].toString().isNotEmpty)
                          {
                            'label': 'Specific Area',
                            'value': log['specificRegion']
                          },
                        if (log['sideOfBody'] != null &&
                            log['sideOfBody'].toString().isNotEmpty)
                          {'label': 'Side of Body', 'value': log['sideOfBody']},
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildDetailSection(
                      title: 'Severity & Symptoms',
                      icon: Icons.warning,
                      items: [
                        {
                          'label': 'Severity',
                          'value': log['severity'] ?? 'Not specified'
                        },
                        if (log['painLevel'] != null)
                          {
                            'label': 'Pain Level',
                            'value': '${log['painLevel']}/10'
                          },
                        if (log['symptoms'] != null &&
                            log['symptoms'].toString().isNotEmpty)
                          {'label': 'Symptoms', 'value': log['symptoms']},
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildDetailSection(
                      title: 'Date & Time',
                      icon: Icons.schedule,
                      items: [
                        {
                          'label': 'Date',
                          'value': log['date'] ?? _formatDate(log['createdAt'])
                        },
                        {
                          'label': 'Time',
                          'value': log['time'] ?? _formatTime(log['createdAt'])
                        },
                        if (log['createdAt'] != null)
                          {
                            'label': 'Logged on',
                            'value': _formatDate(log['createdAt'])
                          },
                      ],
                    ),
                    if (log['notes'] != null &&
                        log['notes'].toString().isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildDetailSection(
                        title: 'Additional Notes',
                        icon: Icons.note,
                        items: [
                          {'label': 'Notes', 'value': log['notes']},
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfusionDetails(Map<String, dynamic> log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.medical_services,
                      color: Colors.green,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Infusion Treatment',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          log['medication'] ?? 'Unknown Medication',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.grey.shade600),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailSection(
                      title: 'Medication Details',
                      icon: Icons.medication,
                      items: [
                        {
                          'label': 'Medication',
                          'value': log['medication'] ?? 'Not specified'
                        },
                        {
                          'label': 'Dose (IU)',
                          'value': '${log['doseIU'] ?? '0'} IU'
                        },
                        if (log['reason'] != null &&
                            log['reason'].toString().isNotEmpty)
                          {'label': 'Reason', 'value': log['reason']},
                        if (log['bodyWeight'] != null)
                          {
                            'label': 'Body Weight',
                            'value': '${log['bodyWeight']} kg'
                          },
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildDetailSection(
                      title: 'Administration',
                      icon: Icons.schedule,
                      items: [
                        {
                          'label': 'Date',
                          'value': log['date'] ?? 'Not specified'
                        },
                        {
                          'label': 'Time',
                          'value': log['time'] ?? 'Not specified'
                        },
                        if (log['administeredBy'] != null &&
                            log['administeredBy'].toString().isNotEmpty)
                          {
                            'label': 'Administered by',
                            'value': log['administeredBy']
                          },
                        if (log['location'] != null &&
                            log['location'].toString().isNotEmpty)
                          {'label': 'Location', 'value': log['location']},
                      ],
                    ),
                    if (log['sideEffects'] != null &&
                        log['sideEffects'].toString().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildDetailSection(
                        title: 'Side Effects',
                        icon: Icons.warning_amber,
                        items: [
                          {
                            'label': 'Side Effects',
                            'value': log['sideEffects']
                          },
                        ],
                      ),
                    ],
                    if (log['notes'] != null &&
                        log['notes'].toString().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildDetailSection(
                        title: 'Additional Notes',
                        icon: Icons.note,
                        items: [
                          {'label': 'Notes', 'value': log['notes']},
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection({
    required String title,
    required IconData icon,
    required List<Map<String, String>> items,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.redAccent, size: 16),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        '${item['label']}:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item['value'] ?? 'Not specified',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSyncStatusIndicator(Map<String, dynamic> log) {
    final syncStatus = log['syncStatus'] ?? 'synced';

    switch (syncStatus) {
      case 'pending':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sync,
                size: 12,
                color: Colors.orange.shade700,
              ),
              const SizedBox(width: 4),
              Text(
                'Offline',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
        );
      case 'synced':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                size: 12,
                color: Colors.green.shade700,
              ),
              const SizedBox(width: 4),
              Text(
                'Synced',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// TODO: Logic for viewing and managing logs in bleeding episodes and infusion taken
