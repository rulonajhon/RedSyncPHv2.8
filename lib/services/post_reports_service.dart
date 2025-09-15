import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostReportsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get all post reports with real-time updates
  Stream<List<Map<String, dynamic>>> getPostReportsStream() {
    print('🚨 [POST_REPORTS] Starting to stream all post reports');
    return _firestore
        .collection('post_reports')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      print(
          '🚨 [POST_REPORTS] Received ${snapshot.docs.length} post reports from Firestore');

      // Debug: Check if collection exists by trying a simple get
      if (snapshot.docs.isEmpty) {
        print('🚨 [POST_REPORTS] No documents found. Checking collection...');
        _firestore.collection('post_reports').get().then((testSnapshot) {
          print(
              '🚨 [POST_REPORTS] Direct collection check: ${testSnapshot.docs.length} docs total');
          for (var doc in testSnapshot.docs) {
            final data = doc.data();
            print(
                '🚨 [POST_REPORTS] Found doc: ${doc.id} - status: ${data['status']}');
          }
        });
      }

      for (var doc in snapshot.docs) {
        final data = doc.data();
        print(
            '🚨 [POST_REPORTS] PostReport: ${doc.id} - postId: ${data['postId']}, status: ${data['status']}, reason: ${data['reason']}');
      }
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'postId': data['postId'],
          'postContent': data['postContent'],
          'postAuthorId': data['postAuthorId'],
          'postAuthorName': data['postAuthorName'],
          'postTimestamp': data['postTimestamp'],
          'reporterId': data['reporterId'],
          'reporterName': data['reporterName'],
          'reason': data['reason'],
          'timestamp': data['timestamp'],
          'status': data['status'] ?? 'pending',
          'reviewedBy': data['reviewedBy'],
          'reviewedAt': data['reviewedAt'],
          'adminNotes': data['adminNotes'] ?? '',
        };
      }).toList();
    });
  }

  // Get reports by status
  Stream<List<Map<String, dynamic>>> getReportsByStatus(String status) {
    print(
        '🚨 [POST_REPORTS] Starting to stream post reports with status: $status');
    return _firestore
        .collection('post_reports')
        .where('status', isEqualTo: status)
        // Remove orderBy to avoid composite index requirement
        .snapshots()
        .map((snapshot) {
      print(
          '🚨 [POST_REPORTS] Received ${snapshot.docs.length} post reports with status "$status" from Firestore');

      // If no pending reports found, check what statuses exist
      if (status == 'pending' && snapshot.docs.isEmpty) {
        print(
            '🚨 [POST_REPORTS] No pending reports found. Checking all statuses...');
        _firestore.collection('post_reports').get().then((allSnapshot) {
          final statusCounts = <String, int>{};
          for (var doc in allSnapshot.docs) {
            final docStatus = doc.data()['status'] ?? 'pending';
            statusCounts[docStatus] = (statusCounts[docStatus] ?? 0) + 1;
          }
          print('🚨 [POST_REPORTS] Status breakdown: $statusCounts');
        });
      }

      for (var doc in snapshot.docs) {
        final data = doc.data();
        print(
            '🚨 [POST_REPORTS] Found ${status} report: ${doc.id} - reason: ${data['reason']}');
      }

      // Convert to list and sort manually to avoid composite index requirement
      final reports = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'postId': data['postId'],
          'postContent': data['postContent'],
          'postAuthorId': data['postAuthorId'],
          'postAuthorName': data['postAuthorName'],
          'postTimestamp': data['postTimestamp'],
          'reporterId': data['reporterId'],
          'reporterName': data['reporterName'],
          'reason': data['reason'],
          'timestamp': data['timestamp'],
          'status': data['status'] ?? 'pending',
          'reviewedBy': data['reviewedBy'],
          'reviewedAt': data['reviewedAt'],
          'adminNotes': data['adminNotes'] ?? '',
        };
      }).toList();

      // Sort by timestamp (most recent first) to maintain order
      reports.sort((a, b) {
        final timestampA = a['timestamp'] as Timestamp?;
        final timestampB = b['timestamp'] as Timestamp?;

        if (timestampA == null && timestampB == null) return 0;
        if (timestampA == null) return 1;
        if (timestampB == null) return -1;

        return timestampB.compareTo(timestampA); // Descending order
      });

      return reports;
    });
  }

  // Get count of pending reports
  Stream<int> getPendingReportsCount() {
    return _firestore
        .collection('post_reports')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Resolve a report (approve or dismiss)
  Future<void> resolveReport({
    required String reportId,
    required String action, // 'approved', 'dismissed'
    String? adminNotes,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    await _firestore.collection('post_reports').doc(reportId).update({
      'status': action,
      'reviewedBy': currentUser.uid,
      'reviewedAt': FieldValue.serverTimestamp(),
      'adminNotes': adminNotes ?? '',
    });
  }

  // Delete a post (when report is approved)
  Future<void> deleteReportedPost(String postId) async {
    // Delete the post
    await _firestore.collection('community_posts').doc(postId).delete();

    // Delete associated likes
    final likesSnapshot = await _firestore
        .collection('community_posts')
        .doc(postId)
        .collection('likes')
        .get();

    for (var doc in likesSnapshot.docs) {
      await doc.reference.delete();
    }

    // Delete associated comments
    final commentsSnapshot = await _firestore
        .collection('community_posts')
        .doc(postId)
        .collection('comments')
        .get();

    for (var doc in commentsSnapshot.docs) {
      await doc.reference.delete();
    }
  }

  // Get reports for a specific post
  Stream<List<Map<String, dynamic>>> getReportsForPost(String postId) {
    return _firestore
        .collection('post_reports')
        .where('postId', isEqualTo: postId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'reporterId': data['reporterId'],
          'reporterName': data['reporterName'],
          'reason': data['reason'],
          'timestamp': data['timestamp'],
          'status': data['status'] ?? 'pending',
          'reviewedBy': data['reviewedBy'],
          'reviewedAt': data['reviewedAt'],
          'adminNotes': data['adminNotes'] ?? '',
        };
      }).toList();
    });
  }
}
