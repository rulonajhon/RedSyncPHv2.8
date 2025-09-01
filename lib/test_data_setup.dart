import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TestDataSetup extends StatelessWidget {
  const TestDataSetup({super.key});

  static Future<void> addTestPosts() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        print('No user logged in');
        return;
      }

      print('Adding test posts...');

      // Add test posts
      final posts = [
        {
          'content':
              'Just had my first successful self-infusion today! Thanks to everyone who shared their tips and encouragement. The community support here is amazing! 💪',
          'authorId': currentUser.uid,
          'timestamp': FieldValue.serverTimestamp(),
        },
        {
          'content':
              'Has anyone tried the new factor concentrate that was recently approved? I\'m considering switching and would love to hear your experiences and any tips you might have.',
          'authorId': currentUser.uid,
          'timestamp': FieldValue.serverTimestamp(),
        },
        {
          'content':
              'Sharing some tips for fellow patients: Remember to stay hydrated, rotate your injection sites, and don\'t hesitate to reach out to your healthcare team if you have concerns. We\'re all in this together! 🤝',
          'authorId': currentUser.uid,
          'timestamp': FieldValue.serverTimestamp(),
        },
      ];

      for (final post in posts) {
        await firestore.collection('community_posts').add(post);
        print('Added post: ${post['content'].toString().substring(0, 50)}...');
      }

      print('✅ Test posts added successfully!');
    } catch (e) {
      print('❌ Error adding test posts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Data Setup'),
        backgroundColor: const Color(0xFF8B0000),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.science, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Test Data Setup',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add sample posts to the community feed',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                await addTestPosts();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Test posts added! Check the community feed.',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B0000),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Add Test Posts'),
            ),
          ],
        ),
      ),
    );
  }
}
