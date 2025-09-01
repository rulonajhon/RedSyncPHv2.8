import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum NotificationType { message, like, comment, share, medication }

class AppNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new notification
  Future<void> createNotification({
    required String recipientId,
    required NotificationType type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      print(
        'Creating notification: type=$type, title=$title, recipient=$recipientId',
      );
      await _firestore.collection('notifications').add({
        'recipientId': recipientId,
        'type': type.toString().split('.').last,
        'title': title,
        'message': message,
        'data': data ?? {},
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('Notification created successfully in Firestore');
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  // Get notifications for current user
  Stream<List<Map<String, dynamic>>> getNotificationsStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: currentUser.uid)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'type': data['type'] ?? '',
              'title': data['title'] ?? '',
              'message': data['message'] ?? '',
              'data': data['data'] ?? {},
              'isRead': data['isRead'] ?? false,
              'timestamp':
                  (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
            };
          }).toList();
        });
  }

  // Get unread count
  Stream<int> getUnreadCountStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: currentUser.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final batch = _firestore.batch();
      final unreadNotifications = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: currentUser.uid)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  // Create message notification
  Future<void> notifyNewMessage({
    required String recipientId,
    required String senderName,
    required String messagePreview,
    required String conversationId,
  }) async {
    await createNotification(
      recipientId: recipientId,
      type: NotificationType.message,
      title: 'New message from $senderName',
      message: messagePreview,
      data: {'conversationId': conversationId, 'senderName': senderName},
    );
  }

  // Create post like notification
  Future<void> notifyPostLike({
    required String recipientId,
    required String likerName,
    required String postId,
    required String postPreview,
  }) async {
    await createNotification(
      recipientId: recipientId,
      type: NotificationType.like,
      title: '$likerName liked your post',
      message: postPreview.length > 50
          ? '${postPreview.substring(0, 50)}...'
          : postPreview,
      data: {'postId': postId, 'likerName': likerName},
    );
  }

  // Create post comment notification
  Future<void> notifyPostComment({
    required String recipientId,
    required String commenterName,
    required String postId,
    required String postPreview,
    required String commentText,
  }) async {
    await createNotification(
      recipientId: recipientId,
      type: NotificationType.comment,
      title: '$commenterName commented on your post',
      message: commentText.length > 50
          ? '${commentText.substring(0, 50)}...'
          : commentText,
      data: {
        'postId': postId,
        'commenterName': commenterName,
        'commentText': commentText,
      },
    );
  }

  // Create post share notification
  Future<void> notifyPostShare({
    required String recipientId,
    required String sharerName,
    required String postId,
    required String postPreview,
  }) async {
    await createNotification(
      recipientId: recipientId,
      type: NotificationType.share,
      title: '$sharerName shared your post',
      message: postPreview.length > 50
          ? '${postPreview.substring(0, 50)}...'
          : postPreview,
      data: {'postId': postId, 'sharerName': sharerName},
    );
  }

  // Create medication reminder notification
  Future<void> notifyMedicationReminder({
    required String recipientId,
    required String medicationName,
    required String dosage,
    required DateTime scheduledTime,
  }) async {
    await createNotification(
      recipientId: recipientId,
      type: NotificationType.medication,
      title: 'Medication Reminder',
      message: 'Time to take $medicationName ($dosage)',
      data: {
        'medicationName': medicationName,
        'dosage': dosage,
        'scheduledTime': scheduledTime.toIso8601String(),
      },
    );
  }
}
