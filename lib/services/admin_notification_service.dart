import 'package:cloud_firestore/cloud_firestore.dart';

class AdminNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create notification for admin
  static Future<void> createAdminNotification({
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore.collection('admin_notifications').add({
        'type': type,
        'title': title,
        'message': message,
        'data': data ?? {},
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now(),
      });
    } catch (e) {
      print('Error creating admin notification: $e');
    }
  }

  // Notify admin about new doctor account
  static Future<void> notifyNewDoctorAccount({
    required String doctorName,
    required String doctorEmail,
    required String doctorId,
  }) async {
    await createAdminNotification(
      type: 'new_doctor',
      title: 'New Doctor Account',
      message:
          'Dr. $doctorName ($doctorEmail) has registered and needs verification.',
      data: {
        'doctorId': doctorId,
        'doctorName': doctorName,
        'doctorEmail': doctorEmail,
        'action': 'verify_doctor',
      },
    );
  }

  // Notify admin about event interactions
  static Future<void> notifyEventInteraction({
    required String eventId,
    required String eventTitle,
    required String userAction,
    required String userName,
  }) async {
    String actionText = '';
    switch (userAction) {
      case 'like':
        actionText = 'liked';
        break;
      case 'comment':
        actionText = 'commented on';
        break;
      case 'attend':
        actionText = 'joined';
        break;
    }

    await createAdminNotification(
      type: 'event_interaction',
      title: 'Event Activity',
      message: '$userName $actionText the event "$eventTitle"',
      data: {
        'eventId': eventId,
        'eventTitle': eventTitle,
        'userAction': userAction,
        'userName': userName,
      },
    );
  }

  // Get admin notifications stream
  static Stream<List<Map<String, dynamic>>> getAdminNotificationsStream() {
    return _firestore
        .collection('admin_notifications')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'timestamp': data['timestamp'] ?? data['createdAt'],
        };
      }).toList();
    });
  }

  // Get unread notifications count
  static Stream<int> getUnreadNotificationsCount() {
    return _firestore
        .collection('admin_notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('admin_notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  static Future<void> markAllAsRead() async {
    try {
      final batch = _firestore.batch();
      final unreadNotifications = await _firestore
          .collection('admin_notifications')
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  // Delete notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('admin_notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  // Delete old notifications (older than 30 days)
  static Future<void> cleanupOldNotifications() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final oldNotifications = await _firestore
          .collection('admin_notifications')
          .where('createdAt', isLessThan: thirtyDaysAgo)
          .get();

      final batch = _firestore.batch();
      for (final doc in oldNotifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error cleaning up old notifications: $e');
    }
  }
}
