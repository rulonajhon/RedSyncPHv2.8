// Manual Admin Setup Script
// Use this to manually setup admin users if needed

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminSetupHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Manual admin setup - call this with the admin user's UID
  static Future<void> manualAdminSetup({
    required String userUid,
    required String email,
    required String name,
  }) async {
    try {
      await _firestore.collection('users').doc(userUid).set({
        'name': name,
        'email': email,
        'role': 'admin',
        'isAdmin': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('Manual admin setup completed for: $email (UID: $userUid)');
    } catch (e) {
      print('Error in manual admin setup: $e');
      rethrow;
    }
  }

  // Setup current authenticated user as admin
  static Future<void> setupCurrentUserAsAdmin() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user is currently authenticated');
      }

      await manualAdminSetup(
        userUid: currentUser.uid,
        email: currentUser.email ?? 'admin@redsyncph.com',
        name: 'Administrator',
      );
    } catch (e) {
      print('Error setting up current user as admin: $e');
      rethrow;
    }
  }

  // Verify admin setup
  static Future<void> verifyAdminSetup(String userUid) async {
    try {
      final doc = await _firestore.collection('users').doc(userUid).get();
      if (doc.exists) {
        final data = doc.data()!;
        print('User document found:');
        print('- Name: ${data['name']}');
        print('- Email: ${data['email']}');
        print('- Role: ${data['role']}');
        print('- IsAdmin: ${data['isAdmin']}');
        print('- Created: ${data['createdAt']}');
      } else {
        print('No user document found for UID: $userUid');
      }
    } catch (e) {
      print('Error verifying admin setup: $e');
    }
  }
}

// To use this helper:
// 1. Import this file in your app
// 2. Call AdminSetupHelper.setupCurrentUserAsAdmin() when logged in as admin
// 3. Or call AdminSetupHelper.manualAdminSetup() with specific user details
