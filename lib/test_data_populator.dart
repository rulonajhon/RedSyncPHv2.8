// This is a temporary script to add test data to the community
// Run this once to populate the community with sample posts

import 'package:cloud_firestore/cloud_firestore.dart';

class TestDataPopulator {
  static Future<void> addSamplePosts() async {
    final firestore = FirebaseFirestore.instance;

    // Sample posts
    final posts = [
      {
        'content':
            'Just had my first successful self-infusion today! Thanks to everyone who shared their tips and encouragement. The community support here is amazing! 💪',
        'authorId': '3EP6kXWlavM6swRmeWVgpvf73dx1', // Current patient user
        'timestamp': FieldValue.serverTimestamp(),
      },
      {
        'content':
            'Has anyone tried the new factor concentrate that was recently approved? I\'m considering switching and would love to hear your experiences and any tips you might have.',
        'authorId': '3EP6kXWlavM6swRmeWVgpvf73dx1',
        'timestamp': FieldValue.serverTimestamp(),
      },
      {
        'content':
            'Reminder: Winter weather can sometimes affect bleeding episodes. Make sure to stay warm and keep your factor replacement handy during cold months. Stay safe everyone! ❄️',
        'authorId': 'sample_hematologist_id',
        'timestamp': FieldValue.serverTimestamp(),
      },
    ];

    // Add posts to Firestore
    for (final post in posts) {
      await firestore.collection('community_posts').add(post);
    }

    print('Sample posts added successfully!');
  }
}
