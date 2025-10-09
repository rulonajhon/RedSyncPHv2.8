import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hemophilia_manager/widgets/offline_indicator.dart';
import 'dart:async';
import '../shared/chat_screen.dart';
import '../../../services/message_service.dart';
import '../../../services/doctor_availability_service.dart';
import 'compose_message_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MessageService _messageService = MessageService();
  final DoctorAvailabilityService _availabilityService =
      DoctorAvailabilityService();

  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _filteredMessages = [];
  bool _isLoading = true;
  String? _currentUserId;
  StreamSubscription<List<Map<String, dynamic>>>? _conversationSubscription;

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
      _setupConversationStream();
    }
  }

  void _setupConversationStream() {
    if (_currentUserId == null) return;

    print('Setting up conversation stream for user: $_currentUserId');

    _conversationSubscription?.cancel();

    // Try the regular service first, fall back to simple service if it fails
    _conversationSubscription = _messageService
        .getConversationsStream(_currentUserId!)
        .handleError((error) {
      print('Regular conversation stream failed: $error');
      // Fall back to manual loading with simple service
      _loadMessages();
    }).listen(
      (conversations) {
        print('Received ${conversations.length} conversations from stream');
        setState(() {
          _messages = conversations;
          _filteredMessages = conversations;
          _isLoading = false;
        });
      },
      onError: (error) {
        print('Error in conversation stream: $error');
        // Use simple service as fallback
        _loadMessages();
      },
    );
  }

  Future<void> _loadMessages() async {
    if (_currentUserId == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // Now that Firebase indexes are created, use the regular message service
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
          final specialization =
              (otherUser['specialization'] ?? '').toString().toLowerCase();
          return senderName.contains(query.toLowerCase()) ||
              lastMessage.contains(query.toLowerCase()) ||
              specialization.contains(query.toLowerCase());
        }).toList();
      }
    });
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

  void _openChatScreen(Map<String, dynamic> conversation) async {
    final otherUser = conversation['otherUser'];

    // Check if the other user is a doctor/healthcare provider
    if (otherUser['role'] == 'doctor' ||
        otherUser['role'] == 'healthcare_provider') {
      final availability =
          await _availabilityService.checkDoctorAvailability(otherUser['id']);

      if (!availability['isAvailable']) {
        _showAvailabilityDialog(otherUser, availability);
        return;
      }
    }

    // Proceed with opening the chat
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
          currentUserRole: 'patient',
        ),
      ),
    );
  }

  void _showAvailabilityDialog(
      Map<String, dynamic> provider, Map<String, dynamic> availability) {
    String dialogTitle;
    String dialogMessage;
    Color iconColor;
    IconData iconData;

    switch (availability['reason']) {
      case 'messages_disabled':
        dialogTitle = 'Messages Disabled';
        dialogMessage =
            'Dr. ${provider['name']} is currently not accepting messages. You can view your previous conversations but cannot send new messages until they become available.';
        iconColor = Colors.red;
        iconData = FontAwesomeIcons.ban;
        break;
      case 'day_unavailable':
        dialogTitle = 'Not Available Today';
        final availableDays =
            List<String>.from(availability['availableDays'] ?? []);
        dialogMessage =
            'Dr. ${provider['name']} is not available for messages today.\n\nAvailable days: ${availableDays.join(', ')}\n\nYou can view your conversation but cannot send new messages right now.';
        iconColor = Colors.orange;
        iconData = FontAwesomeIcons.calendar;
        break;
      case 'time_unavailable':
        dialogTitle = 'Outside Available Hours';
        final availableHours = availability['availableHours'];
        dialogMessage =
            'Dr. ${provider['name']} is currently outside their available hours.\n\nAvailable: ${availableHours['start']} - ${availableHours['end']}\n\nYou can view your conversation but cannot send new messages right now.';
        iconColor = Colors.blue;
        iconData = FontAwesomeIcons.clock;
        break;
      default:
        dialogTitle = 'Unavailable';
        dialogMessage = availability['message'] ??
            'This doctor is currently unavailable for messages. You can view your conversation but cannot send new messages right now.';
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
                      FontAwesomeIcons.eye,
                      color: Colors.blue.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You can still view your previous messages with this doctor.',
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
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Still allow viewing the conversation in read-only mode
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      participant: {
                        'id': provider['id'],
                        'name': provider['name'],
                        'role': provider['role'],
                        'profilePicture': provider['profilePicture'],
                      },
                      currentUserRole: 'patient',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('View Messages'),
            ),
          ],
        );
      },
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
            const Text('Messages',
                style: TextStyle(fontWeight: FontWeight.w600)),
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
          // Refresh button
          IconButton(
            onPressed: () {
              _loadMessages();
            },
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Refresh Messages',
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineIndicator(),
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
                  hintText: 'Search messages...',
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
                          'Loading messages...',
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const ComposeMessageScreen()),
          );
        },
        backgroundColor: Colors.redAccent,
        child: const Icon(FontAwesomeIcons.plus, color: Colors.white),
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
              FontAwesomeIcons.commentSlash,
              color: Colors.grey.shade400,
              size: 32,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with your healthcare provider',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ComposeMessageScreen()),
              );
            },
            icon: const Icon(FontAwesomeIcons.plus, size: 16),
            label: const Text('New Message'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageTile(Map<String, dynamic> conversation) {
    final otherUser = conversation['otherUser'];
    final isUnread = !conversation['isLastMessageRead'];

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
              radius: 24,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: otherUser['profilePicture'] != null
                  ? NetworkImage(otherUser['profilePicture'])
                  : null,
              child: otherUser['profilePicture'] == null
                  ? Icon(
                      FontAwesomeIcons.user,
                      color: Colors.grey.shade500,
                      size: 18,
                    )
                  : null,
            ),
            if (isUnread)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(6),
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
              otherUser['specialization'] ??
                  otherUser['role'] ??
                  'Healthcare Provider',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
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
        trailing: Icon(
          FontAwesomeIcons.chevronRight,
          color: Colors.grey.shade400,
          size: 14,
        ),
        onTap: () => _openChatScreen(conversation),
      ),
    );
  }
}
