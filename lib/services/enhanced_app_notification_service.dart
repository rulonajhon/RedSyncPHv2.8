import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import '../models/offline/notification.dart';
import 'offline_service.dart';

enum NotificationType { message, like, comment, share, medication }

class EnhancedAppNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final OfflineService _offlineService = OfflineService();

  static const String _notificationsBox = 'notifications';

  /// Initialize the service
  Future<void> initialize() async {
    await _offlineService.initialize();
  }

  /// Create a new notification (works offline)
  Future<void> createNotification({
    required String recipientId,
    required NotificationType type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      final uid = _auth.currentUser?.uid ?? '';
      final notificationId = DateTime.now().millisecondsSinceEpoch.toString();

      // Create notification object
      final notification = AppNotification(
        id: notificationId,
        recipientId: recipientId,
        type: type.toString().split('.').last,
        title: title,
        message: message,
        data: data ?? {},
        isRead: false,
        timestamp: DateTime.now(),
        uid: uid,
        createdAt: DateTime.now(),
        needsSync: true,
      );

      // Save offline first
      await _saveNotificationOffline(notification);

      // Try to save online if connected
      try {
        await _firestore.collection('notifications').doc(notificationId).set({
          'recipientId': recipientId,
          'type': type.toString().split('.').last,
          'title': title,
          'message': message,
          'data': data ?? {},
          'isRead': false,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Mark as synced if successful
        notification.needsSync = false;
        notification.syncedAt = DateTime.now();
        await notification.save();

        print('✅ Notification created and synced successfully');
      } catch (e) {
        print('⚠️ Notification saved offline, will sync later: $e');
      }
    } catch (e) {
      print('❌ Error creating notification: $e');
    }
  }

  /// Save notification to offline storage
  Future<void> _saveNotificationOffline(AppNotification notification) async {
    try {
      await _offlineService.initialize();
      final box = Hive.box<AppNotification>(_notificationsBox);
      await box.add(notification);
      print('📱 Notification saved offline');
    } catch (e) {
      print('❌ Error saving notification offline: $e');
    }
  }

  /// Get notifications (combines offline and online)
  Future<List<Map<String, dynamic>>> getNotifications() async {
    await _offlineService.initialize();

    List<Map<String, dynamic>> allNotifications = [];

    // Get offline notifications
    try {
      final offlineNotifications = await _getOfflineNotifications();
      allNotifications.addAll(offlineNotifications);
    } catch (e) {
      print('⚠️ Error loading offline notifications: $e');
    }

    // Get online notifications if connected
    try {
      final onlineNotifications = await _getOnlineNotifications();
      allNotifications.addAll(onlineNotifications);
    } catch (e) {
      print('⚠️ Error loading online notifications: $e');
    }

    // Remove duplicates and sort by timestamp
    final uniqueNotifications = _removeDuplicateNotifications(allNotifications);
    uniqueNotifications.sort((a, b) {
      final aTime = a['timestamp'] as DateTime;
      final bTime = b['timestamp'] as DateTime;
      return bTime.compareTo(aTime); // Newest first
    });

    return uniqueNotifications;
  }

  /// Get notifications from offline storage
  Future<List<Map<String, dynamic>>> _getOfflineNotifications() async {
    final box = Hive.box<AppNotification>(_notificationsBox);
    final uid = _auth.currentUser?.uid ?? '';

    return box.values
        .where((notification) => notification.recipientId == uid)
        .map((notification) => {
              'id': notification.id,
              'recipientId': notification.recipientId,
              'type': notification.type,
              'title': notification.title,
              'message': notification.message,
              'data': notification.data,
              'isRead': notification.isRead,
              'timestamp': notification.timestamp,
              'source': 'offline',
            })
        .toList();
  }

  /// Get notifications from online storage
  Future<List<Map<String, dynamic>>> _getOnlineNotifications() async {
    final uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) return [];

    final snapshot = await _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'recipientId': data['recipientId'],
        'type': data['type'],
        'title': data['title'],
        'message': data['message'],
        'data': data['data'] ?? {},
        'isRead': data['isRead'] ?? false,
        'timestamp':
            (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        'source': 'online',
      };
    }).toList();
  }

  /// Remove duplicate notifications based on ID
  List<Map<String, dynamic>> _removeDuplicateNotifications(
      List<Map<String, dynamic>> notifications) {
    final seen = <String>{};
    return notifications.where((notification) {
      final id = notification['id'] as String;
      return seen.add(id);
    }).toList();
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      // Update offline
      final box = Hive.box<AppNotification>(_notificationsBox);
      final notification = box.values.firstWhere(
        (n) => n.id == notificationId,
        orElse: () => throw Exception('Notification not found offline'),
      );

      notification.isRead = true;
      notification.needsSync = true;
      await notification.save();

      // Update online
      try {
        await _firestore
            .collection('notifications')
            .doc(notificationId)
            .update({'isRead': true});

        notification.needsSync = false;
        notification.syncedAt = DateTime.now();
        await notification.save();
      } catch (e) {
        print('⚠️ Notification marked as read offline, will sync later: $e');
      }
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    try {
      // Update offline notifications
      final box = Hive.box<AppNotification>(_notificationsBox);
      final userNotifications =
          box.values.where((n) => n.recipientId == uid && !n.isRead);

      for (final notification in userNotifications) {
        notification.isRead = true;
        notification.needsSync = true;
        await notification.save();
      }

      // Update online notifications
      try {
        final batch = _firestore.batch();
        final snapshot = await _firestore
            .collection('notifications')
            .where('recipientId', isEqualTo: uid)
            .where('isRead', isEqualTo: false)
            .get();

        for (final doc in snapshot.docs) {
          batch.update(doc.reference, {'isRead': true});
        }

        await batch.commit();

        // Mark offline notifications as synced
        for (final notification in userNotifications) {
          notification.needsSync = false;
          notification.syncedAt = DateTime.now();
          await notification.save();
        }
      } catch (e) {
        print('⚠️ Notifications marked as read offline, will sync later: $e');
      }
    } catch (e) {
      print('❌ Error marking all notifications as read: $e');
    }
  }

  /// Sync notifications between offline and online
  Future<void> syncNotifications() async {
    try {
      await _offlineService.initialize();

      // Upload unsynced offline notifications
      await _syncOfflineNotifications();

      // Download new online notifications
      await _downloadOnlineNotifications();

      print('✅ Notifications sync completed');
    } catch (e) {
      print('❌ Error syncing notifications: $e');
    }
  }

  /// Upload unsynced offline notifications to Firestore
  Future<void> _syncOfflineNotifications() async {
    final box = Hive.box<AppNotification>(_notificationsBox);
    final unsyncedNotifications = box.values.where((n) => n.needsSync).toList();

    for (final notification in unsyncedNotifications) {
      try {
        await _firestore.collection('notifications').doc(notification.id).set({
          'recipientId': notification.recipientId,
          'type': notification.type,
          'title': notification.title,
          'message': notification.message,
          'data': notification.data,
          'isRead': notification.isRead,
          'timestamp': Timestamp.fromDate(notification.timestamp),
        });

        notification.needsSync = false;
        notification.syncedAt = DateTime.now();
        await notification.save();
      } catch (e) {
        print('❌ Failed to sync notification ${notification.id}: $e');
      }
    }
  }

  /// Download new online notifications to offline storage
  Future<void> _downloadOnlineNotifications() async {
    final uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    try {
      final box = Hive.box<AppNotification>(_notificationsBox);

      final snapshot = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: uid)
          .get();

      for (final doc in snapshot.docs) {
        final existingNotification =
            box.values.where((n) => n.id == doc.id).firstOrNull;
        if (existingNotification == null) {
          final data = doc.data();
          final notification = AppNotification(
            id: doc.id,
            recipientId: data['recipientId'],
            type: data['type'],
            title: data['title'],
            message: data['message'],
            data: Map<String, dynamic>.from(data['data'] ?? {}),
            isRead: data['isRead'] ?? false,
            timestamp:
                (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
            uid: uid,
            createdAt: DateTime.now(),
            needsSync: false,
            syncedAt: DateTime.now(),
          );

          await box.add(notification);
        }
      }
    } catch (e) {
      print('❌ Error downloading online notifications: $e');
    }
  }
}
