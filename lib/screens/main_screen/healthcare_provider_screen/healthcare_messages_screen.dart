import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hemophilia_manager/widgets/offline_indicator.dart';
import 'dart:async';
import '../shared/chat_screen.dart';
import '../../../services/message_service.dart';
import '../../../services/doctor_availability_service.dart';

class HealthcareMessagesScreen extends StatefulWidget {
  const HealthcareMessagesScreen({super.key});

  @override
  State<HealthcareMessagesScreen> createState() =>
      _HealthcareMessagesScreenState();
}

class _HealthcareMessagesScreenState extends State<HealthcareMessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MessageService _messageService = MessageService();
  final DoctorAvailabilityService _availabilityService =
      DoctorAvailabilityService();

  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _filteredMessages = [];
  bool _isLoading = true;
  String? _currentUserId;
  StreamSubscription<List<Map<String, dynamic>>>? _conversationSubscription;

  // Availability settings
  bool _isAvailableForMessages = true;
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);
  List<String> _availableDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday'
  ];

  // Temporary settings for the modal (before saving)
  bool _tempIsAvailableForMessages = true;
  TimeOfDay _tempStartTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _tempEndTime = const TimeOfDay(hour: 18, minute: 0);
  List<String> _tempAvailableDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday'
  ];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _conversationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
      });
      await _loadAvailabilitySettings();
      _setupConversationStream();
    }
  }

  Future<void> _loadAvailabilitySettings() async {
    if (_currentUserId == null) return;

    try {
      final settings =
          await _availabilityService.getAvailabilitySettings(_currentUserId!);
      if (settings != null) {
        setState(() {
          _isAvailableForMessages = settings['isAvailable'] ?? true;
          _startTime = TimeOfDay(
            hour: settings['startTime']['hour'] ?? 8,
            minute: settings['startTime']['minute'] ?? 0,
          );
          _endTime = TimeOfDay(
            hour: settings['endTime']['hour'] ?? 18,
            minute: settings['endTime']['minute'] ?? 0,
          );
          _availableDays = List<String>.from(settings['availableDays'] ??
              ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']);

          // Initialize temp settings with current values
          _tempIsAvailableForMessages = _isAvailableForMessages;
          _tempStartTime = _startTime;
          _tempEndTime = _endTime;
          _tempAvailableDays = List<String>.from(_availableDays);
        });
      }
    } catch (e) {
      print('Error loading availability settings: $e');
    }
  }

  Future<void> _saveAvailabilitySettings() async {
    if (_currentUserId == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _availabilityService.saveAvailabilitySettings(
        doctorUid: _currentUserId!,
        isAvailable: _tempIsAvailableForMessages,
        startTime: _tempStartTime,
        endTime: _tempEndTime,
        availableDays: _tempAvailableDays,
      );

      // Update the actual settings with temp values
      setState(() {
        _isAvailableForMessages = _tempIsAvailableForMessages;
        _startTime = _tempStartTime;
        _endTime = _tempEndTime;
        _availableDays = List<String>.from(_tempAvailableDays);
        _isSaving = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Availability settings saved successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Close the modal
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      print('Error saving availability settings: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _setupConversationStream() {
    if (_currentUserId == null) return;

    print(
      'Setting up conversation stream for healthcare provider: $_currentUserId',
    );

    _conversationSubscription?.cancel();
    _conversationSubscription =
        _messageService.getConversationsStream(_currentUserId!).listen(
      (conversations) {
        print(
          'Healthcare provider received ${conversations.length} conversations from stream',
        );
        setState(() {
          _messages = conversations;
          _filteredMessages = conversations;
          _isLoading = false;
        });
      },
      onError: (error) {
        print('Error in healthcare provider conversation stream: $error');
        setState(() {
          _isLoading = false;
        });
      },
    );
  }

  Future<void> _loadMessages() async {
    if (_currentUserId == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // Get conversations for the current healthcare provider
      final conversations = await _messageService.getConversations(
        _currentUserId!,
      );

      setState(() {
        _messages = conversations;
        _filteredMessages = conversations;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading messages: $e');
      setState(() {
        _isLoading = false;
      });
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load messages: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterMessages(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredMessages = _messages;
      } else {
        _filteredMessages = _messages.where((conversation) {
          final otherUser = conversation['otherUser'];
          final senderName = (otherUser['name'] ?? '').toString().toLowerCase();
          final lastMessage =
              (conversation['lastMessage'] ?? '').toString().toLowerCase();
          final email = (otherUser['email'] ?? '').toString().toLowerCase();
          return senderName.contains(query.toLowerCase()) ||
              lastMessage.contains(query.toLowerCase()) ||
              email.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _showAvailabilitySettings() {
    // Initialize temp settings with current values when opening modal
    _tempIsAvailableForMessages = _isAvailableForMessages;
    _tempStartTime = _startTime;
    _tempEndTime = _endTime;
    _tempAvailableDays = List<String>.from(_availableDays);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false, // Prevent dismissing without saving
      enableDrag: false, // Prevent dragging to dismiss
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Icon(
                        FontAwesomeIcons.cog,
                        color: Colors.redAccent,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Message Availability Settings',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 0),
                // Settings content
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Overall availability toggle
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                _tempIsAvailableForMessages
                                    ? FontAwesomeIcons.toggleOn
                                    : FontAwesomeIcons.toggleOff,
                                color: _tempIsAvailableForMessages
                                    ? Colors.green
                                    : Colors.grey,
                                size: 24,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Available for Messages',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _tempIsAvailableForMessages
                                          ? 'Patients can send you messages'
                                          : 'Messages are disabled',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _tempIsAvailableForMessages,
                                onChanged: (value) {
                                  setModalState(() {
                                    _tempIsAvailableForMessages = value;
                                  });
                                },
                                activeColor: Colors.redAccent,
                              ),
                            ],
                          ),
                        ),

                        if (_tempIsAvailableForMessages) ...[
                          const SizedBox(height: 24),

                          // Available hours section
                          const Text(
                            'Available Hours',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                ListTile(
                                  leading: const Icon(
                                    FontAwesomeIcons.sun,
                                    color: Colors.orange,
                                  ),
                                  title: const Text('Start Time'),
                                  subtitle: Text(_formatTime(_tempStartTime)),
                                  trailing: const Icon(Icons.arrow_forward_ios,
                                      size: 16),
                                  onTap: () => _selectTime(true, setModalState),
                                ),
                                const Divider(),
                                ListTile(
                                  leading: const Icon(
                                    FontAwesomeIcons.moon,
                                    color: Colors.indigo,
                                  ),
                                  title: const Text('End Time'),
                                  subtitle: Text(_formatTime(_tempEndTime)),
                                  trailing: const Icon(Icons.arrow_forward_ios,
                                      size: 16),
                                  onTap: () =>
                                      _selectTime(false, setModalState),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Available days section
                          const Text(
                            'Available Days',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              children: [
                                'Monday',
                                'Tuesday',
                                'Wednesday',
                                'Thursday',
                                'Friday',
                                'Saturday',
                                'Sunday'
                              ]
                                  .map((day) => CheckboxListTile(
                                        title: Text(day),
                                        value: _tempAvailableDays.contains(day),
                                        activeColor: Colors.redAccent,
                                        onChanged: (bool? value) {
                                          setModalState(() {
                                            if (value == true) {
                                              _tempAvailableDays.add(day);
                                            } else {
                                              _tempAvailableDays.remove(day);
                                            }
                                          });
                                        },
                                      ))
                                  .toList(),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Info section
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(
                                  FontAwesomeIcons.info,
                                  color: Colors.blue.shade600,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Patients will see your availability status and can only send messages during your available hours.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                // Save button at the bottom
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveAvailabilitySettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Saving...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              'Save Settings',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectTime(bool isStartTime,
      [StateSetter? setModalState]) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _tempStartTime : _tempEndTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.redAccent,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (setModalState != null) {
        // Update temp settings in modal
        setModalState(() {
          if (isStartTime) {
            _tempStartTime = picked;
          } else {
            _tempEndTime = picked;
          }
        });
      } else {
        // Fallback for direct state update (shouldn't happen with new design)
        setState(() {
          if (isStartTime) {
            _tempStartTime = picked;
          } else {
            _tempEndTime = picked;
          }
        });
      }
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour == 0 ? 12 : hour}:$minute $period';
  }

  bool _isCurrentlyAvailable() {
    if (!_isAvailableForMessages) return false;

    final currentDay = _getCurrentDayName();

    if (!_availableDays.contains(currentDay)) return false;

    final currentTime = TimeOfDay.now();
    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;

    return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
  }

  String _getCurrentDayName() {
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return weekdays[DateTime.now().weekday - 1];
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _openChatScreen(Map<String, dynamic> conversation) {
    final otherUser = conversation['otherUser'];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          participant: {
            'id': otherUser['id'],
            'name': otherUser['name'],
            'role': otherUser['role'],
            'profilePicture': otherUser['profilePicture'],
          },
          currentUserRole: 'medical',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _messages
        .where((conversation) => !conversation['isLastMessageRead'])
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text(
              'Patient Messages',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            if (unreadCount > 0)
              Text(
                '$unreadCount unread',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.redAccent,
        actions: [
          IconButton(
            onPressed: () {
              _showAvailabilitySettings();
            },
            icon: const Icon(FontAwesomeIcons.cog, size: 20),
            tooltip: 'Message Settings',
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineIndicator(),
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filterMessages,
                decoration: InputDecoration(
                  hintText: 'Search patients, messages, or conditions...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: Icon(
                    FontAwesomeIcons.magnifyingGlass,
                    color: Colors.grey.shade500,
                    size: 18,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ),

          // Availability Status Indicator
          if (_isAvailableForMessages)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _isCurrentlyAvailable()
                    ? Colors.green.shade50
                    : Colors.blue.shade50,
                border: Border.all(
                    color: _isCurrentlyAvailable()
                        ? Colors.green.shade200
                        : Colors.blue.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    FontAwesomeIcons.circle,
                    color: _isCurrentlyAvailable()
                        ? Colors.green.shade600
                        : Colors.blue.shade600,
                    size: 8,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isCurrentlyAvailable()
                          ? 'Currently available for messages'
                          : 'Available: ${_formatTime(_startTime)} - ${_formatTime(_endTime)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: _isCurrentlyAvailable()
                            ? Colors.green.shade700
                            : Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    _isCurrentlyAvailable()
                        ? 'Online'
                        : '${_availableDays.length} days/week',
                    style: TextStyle(
                      fontSize: 12,
                      color: _isCurrentlyAvailable()
                          ? Colors.green.shade600
                          : Colors.blue.shade600,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    FontAwesomeIcons.circle,
                    color: Colors.orange.shade600,
                    size: 8,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Currently unavailable for messages',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    'Offline',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade600,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Messages List
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                            color: Colors.redAccent),
                        const SizedBox(height: 16),
                        Text(
                          'Loading patient messages...',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : _filteredMessages.isEmpty
                    ? RefreshIndicator(
                        color: Colors.redAccent,
                        onRefresh: _loadMessages,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: _buildEmptyState(),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        color: Colors.redAccent,
                        onRefresh: _loadMessages,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _filteredMessages.length,
                          itemBuilder: (context, index) {
                            final conversation = _filteredMessages[index];
                            return _buildMessageTile(conversation);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              FontAwesomeIcons.userDoctor,
              color: Colors.grey.shade400,
              size: 32,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No patient messages',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Patient conversations will appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageTile(Map<String, dynamic> conversation) {
    final otherUser = conversation['otherUser'];
    final isUnread = !conversation['isLastMessageRead'];
    final isCaregiver = otherUser['role'] == 'caregiver';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isUnread ? Colors.red.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnread ? Colors.red.shade200 : Colors.grey.shade200,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor:
                  isCaregiver ? Colors.purple.shade100 : Colors.blue.shade100,
              backgroundImage: otherUser['profilePicture'] != null
                  ? NetworkImage(otherUser['profilePicture'])
                  : null,
              child: otherUser['profilePicture'] == null
                  ? Icon(
                      isCaregiver
                          ? FontAwesomeIcons.userGroup
                          : FontAwesomeIcons.user,
                      color: isCaregiver
                          ? Colors.purple.shade600
                          : Colors.blue.shade600,
                      size: 18,
                    )
                  : null,
            ),
            if (isUnread)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                otherUser['name'] ?? 'Unknown User',
                style: TextStyle(
                  fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              _formatTimestamp(conversation['lastMessageTimestamp']),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              otherUser['role'] == 'caregiver' ? 'Caregiver' : 'Patient',
              style: TextStyle(
                fontSize: 12,
                color:
                    isCaregiver ? Colors.purple.shade600 : Colors.blue.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (otherUser['email'] != null && otherUser['email'].isNotEmpty)
              Text(
                otherUser['email'],
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            const SizedBox(height: 8),
            Text(
              conversation['lastMessage'] ?? 'No messages yet',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FontAwesomeIcons.chevronRight,
              color: Colors.grey.shade400,
              size: 14,
            ),
            if (isUnread) const SizedBox(height: 4),
            if (isUnread)
              Icon(
                FontAwesomeIcons.exclamation,
                color: Colors.red.shade500,
                size: 12,
              ),
          ],
        ),
        onTap: () => _openChatScreen(conversation),
      ),
    );
  }
}
