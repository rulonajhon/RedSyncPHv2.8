import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

class DatabaseCleanup {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Clear all dummy/test posts from the community_posts collection
  /// This will remove any posts that are not from real authenticated users
  static Future<void> clearDummyPosts() async {
    try {
      print('Starting cleanup of dummy posts...');

      // Get all posts
      final QuerySnapshot postsSnapshot = await _firestore
          .collection('community_posts')
          .get();

      int deletedCount = 0;

      for (QueryDocumentSnapshot doc in postsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final authorId = data['authorId'] as String?;

        // Check if this is a dummy post by checking various criteria:
        // 1. Posts with generic/test author IDs
        // 2. Posts with test content
        // 3. Posts without proper timestamps

        bool isDummyPost = false;

        // Check for test/dummy author IDs
        if (authorId == null ||
            authorId.isEmpty ||
            authorId == 'test_user' ||
            authorId == 'dummy_user' ||
            authorId.startsWith('test_') ||
            authorId.startsWith('dummy_')) {
          isDummyPost = true;
        }

        // Check for test content
        final content = data['content'] as String?;
        if (content != null) {
          final lowerContent = content.toLowerCase();
          if (lowerContent.contains('test') ||
              lowerContent.contains('dummy') ||
              lowerContent.contains('sample') ||
              lowerContent.startsWith('this is a test')) {
            isDummyPost = true;
          }
        }

        // If it's a dummy post, delete it
        if (isDummyPost) {
          await doc.reference.delete();
          deletedCount++;
          print('Deleted dummy post: ${doc.id}');
        }
      }

      print('Cleanup completed. Deleted $deletedCount dummy posts.');
    } catch (e) {
      print('Error during cleanup: $e');
      rethrow;
    }
  }

  /// Reset the community collection to be completely empty
  /// Use this if you want to start fresh with no posts at all
  static Future<void> clearAllPosts() async {
    try {
      print('Starting complete cleanup of all posts...');

      final QuerySnapshot postsSnapshot = await _firestore
          .collection('community_posts')
          .get();

      int deletedCount = 0;

      for (QueryDocumentSnapshot doc in postsSnapshot.docs) {
        await doc.reference.delete();
        deletedCount++;
      }

      print('Complete cleanup finished. Deleted $deletedCount posts.');
    } catch (e) {
      print('Error during complete cleanup: $e');
      rethrow;
    }
  }

  /// Verify that only authentic user posts remain
  static Future<void> verifyCleanDatabase() async {
    try {
      final QuerySnapshot postsSnapshot = await _firestore
          .collection('community_posts')
          .get();

      print('Database verification:');
      print('Total posts remaining: ${postsSnapshot.docs.length}');

      for (QueryDocumentSnapshot doc in postsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final authorId = data['authorId'];
        final content = data['content'];
        final timestamp = data['timestamp'];

        print('Post ID: ${doc.id}');
        print('  Author: $authorId');
        print(
          '  Content preview: ${content?.toString().substring(0, math.min(50, content?.toString().length ?? 0))}...',
        );
        print('  Timestamp: $timestamp');
        print('---');
      }
    } catch (e) {
      print('Error during verification: $e');
    }
  }
}
