import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../../../services/message_service.dart';
import '../../../services/doctor_availability_service.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> participant;
  final String currentUserRole;

  const ChatScreen({
    super.key,
    required this.participant,
    required this.currentUserRole,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final MessageService _messageService = MessageService();
  final DoctorAvailabilityService _availabilityService =
      DoctorAvailabilityService();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _currentUserId;
  StreamSubscription<List<Map<String, dynamic>>>? _messageSubscription;
  Map<String, dynamic>? _doctorAvailability;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _checkDoctorAvailability();
    // Add listener to rebuild when text changes for instant color update
    _messageController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    // Try Firebase Auth first, then fall back to secure storage
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      print('ChatScreen: Using Firebase Auth user ID: $_currentUserId');
    } else {
      _currentUserId = await _secureStorage.read(key: 'userUid');
      print('ChatScreen: Using secure storage user ID: $_currentUserId');
    }

    if (_currentUserId != null) {
      _setupMessageStream();
    } else {
      print('ChatScreen: No user ID found!');
    }
  }

  void _setupMessageStream() {
    if (_currentUserId == null) return;

    final participantId =
        widget.participant['id'] ?? widget.participant['uid'] ?? '';
    print(
      'Setting up message stream between $_currentUserId and $participantId',
    );

    setState(() => _isLoading = true);

    _messageSubscription?.cancel();
    _messageSubscription = _messageService
        .getMessagesStream(_currentUserId!, participantId)
        .listen(
      (messages) {
        print('Received ${messages.length} messages in chat stream');
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        _scrollToBottom();
      },
      onError: (error) {
        print('Error in message stream: $error');
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load messages: $error'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  Future<void> _checkDoctorAvailability() async {
    // Only check availability if patient is chatting with a doctor
    if (widget.currentUserRole == 'patient' &&
        (widget.participant['role'] == 'doctor' ||
            widget.participant['role'] == 'healthcare_provider')) {
      try {
        final availability = await _availabilityService.checkDoctorAvailability(
            widget.participant['id'] ?? widget.participant['uid'] ?? '');
        setState(() {
          _doctorAvailability = availability;
        });
      } catch (e) {
        print('Error checking doctor availability: $e');
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    // Check if patient is trying to message a doctor
    if (widget.currentUserRole == 'patient' &&
        (widget.participant['role'] == 'doctor' ||
            widget.participant['role'] == 'healthcare_provider')) {
      final availability = await _availabilityService.checkDoctorAvailability(
          widget.participant['id'] ?? widget.participant['uid'] ?? '');

      if (!availability['isAvailable']) {
        _showAvailabilityWarning(availability);
        return;
      }
    }

    final messageText = _messageController.text.trim();
    _messageController.clear();

    setState(() => _isSending = true);

    try {
      final message = await _messageService.sendMessage(
        senderId: _currentUserId ?? '',
        receiverId: widget.participant['id'] ?? widget.participant['uid'] ?? '',
        message: messageText,
        senderRole: widget.currentUserRole,
      );

      print('Message sent successfully: ${message['id']}');

      _scrollToBottom();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check, color: Colors.white),
              SizedBox(width: 8),
              Text('Message sent'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _isSending = false);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showAvailabilityWarning(Map<String, dynamic> availability) {
    String dialogTitle;
    String dialogMessage;
    Color iconColor;
    IconData iconData;

    switch (availability['reason']) {
      case 'messages_disabled':
        dialogTitle = 'Messages Disabled';
        dialogMessage =
            '${widget.participant['name'] ?? 'This doctor'} is currently not accepting messages. Please try again later.';
        iconColor = Colors.red;
        iconData = FontAwesomeIcons.ban;
        break;
      case 'day_unavailable':
        final availableDays =
            List<String>.from(availability['availableDays'] ?? []);
        dialogTitle = 'Not Available Today';
        dialogMessage =
            '${widget.participant['name'] ?? 'This doctor'} is not available for messages today.\n\nAvailable days: ${availableDays.join(', ')}';
        iconColor = Colors.orange;
        iconData = FontAwesomeIcons.calendar;
        break;
      case 'time_unavailable':
        dialogTitle = 'Outside Office Hours';
        final availableHours = availability['availableHours'];
        dialogMessage =
            '${widget.participant['name'] ?? 'This doctor'} is currently outside their available hours.\n\nAvailable: ${availableHours['start']} - ${availableHours['end']}';
        iconColor = Colors.blue;
        iconData = FontAwesomeIcons.clock;
        break;
      default:
        dialogTitle = 'Doctor Unavailable';
        dialogMessage = availability['message'] ??
            '${widget.participant['name'] ?? 'This doctor'} is currently unavailable for messages.';
        iconColor = Colors.grey;
        iconData = FontAwesomeIcons.exclamation;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(iconData, color: iconColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  dialogTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dialogMessage,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      FontAwesomeIcons.lightbulb,
                      color: Colors.blue.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your message will be saved as a draft and you can send it when the doctor becomes available.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Understood',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade100, width: 1),
            ),
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            FontAwesomeIcons.arrowLeft,
            color: Colors.redAccent,
            size: 18,
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                widget.participant['role'] == 'medical'
                    ? FontAwesomeIcons.userDoctor
                    : FontAwesomeIcons.user,
                color: Colors.redAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.participant['name'] ?? 'Unknown User',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.participant['role'] == 'medical'
                        ? 'Healthcare Provider'
                        : 'Patient',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Doctor Availability Status Indicator
          if (widget.currentUserRole == 'patient' &&
              (widget.participant['role'] == 'doctor' ||
                  widget.participant['role'] == 'healthcare_provider'))
            GestureDetector(
              onTap: () {
                if (_doctorAvailability != null &&
                    !_doctorAvailability!['isAvailable']) {
                  _showAvailabilityWarning(_doctorAvailability!);
                }
              },
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _doctorAvailability != null &&
                          _doctorAvailability!['isAvailable']
                      ? Colors.green.shade50
                      : _doctorAvailability != null &&
                              !_doctorAvailability!['isAvailable']
                          ? (_doctorAvailability!['reason'] ==
                                  'messages_disabled'
                              ? Colors.red.shade50
                              : _doctorAvailability!['reason'] ==
                                      'day_unavailable'
                                  ? Colors.orange.shade50
                                  : Colors.blue.shade50)
                          : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _doctorAvailability != null &&
                            _doctorAvailability!['isAvailable']
                        ? Colors.green.shade200
                        : _doctorAvailability != null &&
                                !_doctorAvailability!['isAvailable']
                            ? (_doctorAvailability!['reason'] ==
                                    'messages_disabled'
                                ? Colors.red.shade200
                                : _doctorAvailability!['reason'] ==
                                        'day_unavailable'
                                    ? Colors.orange.shade200
                                    : Colors.blue.shade200)
                            : Colors.grey.shade200,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _doctorAvailability != null &&
                                _doctorAvailability!['isAvailable']
                            ? Colors.green.shade600
                            : _doctorAvailability != null &&
                                    !_doctorAvailability!['isAvailable']
                                ? (_doctorAvailability!['reason'] ==
                                        'messages_disabled'
                                    ? Colors.red.shade600
                                    : _doctorAvailability!['reason'] ==
                                            'day_unavailable'
                                        ? Colors.orange.shade600
                                        : Colors.blue.shade600)
                                : Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _doctorAvailability != null &&
                              _doctorAvailability!['isAvailable']
                          ? FontAwesomeIcons.circleCheck
                          : _doctorAvailability != null &&
                                  !_doctorAvailability!['isAvailable']
                              ? (_doctorAvailability!['reason'] ==
                                      'messages_disabled'
                                  ? FontAwesomeIcons.ban
                                  : _doctorAvailability!['reason'] ==
                                          'day_unavailable'
                                      ? FontAwesomeIcons.calendar
                                      : FontAwesomeIcons.clock)
                              : FontAwesomeIcons.circle,
                      size: 14,
                      color: _doctorAvailability != null &&
                              _doctorAvailability!['isAvailable']
                          ? Colors.green.shade700
                          : _doctorAvailability != null &&
                                  !_doctorAvailability!['isAvailable']
                              ? (_doctorAvailability!['reason'] ==
                                      'messages_disabled'
                                  ? Colors.red.shade700
                                  : _doctorAvailability!['reason'] ==
                                          'day_unavailable'
                                      ? Colors.orange.shade700
                                      : Colors.blue.shade700)
                              : Colors.grey.shade500,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _doctorAvailability != null &&
                              _doctorAvailability!['isAvailable']
                          ? 'Available'
                          : _doctorAvailability != null &&
                                  !_doctorAvailability!['isAvailable']
                              ? (_doctorAvailability!['reason'] ==
                                      'messages_disabled'
                                  ? 'Messages Disabled'
                                  : _doctorAvailability!['reason'] ==
                                          'day_unavailable'
                                      ? 'Away Today'
                                      : 'Busy')
                              : 'Checking...',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _doctorAvailability != null &&
                                _doctorAvailability!['isAvailable']
                            ? Colors.green.shade800
                            : _doctorAvailability != null &&
                                    !_doctorAvailability!['isAvailable']
                                ? (_doctorAvailability!['reason'] ==
                                        'messages_disabled'
                                    ? Colors.red.shade800
                                    : _doctorAvailability!['reason'] ==
                                            'day_unavailable'
                                        ? Colors.orange.shade800
                                        : Colors.blue.shade800)
                                : Colors.grey.shade600,
                      ),
                    ),
                    if (_doctorAvailability != null &&
                        !_doctorAvailability!['isAvailable']) ...[
                      const SizedBox(width: 4),
                      Icon(
                        FontAwesomeIcons.infoCircle,
                        size: 10,
                        color: _doctorAvailability!['reason'] ==
                                'messages_disabled'
                            ? Colors.red.shade600
                            : _doctorAvailability!['reason'] ==
                                    'day_unavailable'
                                ? Colors.orange.shade600
                                : Colors.blue.shade600,
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            // Non-doctor participants get a simple status indicator
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Online',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Doctor Availability Status Banner
          if (widget.currentUserRole == 'patient' &&
              (widget.participant['role'] == 'doctor' ||
                  widget.participant['role'] == 'healthcare_provider') &&
              _doctorAvailability != null &&
              !_doctorAvailability!['isAvailable'])
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _doctorAvailability!['reason'] == 'messages_disabled'
                    ? Colors.red.shade50
                    : _doctorAvailability!['reason'] == 'day_unavailable'
                        ? Colors.orange.shade50
                        : Colors.blue.shade50,
                border: Border(
                  bottom: BorderSide(
                    color: _doctorAvailability!['reason'] == 'messages_disabled'
                        ? Colors.red.shade200
                        : _doctorAvailability!['reason'] == 'day_unavailable'
                            ? Colors.orange.shade200
                            : Colors.blue.shade200,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _doctorAvailability!['reason'] == 'messages_disabled'
                        ? FontAwesomeIcons.ban
                        : _doctorAvailability!['reason'] == 'day_unavailable'
                            ? FontAwesomeIcons.calendar
                            : FontAwesomeIcons.clock,
                    color: _doctorAvailability!['reason'] == 'messages_disabled'
                        ? Colors.red.shade600
                        : _doctorAvailability!['reason'] == 'day_unavailable'
                            ? Colors.orange.shade600
                            : Colors.blue.shade600,
                    size: 16,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _doctorAvailability!['reason'] == 'messages_disabled'
                          ? '${widget.participant['name']} has disabled messaging'
                          : _doctorAvailability!['reason'] == 'day_unavailable'
                              ? '${widget.participant['name']} is not available today'
                              : '${widget.participant['name']} is outside available hours',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _doctorAvailability!['reason'] ==
                                'messages_disabled'
                            ? Colors.red.shade700
                            : _doctorAvailability!['reason'] ==
                                    'day_unavailable'
                                ? Colors.orange.shade700
                                : Colors.blue.shade700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        _showAvailabilityWarning(_doctorAvailability!),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _doctorAvailability!['reason'] ==
                                'messages_disabled'
                            ? Colors.red.shade600
                            : _doctorAvailability!['reason'] ==
                                    'day_unavailable'
                                ? Colors.orange.shade600
                                : Colors.blue.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Messages List
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.redAccent,
                            strokeWidth: 2.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading messages...',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : _messages.isEmpty
                    ? Center(
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
                                FontAwesomeIcons.comments,
                                size: 32,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No messages yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 48),
                              child: Text(
                                'Start a conversation with ${widget.participant['name']}',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 16,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isCurrentUser =
                              message['senderId'] == _currentUserId;
                          final showAvatar = index == _messages.length - 1 ||
                              _messages[index + 1]['senderId'] !=
                                  message['senderId'];

                          return _buildMessageBubble(
                            message,
                            isCurrentUser,
                            showAvatar,
                          );
                        },
                      ),
          ),

          // Message Input
          SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade100, width: 1),
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: widget.currentUserRole == 'patient' &&
                                  (widget.participant['role'] == 'doctor' ||
                                      widget.participant['role'] ==
                                          'healthcare_provider') &&
                                  _doctorAvailability != null &&
                                  !_doctorAvailability!['isAvailable']
                              ? Colors.grey.shade100 // Disabled appearance
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: widget.currentUserRole == 'patient' &&
                                    (widget.participant['role'] == 'doctor' ||
                                        widget.participant['role'] ==
                                            'healthcare_provider') &&
                                    _doctorAvailability != null &&
                                    !_doctorAvailability!['isAvailable']
                                ? Colors.grey.shade300 // Disabled border
                                : Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: _messageController,
                          enabled: !(widget.currentUserRole == 'patient' &&
                              (widget.participant['role'] == 'doctor' ||
                                  widget.participant['role'] ==
                                      'healthcare_provider') &&
                              _doctorAvailability != null &&
                              !_doctorAvailability!['isAvailable']),
                          decoration: InputDecoration(
                            hintText: widget.currentUserRole == 'patient' &&
                                    (widget.participant['role'] == 'doctor' ||
                                        widget.participant['role'] ==
                                            'healthcare_provider') &&
                                    _doctorAvailability != null &&
                                    !_doctorAvailability!['isAvailable']
                                ? (_doctorAvailability!['reason'] ==
                                        'messages_disabled'
                                    ? 'Doctor has disabled messaging...'
                                    : 'Doctor is currently unavailable...')
                                : 'Type a message...',
                            hintStyle: TextStyle(
                              color: widget.currentUserRole == 'patient' &&
                                      (widget.participant['role'] == 'doctor' ||
                                          widget.participant['role'] ==
                                              'healthcare_provider') &&
                                      _doctorAvailability != null &&
                                      !_doctorAvailability!['isAvailable']
                                  ? Colors.red.shade400
                                  : Colors.grey.shade500,
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                          onSubmitted: (_) => _sendMessage(),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _isSending
                            ? Colors.grey.shade300
                            : (widget.currentUserRole == 'patient' &&
                                    (widget.participant['role'] == 'doctor' ||
                                        widget.participant['role'] ==
                                            'healthcare_provider') &&
                                    _doctorAvailability != null &&
                                    !_doctorAvailability!['isAvailable'])
                                ? Colors.grey
                                    .shade300 // Disabled when doctor unavailable
                                : _messageController.text.trim().isNotEmpty
                                    ? Colors.redAccent
                                    : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: IconButton(
                        onPressed: _isSending
                            ? null
                            : (widget.currentUserRole == 'patient' &&
                                    (widget.participant['role'] == 'doctor' ||
                                        widget.participant['role'] ==
                                            'healthcare_provider') &&
                                    _doctorAvailability != null &&
                                    !_doctorAvailability!['isAvailable'])
                                ? null // Disable button when doctor unavailable
                                : _sendMessage,
                        icon: _isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                FontAwesomeIcons.paperPlane,
                                color: (widget.currentUserRole == 'patient' &&
                                        (widget.participant['role'] ==
                                                'doctor' ||
                                            widget.participant['role'] ==
                                                'healthcare_provider') &&
                                        _doctorAvailability != null &&
                                        !_doctorAvailability!['isAvailable'])
                                    ? Colors.grey
                                        .shade500 // Grayed out when disabled
                                    : Colors.white,
                                size: 16,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    Map<String, dynamic> message,
    bool isCurrentUser,
    bool showAvatar,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: showAvatar ? 16 : 4),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
            showAvatar
                ? Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      FontAwesomeIcons.user,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                  )
                : const SizedBox(width: 32),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isCurrentUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onLongPress: () =>
                      _showDeleteMessageDialog(message, isCurrentUser),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isCurrentUser ? Colors.redAccent : Colors.white,
                      borderRadius: BorderRadius.circular(20).copyWith(
                        bottomLeft: isCurrentUser
                            ? const Radius.circular(20)
                            : const Radius.circular(4),
                        bottomRight: isCurrentUser
                            ? const Radius.circular(4)
                            : const Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      message['message'] ?? '',
                      style: TextStyle(
                        color:
                            isCurrentUser ? Colors.white : Colors.grey.shade800,
                        fontSize: 16,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
                if (showAvatar) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      _formatMessageTime(message['timestamp']),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            showAvatar
                ? Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      FontAwesomeIcons.user,
                      size: 16,
                      color: Colors.redAccent,
                    ),
                  )
                : const SizedBox(width: 32),
          ],
        ],
      ),
    );
  }

  String _formatMessageTime(dynamic timestamp) {
    if (timestamp == null) return '';

    DateTime time;
    if (timestamp is DateTime) {
      time = timestamp;
    } else if (timestamp is String) {
      time = DateTime.tryParse(timestamp) ?? DateTime.now();
    } else {
      return '';
    }

    final now = DateTime.now();
    final difference = now.difference(time);

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

  void _showDeleteMessageDialog(
      Map<String, dynamic> message, bool isCurrentUser) {
    // Only show delete option for the message sender
    if (!isCurrentUser) {
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Message'),
          content: const Text(
              'Are you sure you want to delete this message? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteMessage(message);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteMessage(Map<String, dynamic> message) async {
    try {
      // Get message ID from Firestore document
      final messageId =
          message['id']; // This should be set when loading messages

      print('Attempting to delete message with ID: $messageId');
      print('Current user ID: $_currentUserId');

      if (messageId == null) {
        print('Error: Message ID is null');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot delete message: Invalid message ID'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final success =
          await _messageService.deleteMessage(messageId, _currentUserId!);

      print('Delete message result: $success');

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error deleting message in chat screen: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error deleting message'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// TODO: Add a delete functionality to remove messages
