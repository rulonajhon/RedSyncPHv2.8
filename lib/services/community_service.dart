import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'firestore.dart';
import 'admin_notification_service.dart';

class CommunityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // Get all posts for the community feed with real-time likes and comments
  Stream<List<Map<String, dynamic>>> getPostsStream() {
    return _firestore
        .collection('community_posts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> posts = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();

        // Get author information
        final authorData = await _getUserData(data['authorId']);

        posts.add({
          'id': doc.id,
          'content': data['content'] ?? '',
          'timestamp':
              (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'authorId': data['authorId'] ?? '',
          'authorName': authorData['name'] ?? 'Unknown User',
          'authorRole': authorData['role'] ?? 'Patient',
          'imageUrl': data['imageUrl'],
        });
      }

      return posts;
    });
  }

  // Get real-time likes count and user like status for a specific post
  Stream<Map<String, dynamic>> getLikesStream(String postId) {
    final currentUserId = _auth.currentUser?.uid ?? '';

    return _firestore
        .collection('community_posts')
        .doc(postId)
        .collection('likes')
        .snapshots()
        .map((snapshot) {
      final likesCount = snapshot.docs.length;
      final isLiked = snapshot.docs.any((like) => like.id == currentUserId);

      return {'count': likesCount, 'isLiked': isLiked};
    });
  }

  // Get real-time comments count for a specific post
  Stream<int> getCommentsCountStream(String postId) {
    return _firestore
        .collection('community_posts')
        .doc(postId)
        .collection('comments')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get real-time comments for a specific post
  Stream<List<Map<String, dynamic>>> getCommentsStream(String postId) {
    return _firestore
        .collection('community_posts')
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'content': data['content'] ?? '',
          'timestamp':
              (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'authorId': data['authorId'] ?? '',
          'authorName': data['authorName'] ?? 'Unknown User',
          'authorRole': data['authorRole'] ?? 'Patient',
        };
      }).toList();
    });
  }

  // Create a new post
  Future<void> createPost({required String content, String? imageUrl}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    await _firestore.collection('community_posts').add({
      'content': content,
      'authorId': currentUser.uid,
      'timestamp': FieldValue.serverTimestamp(),
      'imageUrl': imageUrl,
    });
  }

  // Toggle like on a post
  Future<void> toggleLike(String postId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // Get post data to check author and content
      final postDoc =
          await _firestore.collection('community_posts').doc(postId).get();
      if (!postDoc.exists) return;

      final postData = postDoc.data()!;
      final postAuthorId = postData['authorId'] as String;
      final postContent = postData['content'] as String;

      final likeRef = _firestore
          .collection('community_posts')
          .doc(postId)
          .collection('likes')
          .doc(currentUser.uid);

      final likeDoc = await likeRef.get();

      if (likeDoc.exists) {
        // Unlike the post
        await likeRef.delete();
      } else {
        // Like the post
        await likeRef.set({
          'userId': currentUser.uid,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Send notification to post author (don't notify if user likes their own post)
        if (postAuthorId != currentUser.uid) {
          final currentUserData = await _getUserData(currentUser.uid);
          final currentUserName = currentUserData['name'] ?? 'Someone';

          print(
            'Creating like notification for user: $postAuthorId by $currentUserName',
          );

          // Store notification in Firestore (this will be picked up by the post author's app)
          await _firestoreService.createNotificationWithData(
            uid: postAuthorId,
            text:
                '$currentUserName liked your post: "${postContent.length > 30 ? '${postContent.substring(0, 30)}...' : postContent}"',
            type: 'post_like',
            data: {
              'postId': postId,
              'likerName': currentUserName,
              'likerId': currentUser.uid,
            },
          );

          print('Like notification stored in Firestore for post author');

          // Note: Local notifications should only be shown to the recipient (post author)
          // when they receive the notification through their notification stream,
          // not when someone else (liker) creates the notification.
        }
      }
    } catch (e) {
      print('Error toggling like: $e');
      rethrow;
    }
  }

  // Add a comment to a post
  Future<void> addComment({
    required String postId,
    required String content,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get post data to check author and content
      final postDoc =
          await _firestore.collection('community_posts').doc(postId).get();
      if (!postDoc.exists) return;

      final postData = postDoc.data()!;
      final postAuthorId = postData['authorId'] as String;

      // Get user data
      final userData = await _getUserData(currentUser.uid);
      final userName = userData['name'] ?? 'Unknown User';
      final userRole = userData['role'] ?? 'Patient';

      await _firestore
          .collection('community_posts')
          .doc(postId)
          .collection('comments')
          .add({
        'content': content,
        'authorId': currentUser.uid,
        'authorName': userName,
        'authorRole': userRole,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Send notification to post author (don't notify if user comments on their own post)
      if (postAuthorId != currentUser.uid) {
        print(
          'Creating comment notification for user: $postAuthorId by $userName (commenter ID: ${currentUser.uid})',
        );
        print('Post author ID: $postAuthorId');
        print('Current user ID: ${currentUser.uid}');
        print('Are they different? ${postAuthorId != currentUser.uid}');

        // Store notification in Firestore (this will be picked up by the post author's app)
        await _firestoreService.createNotificationWithData(
          uid: postAuthorId,
          text:
              '$userName commented on your post: "${content.length > 50 ? '${content.substring(0, 50)}...' : content}"',
          type: 'post_comment',
          data: {
            'postId': postId,
            'commenterName': userName,
            'commenterId': currentUser.uid,
            'commentText': content,
          },
        );

        print('Comment notification stored in Firestore for post author');

        // Note: Local notifications should only be shown to the recipient (post author)
        // when they receive the notification through their notification stream,
        // not when someone else (commenter) creates the notification.
      }
    } catch (e) {
      print('Error adding comment: $e');
      rethrow;
    }
  }

  // Get a specific post by ID
  Future<Map<String, dynamic>?> getPostById(String postId) async {
    try {
      final postDoc =
          await _firestore.collection('community_posts').doc(postId).get();

      if (!postDoc.exists) {
        return null;
      }

      final postData = postDoc.data()!;

      // Get real-time counts
      final likesSnapshot = await _firestore
          .collection('community_posts')
          .doc(postId)
          .collection('likes')
          .get();

      final commentsSnapshot = await _firestore
          .collection('community_posts')
          .doc(postId)
          .collection('comments')
          .get();

      // Check if current user liked this post
      final currentUser = _auth.currentUser;
      bool isLiked = false;
      if (currentUser != null) {
        final userLikeDoc = await _firestore
            .collection('community_posts')
            .doc(postId)
            .collection('likes')
            .doc(currentUser.uid)
            .get();
        isLiked = userLikeDoc.exists;
      }

      // Get author information from users collection
      final authorId = postData['authorId'] ?? '';
      String authorName = postData['authorName'] ?? '';
      String authorRole = postData['authorRole'] ?? '';

      if (authorId.isNotEmpty) {
        try {
          final authorData = await _getUserData(authorId);
          authorName = authorData['name'] ?? 'Unknown User';
          authorRole = authorData['role'] ?? 'Patient';
        } catch (e) {
          print('Error fetching author data: $e');
          // Fallback to stored data if fetching fails
          authorName = postData['authorName'] ?? 'Unknown User';
          authorRole = postData['authorRole'] ?? 'Patient';
        }
      }

      // Handle timestamp conversion
      DateTime? timestamp;
      final timestampData = postData['timestamp'] ?? postData['createdAt'];
      if (timestampData is Timestamp) {
        timestamp = timestampData.toDate();
      } else if (timestampData is DateTime) {
        timestamp = timestampData;
      } else {
        timestamp = DateTime.now(); // Fallback
      }

      return {
        'id': postDoc.id,
        'title': postData['title'] ?? '',
        'content': postData['content'] ?? '',
        'authorId': authorId,
        'authorName': authorName,
        'authorRole': authorRole,
        'timestamp': timestamp,
        'createdAt': timestamp,
        'likesCount': likesSnapshot.docs.length,
        'commentsCount': commentsSnapshot.docs.length,
        'isLiked': isLiked,
      };
    } catch (e) {
      print('Error getting post by ID: $e');
      return null;
    }
  }

  // Delete a post (only author can delete)
  Future<void> deletePost(String postId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get the post to check if current user is the author
      final postDoc =
          await _firestore.collection('community_posts').doc(postId).get();
      if (!postDoc.exists) {
        throw Exception('Post not found');
      }

      final postData = postDoc.data()!;
      if (postData['authorId'] != currentUser.uid) {
        throw Exception('You can only delete your own posts');
      }

      // Delete all subcollections first
      final batch = _firestore.batch();

      // Delete likes
      final likesSnapshot = await _firestore
          .collection('community_posts')
          .doc(postId)
          .collection('likes')
          .get();
      for (var doc in likesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete comments
      final commentsSnapshot = await _firestore
          .collection('community_posts')
          .doc(postId)
          .collection('comments')
          .get();
      for (var doc in commentsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete the post itself
      batch.delete(_firestore.collection('community_posts').doc(postId));

      await batch.commit();
      print('Post deleted successfully: $postId');
    } catch (e) {
      print('Error deleting post: $e');
      rethrow;
    }
  }

  // Check if current user can delete a post
  bool canDeletePost(String postAuthorId) {
    final currentUser = _auth.currentUser;
    return currentUser != null && currentUser.uid == postAuthorId;
  }

  // Report a post
  Future<void> reportPost({
    required String postId,
    required String reason,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Get post details
    final postDoc =
        await _firestore.collection('community_posts').doc(postId).get();
    if (!postDoc.exists) return;

    final postData = postDoc.data()!;
    final reporterData = await _getUserData(currentUser.uid);
    final authorData = await _getUserData(postData['authorId']);

    await _firestore.collection('post_reports').add({
      'postId': postId,
      'postContent': postData['content'],
      'postAuthorId': postData['authorId'],
      'postAuthorName': authorData['name'],
      'postTimestamp': postData['timestamp'],
      'reporterId': currentUser.uid,
      'reporterName': reporterData['name'],
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
      'reviewedBy': null,
      'reviewedAt': null,
      'adminNotes': '',
    });

    // Create admin notification
    await AdminNotificationService.createAdminNotification(
      title: 'New Post Report',
      message: 'A post has been reported for: $reason',
      type: 'post_report',
      data: {
        'postId': postId,
        'reportReason': reason,
      },
    );
  }

  // Get user data by ID
  Future<Map<String, dynamic>> _getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return {'id': userId, 'uid': userId, ...doc.data()!};
      }
    } catch (e) {
      print('Error getting user data: $e');
    }

    // Return default user data if not found
    return {
      'id': userId,
      'uid': userId,
      'name': 'Unknown User',
      'role': 'patient',
      'email': '',
    };
  }

  // Setup admin user - call this to ensure admin user has correct role
  Future<void> setupAdminUser({
    required String email,
    required String name,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Check if this is an admin email
      final adminEmails = [
        'admin@redsyncph.com',
        'administrator@redsyncph.com',
        'superadmin@redsyncph.com',
      ];

      if (!adminEmails.contains(email.toLowerCase())) {
        throw Exception('Email not authorized for admin access');
      }

      // Create or update user document with admin role
      await _firestore.collection('users').doc(currentUser.uid).set({
        'name': name,
        'email': email,
        'role': 'admin',
        'isAdmin': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('Admin user setup completed for: $email');
    } catch (e) {
      print('Error setting up admin user: $e');
      rethrow;
    }
  }

  // Quick admin check method
  Future<bool> isCurrentUserAdmin() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final userData = await _getUserData(currentUser.uid);
      final userRole = userData['role'] ?? '';

      return userRole.toLowerCase() == 'admin' ||
          userRole.toLowerCase() == 'administrator' ||
          userData['isAdmin'] == true ||
          userData['admin'] == true;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  // Share post (create a reference/notification)
  Future<void> sharePost({required String postId, String? message}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // Get the post to find the owner
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      if (!postDoc.exists) return;

      final postData = postDoc.data() as Map<String, dynamic>;
      final postOwnerId = postData['userId'] as String;

      // Create a share record
      await _firestore.collection('post_shares').add({
        'postId': postId,
        'sharerId': currentUser.uid,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Send notification to the post owner (if it's not their own post)
      if (postOwnerId != currentUser.uid) {
        final sharerName = currentUser.displayName ?? 'Someone';

        // Store notification in Firestore (this will be picked up by the post author's app)
        await _firestoreService.createNotificationWithData(
          uid: postOwnerId,
          text: '$sharerName shared your post',
          type: 'post_share',
          data: {
            'postId': postId,
            'sharerName': sharerName,
            'sharerId': currentUser.uid,
          },
        );

        print('Share notification stored in Firestore for post author');

        // Note: Local notifications should only be shown to the recipient (post author)
        // when they receive the notification through their notification stream,
        // not when someone else (sharer) creates the notification.
      }
    } catch (e) {
      print('Error sharing post: $e');
    }
  }

  // ==================== EVENTS FUNCTIONALITY ====================

  // Get all community events stream
  Stream<List<Map<String, dynamic>>> getEventsStream() {
    return _firestore
        .collection('community_events')
        .where('date', isGreaterThanOrEqualTo: DateTime.now())
        .orderBy('date', descending: false)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> events = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();

        // Get author information
        final authorData = await _getUserData(data['authorId']);

        events.add({
          'id': doc.id,
          'title': data['title'] ?? '',
          'description': data['description'] ?? '',
          'date': (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'location': data['location'] ?? '',
          'imageUrl': data['imageUrl'],
          'eventType': data['eventType'] ?? 'general',
          'timestamp':
              (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'authorId': data['authorId'] ?? '',
          'authorName': authorData['name'] ?? 'RedSync Admin',
          'authorRole': authorData['role'] ?? 'admin',
          'attendeesCount': data['attendeesCount'] ?? 0,
          'maxAttendees': data['maxAttendees'],
        });
      }

      return events;
    });
  }

  // Create a new community event (admin only)
  Future<void> createEvent({
    required String title,
    required String description,
    required DateTime date,
    required TimeOfDay time,
    required String location,
    required String eventType,
    String? imageUrl,
    int? maxAttendees,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Check if user is admin
      final userData = await _getUserData(currentUser.uid);
      final userRole = userData['role'] ?? '';

      print('User data for event creation: $userData');
      print('User role: $userRole');

      // Check for admin role (case insensitive and multiple possible values)
      final isAdmin = userRole.toLowerCase() == 'admin' ||
          userRole.toLowerCase() == 'administrator' ||
          userData['isAdmin'] == true ||
          userData['admin'] == true;

      if (!isAdmin) {
        throw Exception(
            'Only administrators can create events. Current role: $userRole');
      }

      // Combine date and time into a single DateTime
      final eventDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );

      await _firestore.collection('community_events').add({
        'title': title,
        'description': description,
        'date': Timestamp.fromDate(eventDateTime),
        'location': location,
        'eventType': eventType,
        'imageUrl': imageUrl,
        'maxAttendees': maxAttendees,
        'authorId': currentUser.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'attendeesCount': 0,
      });

      print('Event created successfully');
    } catch (e) {
      print('Error creating event: $e');
      rethrow;
    }
  }

  // Update an existing community event (admin only)
  Future<void> updateEvent({
    required String eventId,
    required String title,
    required String description,
    required DateTime date,
    required TimeOfDay time,
    required String location,
    required String eventType,
    String? imageUrl,
    int? maxAttendees,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Check if user is admin
      final userData = await _getUserData(currentUser.uid);
      final userRole = userData['role'] ?? '';

      // Check for admin role (case insensitive and multiple possible values)
      final isAdmin = userRole.toLowerCase() == 'admin' ||
          userRole.toLowerCase() == 'administrator' ||
          userData['isAdmin'] == true ||
          userData['admin'] == true;

      if (!isAdmin) {
        throw Exception(
            'Only administrators can edit events. Current role: $userRole');
      }

      // Combine date and time into a single DateTime
      final eventDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );

      await _firestore.collection('community_events').doc(eventId).update({
        'title': title,
        'description': description,
        'date': Timestamp.fromDate(eventDateTime),
        'location': location,
        'eventType': eventType,
        'imageUrl': imageUrl,
        'maxAttendees': maxAttendees,
        'lastModified': FieldValue.serverTimestamp(),
      });

      print('Event updated successfully');
    } catch (e) {
      print('Error updating event: $e');
      rethrow;
    }
  }

  // Delete a community event (admin only)
  Future<void> deleteEvent(String eventId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Check if user is admin
      final userData = await _getUserData(currentUser.uid);
      final userRole = userData['role'] ?? '';

      // Check for admin role (case insensitive and multiple possible values)
      final isAdmin = userRole.toLowerCase() == 'admin' ||
          userRole.toLowerCase() == 'administrator' ||
          userData['isAdmin'] == true ||
          userData['admin'] == true;

      if (!isAdmin) {
        throw Exception(
            'Only administrators can delete events. Current role: $userRole');
      }

      // Delete the event document
      await _firestore.collection('community_events').doc(eventId).delete();

      // Also delete all associated subcollections (attendees, likes, comments)
      final batch = _firestore.batch();

      // Delete attendees
      final attendeesSnapshot = await _firestore
          .collection('community_events')
          .doc(eventId)
          .collection('attendees')
          .get();

      for (var doc in attendeesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete likes
      final likesSnapshot = await _firestore
          .collection('community_events')
          .doc(eventId)
          .collection('likes')
          .get();

      for (var doc in likesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete comments
      final commentsSnapshot = await _firestore
          .collection('community_events')
          .doc(eventId)
          .collection('comments')
          .get();

      for (var doc in commentsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      print('Event and all associated data deleted successfully');
    } catch (e) {
      print('Error deleting event: $e');
      rethrow;
    }
  }

  // Get attendees for a specific event
  Stream<Map<String, dynamic>> getEventAttendeesStream(String eventId) {
    final currentUserId = _auth.currentUser?.uid ?? '';

    return _firestore
        .collection('community_events')
        .doc(eventId)
        .collection('attendees')
        .snapshots()
        .map((snapshot) {
      final attendees = snapshot.docs.map((doc) => doc.id).toList();
      final isAttending = attendees.contains(currentUserId);

      return {
        'count': attendees.length,
        'isAttending': isAttending,
        'attendees': attendees,
      };
    });
  }

  // Toggle event attendance
  Future<void> toggleEventAttendance(String eventId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final attendeeRef = _firestore
          .collection('community_events')
          .doc(eventId)
          .collection('attendees')
          .doc(currentUser.uid);

      final eventRef = _firestore.collection('community_events').doc(eventId);

      final attendeeDoc = await attendeeRef.get();

      if (attendeeDoc.exists) {
        // Remove attendance
        await attendeeRef.delete();
        await eventRef.update({
          'attendeesCount': FieldValue.increment(-1),
        });
        print('Removed attendance for event: $eventId');
      } else {
        // Add attendance
        await attendeeRef.set({
          'userId': currentUser.uid,
          'timestamp': FieldValue.serverTimestamp(),
        });
        await eventRef.update({
          'attendeesCount': FieldValue.increment(1),
        });
        print('Added attendance for event: $eventId');

        // Get event details and user data for notification
        final eventDoc =
            await _firestore.collection('community_events').doc(eventId).get();
        final userData = await _getUserData(currentUser.uid);

        if (eventDoc.exists) {
          final eventData = eventDoc.data()!;
          await AdminNotificationService.notifyEventInteraction(
            eventId: eventId,
            eventTitle: eventData['title'] ?? 'Community Event',
            userAction: 'attend',
            userName: userData['name'] ?? 'Unknown User',
          );
        }
      }
    } catch (e) {
      print('Error toggling event attendance: $e');
      rethrow;
    }
  }

  // Get comments for a specific event
  Stream<List<Map<String, dynamic>>> getEventCommentsStream(String eventId) {
    return _firestore
        .collection('community_events')
        .doc(eventId)
        .collection('comments')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> comments = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final authorData = await _getUserData(data['authorId']);

        comments.add({
          'id': doc.id,
          'content': data['content'] ?? '',
          'timestamp':
              (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'authorId': data['authorId'] ?? '',
          'authorName': authorData['name'] ?? 'Unknown User',
          'authorRole': authorData['role'] ?? 'Patient',
        });
      }

      return comments;
    });
  }

  // Add comment to event
  Future<void> addEventComment(String eventId, String content) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection('community_events')
          .doc(eventId)
          .collection('comments')
          .add({
        'content': content,
        'authorId': currentUser.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('Comment added to event: $eventId');

      // Get event details and user data for notification
      final eventDoc =
          await _firestore.collection('community_events').doc(eventId).get();
      final userData = await _getUserData(currentUser.uid);

      if (eventDoc.exists) {
        final eventData = eventDoc.data()!;
        await AdminNotificationService.notifyEventInteraction(
          eventId: eventId,
          eventTitle: eventData['title'] ?? 'Community Event',
          userAction: 'comment',
          userName: userData['name'] ?? 'Unknown User',
        );
      }
    } catch (e) {
      print('Error adding event comment: $e');
      rethrow;
    }
  }

  // Get event likes stream
  Stream<Map<String, dynamic>> getEventLikesStream(String eventId) {
    final currentUserId = _auth.currentUser?.uid ?? '';

    return _firestore
        .collection('community_events')
        .doc(eventId)
        .collection('likes')
        .snapshots()
        .map((snapshot) {
      final likes = snapshot.docs.map((doc) => doc.id).toList();
      final isLiked = likes.contains(currentUserId);

      return {
        'count': likes.length,
        'isLiked': isLiked,
        'likes': likes,
      };
    });
  }

  // Toggle event like
  Future<void> toggleEventLike(String eventId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final likeRef = _firestore
          .collection('community_events')
          .doc(eventId)
          .collection('likes')
          .doc(currentUser.uid);

      final likeDoc = await likeRef.get();

      if (likeDoc.exists) {
        // Remove like
        await likeRef.delete();
        print('Removed like from event: $eventId');
      } else {
        // Add like
        await likeRef.set({
          'userId': currentUser.uid,
          'timestamp': FieldValue.serverTimestamp(),
        });
        print('Added like to event: $eventId');

        // Get event details and user data for notification
        final eventDoc =
            await _firestore.collection('community_events').doc(eventId).get();
        final userData = await _getUserData(currentUser.uid);

        if (eventDoc.exists) {
          final eventData = eventDoc.data()!;
          await AdminNotificationService.notifyEventInteraction(
            eventId: eventId,
            eventTitle: eventData['title'] ?? 'Community Event',
            userAction: 'like',
            userName: userData['name'] ?? 'Unknown User',
          );
        }
      }
    } catch (e) {
      print('Error toggling event like: $e');
      rethrow;
    }
  }

  // Share event
  Future<void> shareEvent(String eventId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get event data
      final eventDoc =
          await _firestore.collection('community_events').doc(eventId).get();
      if (!eventDoc.exists) {
        throw Exception('Event not found');
      }

      final eventData = eventDoc.data()!;

      // Create a shared post in the community feed
      await _firestore.collection('community_posts').add({
        'content':
            'Check out this upcoming event: ${eventData['title']}\n\n${eventData['description']}',
        'authorId': currentUser.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'sharedEventId': eventId,
        'postType': 'shared_event',
      });

      print('Event shared: $eventId');
    } catch (e) {
      print('Error sharing event: $e');
      rethrow;
    }
  }
}
