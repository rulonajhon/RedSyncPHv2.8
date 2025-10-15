import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<User?> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    return credential.user;
  }

  // Create account with email and password
  Future<User?> createAccount(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    return credential.user;
  }

  // Sign out - Fixed to clear both storage types
  Future<void> signOut() async {
    try {
      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');
      await prefs.remove('userRole');
      await prefs.remove('saved_email');
      await prefs.remove('remember_me');

      // Clear FlutterSecureStorage - THIS WAS MISSING!
      await _secureStorage.delete(key: 'isLoggedIn');
      await _secureStorage.delete(key: 'userRole');
      await _secureStorage.delete(key: 'userUid');
      await _secureStorage.delete(key: 'isGuest');

      // Sign out from Firebase
      await _auth.signOut();

      print('✅ Successfully signed out and cleared all storage');
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  // Sign in anonymously
  Future<User?> signInAnonymously() async {
    final userCredential = await FirebaseAuth.instance.signInAnonymously();
    return userCredential.user;
  }

  // Validate authentication state - IMPROVED METHOD
  Future<bool> validateAuthState() async {
    try {
      final currentUser = _auth.currentUser;
      final isLoggedIn = await _secureStorage.read(key: 'isLoggedIn');

      // If Firebase user is null but storage says logged in, clear storage
      if (currentUser == null && isLoggedIn == 'true') {
        print(
            '⚠️ Auth mismatch detected: No Firebase user but storage says logged in');
        await _clearAllStorageData();
        return false;
      }

      // If Firebase user exists, trust the Firebase session even if storage is inconsistent
      if (currentUser != null) {
        // Firebase Auth has automatic persistence, so if there's a user, they're authenticated
        print('✅ Firebase user session found, authentication valid');

        // If storage is missing, restore it from Firebase user
        if (isLoggedIn != 'true') {
          print('🔄 Restoring login state to secure storage');
          await _secureStorage.write(key: 'isLoggedIn', value: 'true');
          await _secureStorage.write(key: 'userUid', value: currentUser.uid);
        }

        return true;
      }

      // No Firebase user and no storage flag - user is not authenticated
      return false;
    } catch (e) {
      print('Error validating auth state: $e');
      return false;
    }
  }

  // Clear all storage data - PRIVATE HELPER METHOD
  Future<void> _clearAllStorageData() async {
    try {
      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');
      await prefs.remove('userRole');
      await prefs.remove('saved_email');
      await prefs.remove('remember_me');

      // Clear FlutterSecureStorage
      await _secureStorage.delete(key: 'isLoggedIn');
      await _secureStorage.delete(key: 'userRole');
      await _secureStorage.delete(key: 'userUid');
      await _secureStorage.delete(key: 'isGuest');

      print('🧹 Cleared all storage data');
    } catch (e) {
      print('Error clearing storage data: $e');
    }
  }
}
