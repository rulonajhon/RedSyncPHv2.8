import 'package:cloud_firestore/cloud_firestore.dart';

/// Test helper to create sample post reports for testing admin functionality
class PostReportsTestHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create sample post reports for testing
  static Future<void> createSampleReports() async {
    print('🧪 [TEST] Creating sample post reports...');

    try {
      // Sample post report 1 - Pending
      await _firestore.collection('post_reports').add({
        'postId': 'test_post_1',
        'postContent':
            'This is a test post that has been reported for inappropriate content.',
        'postAuthorId': 'test_user_1',
        'postAuthorName': 'Test User 1',
        'postTimestamp': FieldValue.serverTimestamp(),
        'reporterId': 'test_reporter_1',
        'reporterName': 'Test Reporter 1',
        'reason': 'Inappropriate Content',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      // Sample post report 2 - Pending
      await _firestore.collection('post_reports').add({
        'postId': 'test_post_2',
        'postContent': 'Another test post with spam content that needs review.',
        'postAuthorId': 'test_user_2',
        'postAuthorName': 'Test User 2',
        'postTimestamp': FieldValue.serverTimestamp(),
        'reporterId': 'test_reporter_2',
        'reporterName': 'Test Reporter 2',
        'reason': 'Spam',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      // Sample post report 3 - Already reviewed
      await _firestore.collection('post_reports').add({
        'postId': 'test_post_3',
        'postContent': 'This post was already reviewed and dismissed.',
        'postAuthorId': 'test_user_3',
        'postAuthorName': 'Test User 3',
        'postTimestamp': FieldValue.serverTimestamp(),
        'reporterId': 'test_reporter_3',
        'reporterName': 'Test Reporter 3',
        'reason': 'Misinformation',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'dismissed',
        'reviewedBy': 'admin_test',
        'reviewedAt': FieldValue.serverTimestamp(),
        'adminNotes': 'Reviewed and found to be legitimate content.',
      });

      print('✅ [TEST] Sample post reports created successfully!');
    } catch (e) {
      print('❌ [TEST] Error creating sample reports: $e');
    }
  }

  /// Clear all test reports
  static Future<void> clearTestReports() async {
    print('🧹 [TEST] Clearing test post reports...');

    try {
      final snapshot = await _firestore.collection('post_reports').where(
          'postId',
          whereIn: ['test_post_1', 'test_post_2', 'test_post_3']).get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      print('✅ [TEST] Test post reports cleared successfully!');
    } catch (e) {
      print('❌ [TEST] Error clearing test reports: $e');
    }
  }

  /// Check what reports exist in the database
  static Future<void> debugReportsInDatabase() async {
    print('🔍 [TEST] Checking post reports in database...');

    try {
      final snapshot = await _firestore.collection('post_reports').get();
      print('📊 [TEST] Total reports in database: ${snapshot.docs.length}');

      if (snapshot.docs.isEmpty) {
        print('📭 [TEST] No reports found in database');
        return;
      }

      final statusCounts = <String, int>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] ?? 'pending';
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;

        print('📝 [TEST] Report ${doc.id}:');
        print('   - Post ID: ${data['postId']}');
        print('   - Status: ${data['status']}');
        print('   - Reason: ${data['reason']}');
        print('   - Reporter: ${data['reporterName']}');
      }

      print('📈 [TEST] Status breakdown: $statusCounts');
    } catch (e) {
      print('❌ [TEST] Error checking reports: $e');
    }
  }
}
