import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages authentication state and provides consistent auth state across the app
class AuthStateManager {
  static final AuthStateManager _instance = AuthStateManager._internal();
  factory AuthStateManager() => _instance;
  AuthStateManager._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  StreamSubscription<User?>? _authStateSubscription;

  /// Initialize auth state listener
  void initialize() {
    _authStateSubscription =
        _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  /// Handle Firebase auth state changes
  void _onAuthStateChanged(User? user) async {
    try {
      final isLoggedIn = await _secureStorage.read(key: 'isLoggedIn');

      if (user == null && isLoggedIn == 'true') {
        // User signed out in Firebase but storage still says logged in
        print('🔄 Auth state mismatch: User signed out, clearing storage');
        await _clearAllStorageData();
      } else if (user != null && isLoggedIn != 'true') {
        // User exists in Firebase but storage doesn't reflect this
        // This could happen after app restart with persistent Firebase session
        print('🔄 Auth state mismatch: Firebase user exists but storage empty');

        // Only log this for debugging, don't auto-clear as it might be a legitimate restored session
        // The app initialization will handle this properly
      }
    } catch (e) {
      print('Error handling auth state change: $e');
    }
  }

  /// Clear all authentication-related storage
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

      print('🧹 Cleared all authentication storage');
    } catch (e) {
      print('Error clearing storage: $e');
    }
  }

  /// Clean up resources
  void dispose() {
    _authStateSubscription?.cancel();
  }
}
