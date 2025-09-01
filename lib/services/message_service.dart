import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore.dart';

class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // Send a message between healthcare provider and patient
  Future<Map<String, dynamic>> sendMessage({
    required String senderId,
    required String receiverId,
    required String message,
    required String senderRole,
  }) async {
    try {
      print('Sending message from $senderId to $receiverId: $message');

      final messageData = {
        'senderId': senderId,
        'receiverId': receiverId,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'senderRole': senderRole,
        'isRead': false,
        'messageType': 'text',
      };

      // Add message to Firestore
      final docRef = await _firestore.collection('messages').add(messageData);
      print('Message added with ID: ${docRef.id}');

      // Create conversation document if it doesn't exist
      final conversationId = _getConversationId(senderId, receiverId);
      print('Updating conversation: $conversationId');

      await _firestore.collection('conversations').doc(conversationId).set({
        'participants': [senderId, receiverId],
        'lastMessage': message,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'lastMessageSender': senderId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('Conversation updated successfully');

      // Send notification to the receiver
      try {
        // Get sender's display name
        final senderDoc =
            await _firestore.collection('users').doc(senderId).get();
        final senderData = senderDoc.data();
        final senderName =
            senderData?['displayName'] ?? senderData?['name'] ?? 'Someone';

        await _firestoreService.createNotificationWithData(
          uid: receiverId,
          text: 'You have a new message from $senderName',
          type: 'message',
          data: {
            'senderId': senderId,
            'senderName': senderName,
            'conversationId': _getConversationId(senderId, receiverId),
          },
        );
      } catch (notificationError) {
        print('Error sending notification: $notificationError');
        // Don't throw here as the message was sent successfully
      }

      // Return the message data with the generated ID
      return {
        'id': docRef.id,
        'senderId': senderId,
        'receiverId': receiverId,
        'message': message,
        'timestamp': DateTime.now(),
        'senderRole': senderRole,
        'isRead': false,
        'messageType': 'text',
      };
    } catch (e) {
      print('Error sending message: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  // Get messages between two users
  Future<List<Map<String, dynamic>>> getMessages(
    String userId1,
    String userId2,
  ) async {
    try {
      // Since Firestore doesn't support multiple whereIn queries,
      // we need to make two separate queries and combine the results
      final query1 = await _firestore
          .collection('messages')
          .where('senderId', isEqualTo: userId1)
          .where('receiverId', isEqualTo: userId2)
          .get();

      final query2 = await _firestore
          .collection('messages')
          .where('senderId', isEqualTo: userId2)
          .where('receiverId', isEqualTo: userId1)
          .get();

      List<Map<String, dynamic>> messages = [];

      // Add messages from first query
      for (var doc in query1.docs) {
        final data = doc.data();
        messages.add({
          'id': doc.id,
          ...data,
          'timestamp':
              (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        });
      }

      // Add messages from second query
      for (var doc in query2.docs) {
        final data = doc.data();
        messages.add({
          'id': doc.id,
          ...data,
          'timestamp':
              (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        });
      }

      // Sort messages by timestamp
      messages.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));

      return messages;
    } catch (e) {
      print('Error loading messages: $e');
      // Don't return fake data - let the error bubble up so the UI can handle it properly
      rethrow;
    }
  }

  // Get conversations as a stream for real-time updates
  Stream<List<Map<String, dynamic>>> getConversationsStream(String userId) {
    print('Starting conversation stream for user: $userId');

    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .snapshots()
        .asyncMap((snapshot) async {
      print(
        'Conversation stream update: ${snapshot.docs.length} conversations',
      );

      List<Map<String, dynamic>> conversations = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        print('Processing conversation ${doc.id}: $data');

        final participants = List<String>.from(data['participants'] ?? []);
        final otherUserId = participants.firstWhere(
          (id) => id != userId,
          orElse: () => '',
        );

        if (otherUserId.isNotEmpty) {
          // Get other user's information
          final otherUserData = await _getUserData(otherUserId);
          print('Other user data: $otherUserData');

          conversations.add({
            'id': doc.id,
            'otherUser': otherUserData,
            'lastMessage': data['lastMessage'] ?? '',
            'lastMessageTimestamp':
                (data['lastMessageTimestamp'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
            'lastMessageSender': data['lastMessageSender'] ?? '',
            'isLastMessageRead': data['lastMessageSender'] ==
                userId, // If current user sent last message, mark as read
          });
        }
      }

      // Sort by timestamp on client side instead of in query
      conversations.sort((a, b) {
        final timeA = a['lastMessageTimestamp'] as DateTime;
        final timeB = b['lastMessageTimestamp'] as DateTime;
        return timeB.compareTo(timeA); // Descending order (newest first)
      });

      print('Returning ${conversations.length} conversations from stream');
      return conversations;
    });
  }

  // Get all conversations for a user (keeping for backward compatibility)
  Future<List<Map<String, dynamic>>> getConversations(String userId) async {
    try {
      print('Getting conversations for user: $userId');

      final query = await _firestore
          .collection('conversations')
          .where('participants', arrayContains: userId)
          .get();

      print('Found ${query.docs.length} conversations');

      List<Map<String, dynamic>> conversations = [];

      for (var doc in query.docs) {
        final data = doc.data();
        print('Processing conversation ${doc.id}: $data');

        final participants = List<String>.from(data['participants'] ?? []);
        final otherUserId = participants.firstWhere(
          (id) => id != userId,
          orElse: () => '',
        );

        if (otherUserId.isNotEmpty) {
          // Get other user's information
          final otherUserData = await _getUserData(otherUserId);
          print('Other user data: $otherUserData');

          conversations.add({
            'id': doc.id,
            'otherUser': otherUserData,
            'lastMessage': data['lastMessage'] ?? '',
            'lastMessageTimestamp':
                (data['lastMessageTimestamp'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
            'lastMessageSender': data['lastMessageSender'] ?? '',
            'isLastMessageRead': data['lastMessageSender'] ==
                userId, // If current user sent last message, mark as read
          });
        }
      }

      // Sort by timestamp on client side instead of in query
      conversations.sort((a, b) {
        final timeA = a['lastMessageTimestamp'] as DateTime;
        final timeB = b['lastMessageTimestamp'] as DateTime;
        return timeB.compareTo(timeA); // Descending order (newest first)
      });

      print('Returning ${conversations.length} conversations');
      return conversations;
    } catch (e) {
      print('Error loading conversations: $e');
      // Don't return fake data - let the error bubble up so the UI can handle it properly
      rethrow;
    }
  } // Get user data by ID

  Future<Map<String, dynamic>> _getUserData(String userId) async {
    try {
      print('Getting user data for: $userId');
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final userData = {'id': userId, 'uid': userId, ...doc.data()!};
        print('Found user data: $userData');
        return userData;
      } else {
        print('User document not found for: $userId');
      }
    } catch (e) {
      print('Error getting user data: $e');
    }

    // Return default user data if not found
    final defaultData = {
      'id': userId,
      'uid': userId,
      'name': 'Unknown User',
      'role': 'patient',
      'email': '',
    };
    print('Returning default user data: $defaultData');
    return defaultData;
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(
    String currentUserId,
    String otherUserId,
  ) async {
    try {
      final query = await _firestore
          .collection('messages')
          .where('senderId', isEqualTo: otherUserId)
          .where('receiverId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();

      for (var doc in query.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // Helper method to generate consistent conversation ID
  String _getConversationId(String userId1, String userId2) {
    final users = [userId1, userId2]..sort();
    return '${users[0]}_${users[1]}';
  }

  // Get unread message count for a user
  Future<int> getUnreadMessageCount(String userId) async {
    try {
      final query = await _firestore
          .collection('messages')
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return query.docs.length;
    } catch (e) {
      print('Error getting unread message count: $e');
      return 0;
    }
  }

  // Stream messages for real-time updates
  Stream<List<Map<String, dynamic>>> getMessagesStream(
    String userId1,
    String userId2,
  ) {
    print('Starting message stream between $userId1 and $userId2');

    // Use a simpler approach - query all messages and filter on client side
    // This avoids complex stream combinations that might cause issues
    return _firestore
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      List<Map<String, dynamic>> messages = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();

        // Filter messages to only include those between the two specific users
        if ((data['senderId'] == userId1 && data['receiverId'] == userId2) ||
            (data['senderId'] == userId2 && data['receiverId'] == userId1)) {
          messages.add({
            'id': doc.id,
            ...data,
            'timestamp':
                (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          });
        }
      }

      print(
        'Message stream update: ${messages.length} messages between $userId1 and $userId2',
      );
      return messages;
    });
  }

  // Delete a message
  Future<bool> deleteMessage(String messageId, String currentUserId) async {
    try {
      print('Attempting to delete message: $messageId by user: $currentUserId');
      
      // Get the message first to check ownership
      final messageDoc = await _firestore.collection('messages').doc(messageId).get();
      
      if (!messageDoc.exists) {
        print('Message not found');
        return false;
      }
      
      final messageData = messageDoc.data()!;
      final senderId = messageData['senderId'];
      
      // Check if the current user is the sender (only sender can delete their own messages)
      if (senderId != currentUserId) {
        print('User $currentUserId is not authorized to delete this message');
        return false;
      }
      
      // Delete the message first
      await _firestore.collection('messages').doc(messageId).delete();
      print('Message deleted successfully');
      
      // Update the conversation's last message
      final receiverId = messageData['receiverId'];
      final conversationId = _getConversationId(senderId, receiverId);
      
      try {
        // Get remaining messages in this conversation using a simpler query
        final query1 = await _firestore
            .collection('messages')
            .where('senderId', isEqualTo: senderId)
            .where('receiverId', isEqualTo: receiverId)
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();
            
        final query2 = await _firestore
            .collection('messages')
            .where('senderId', isEqualTo: receiverId)
            .where('receiverId', isEqualTo: senderId)
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();
        
        // Combine and find the most recent message
        List<QueryDocumentSnapshot> allDocs = [...query1.docs, ...query2.docs];
        
        if (allDocs.isNotEmpty) {
          // Sort by timestamp to get the most recent
          allDocs.sort((a, b) {
            final aTime = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp;
            final bTime = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp;
            return bTime.compareTo(aTime);
          });
          
          final lastMessage = allDocs.first.data() as Map<String, dynamic>;
          await _firestore.collection('conversations').doc(conversationId).update({
            'lastMessage': lastMessage['message'] ?? '',
            'lastMessageTimestamp': lastMessage['timestamp'],
            'lastMessageSender': lastMessage['senderId'],
            'updatedAt': FieldValue.serverTimestamp(),
          });
          print('Conversation updated with new last message');
        } else {
          // No messages left, clear the conversation
          await _firestore.collection('conversations').doc(conversationId).update({
            'lastMessage': '',
            'lastMessageTimestamp': FieldValue.serverTimestamp(),
            'lastMessageSender': '',
            'updatedAt': FieldValue.serverTimestamp(),
          });
          print('Conversation cleared - no messages remaining');
        }
      } catch (conversationError) {
        print('Error updating conversation, but message was deleted: $conversationError');
        // Don't return false here since the message was successfully deleted
      }
      
      return true;
    } catch (e) {
      print('Error deleting message: $e');
      return false;
    }
  }
}
  