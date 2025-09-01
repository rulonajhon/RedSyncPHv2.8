import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hemophilia_manager/widgets/offline_indicator.dart';
import 'dart:async';
import '../shared/chat_screen.dart';
import '../../../services/message_service.dart';

class HealthcareMessagesScreen extends StatefulWidget {
  const HealthcareMessagesScreen({super.key});

  @override
  State<HealthcareMessagesScreen> createState() =>
      _HealthcareMessagesScreenState();
}

class _HealthcareMessagesScreenState extends State<HealthcareMessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MessageService _messageService = MessageService();

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
              // TODO: Implement priority filter or sorting
              showModalBottomSheet(
                context: context,
                builder: (context) => Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Message Filters',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ListTile(
                        leading: const Icon(
                          FontAwesomeIcons.exclamation,
                          color: Colors.red,
                        ),
                        title: const Text('Urgent Messages'),
                        onTap: () => Navigator.pop(context),
                      ),
                      ListTile(
                        leading: const Icon(
                          FontAwesomeIcons.clock,
                          color: Colors.orange,
                        ),
                        title: const Text('Recent Messages'),
                        onTap: () => Navigator.pop(context),
                      ),
                      ListTile(
                        leading: const Icon(
                          FontAwesomeIcons.envelope,
                          color: Colors.blue,
                        ),
                        title: const Text('Unread Messages'),
                        onTap: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              );
            },
            icon: const Icon(FontAwesomeIcons.filter, size: 20),
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
