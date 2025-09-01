import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DataSharingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get healthcare providers who have active data sharing agreements with the current patient
  Future<List<String>> getAuthorizedProviderUids() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      final querySnapshot = await _firestore
          .collection('data_sharing')
          .where('patientUid', isEqualTo: currentUser.uid)
          .where('active', isEqualTo: true)
          .get();

      List<String> authorizedProviderUids = [];
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final providerUid = data['providerUid'] as String?;
        if (providerUid != null && providerUid.isNotEmpty) {
          authorizedProviderUids.add(providerUid);
        }
      }

      print(
        'Found ${authorizedProviderUids.length} authorized healthcare providers for patient: ${currentUser.uid}',
      );
      return authorizedProviderUids;
    } catch (e) {
      print('Error getting authorized provider UIDs: $e');
      return [];
    }
  }

  /// Check if a specific provider has active data sharing with the current patient
  Future<bool> hasActiveDataSharing(String providerUid) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return false;
      }

      final querySnapshot = await _firestore
          .collection('data_sharing')
          .where('patientUid', isEqualTo: currentUser.uid)
          .where('providerUid', isEqualTo: providerUid)
          .where('active', isEqualTo: true)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking data sharing status: $e');
      return false;
    }
  }

  /// Get all healthcare providers who have active data sharing with the current patient
  /// Returns a list of provider documents with their user information
  Future<List<Map<String, dynamic>>> getAuthorizedHealthcareProviders() async {
    try {
      final authorizedProviderUids = await getAuthorizedProviderUids();

      if (authorizedProviderUids.isEmpty) {
        print('No authorized healthcare providers found');
        return [];
      }

      // Get user details for authorized providers
      List<Map<String, dynamic>> authorizedProviders = [];

      for (String providerUid in authorizedProviderUids) {
        try {
          final userDoc = await _firestore
              .collection('users')
              .doc(providerUid)
              .get();

          if (userDoc.exists) {
            final userData = userDoc.data()!;
            // Only include if the user is actually a healthcare provider
            if (userData['role'] == 'medical') {
              authorizedProviders.add({
                'id': userDoc.id,
                'uid': userDoc.id,
                ...userData,
              });
            }
          }
        } catch (e) {
          print('Error fetching provider data for UID $providerUid: $e');
          // Continue with other providers even if one fails
        }
      }

      print(
        'Retrieved ${authorizedProviders.length} authorized healthcare providers',
      );
      return authorizedProviders;
    } catch (e) {
      print('Error getting authorized healthcare providers: $e');
      return [];
    }
  }

  /// Get data sharing status between current patient and a specific provider
  Future<Map<String, dynamic>?> getDataSharingStatus(String providerUid) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return null;
      }

      final querySnapshot = await _firestore
          .collection('data_sharing')
          .where('patientUid', isEqualTo: currentUser.uid)
          .where('providerUid', isEqualTo: providerUid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return {'id': doc.id, ...doc.data()};
      }

      return null;
    } catch (e) {
      print('Error getting data sharing status: $e');
      return null;
    }
  }

  /// Stream to listen for real-time updates to data sharing agreements for the current patient
  Stream<List<String>> getAuthorizedProviderUidsStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('data_sharing')
        .where('patientUid', isEqualTo: currentUser.uid)
        .where('active', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          List<String> authorizedProviderUids = [];
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final providerUid = data['providerUid'] as String?;
            if (providerUid != null && providerUid.isNotEmpty) {
              authorizedProviderUids.add(providerUid);
            }
          }
          return authorizedProviderUids;
        });
  }

  /// Create a new data sharing agreement (typically done by healthcare provider)
  Future<String?> createDataSharingAgreement(
    String patientUid,
    String providerUid,
  ) async {
    try {
      final docRef = await _firestore.collection('data_sharing').add({
        'patientUid': patientUid,
        'providerUid': providerUid,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('Data sharing agreement created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error creating data sharing agreement: $e');
      return null;
    }
  }

  /// Deactivate a data sharing agreement
  Future<bool> deactivateDataSharing(String agreementId) async {
    try {
      await _firestore.collection('data_sharing').doc(agreementId).update({
        'active': false,
        'deactivatedAt': FieldValue.serverTimestamp(),
      });

      print('Data sharing agreement deactivated: $agreementId');
      return true;
    } catch (e) {
      print('Error deactivating data sharing agreement: $e');
      return false;
    }
  }
}
