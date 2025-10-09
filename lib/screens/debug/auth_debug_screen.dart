import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Debug screen to help troubleshoot authentication issues
/// Add this to your routes and access it via '/auth_debug' route
class AuthDebugScreen extends StatefulWidget {
  const AuthDebugScreen({super.key});

  @override
  State<AuthDebugScreen> createState() => _AuthDebugScreenState();
}

class _AuthDebugScreenState extends State<AuthDebugScreen> {
  Map<String, dynamic> authState = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAuthState();
  }

  Future<void> _loadAuthState() async {
    setState(() => isLoading = true);

    try {
      final auth = FirebaseAuth.instance;
      const secureStorage = FlutterSecureStorage();
      final prefs = await SharedPreferences.getInstance();

      authState = {
        'firebase': {
          'user': auth.currentUser?.uid,
          'email': auth.currentUser?.email,
          'isAnonymous': auth.currentUser?.isAnonymous,
          'emailVerified': auth.currentUser?.emailVerified,
        },
        'secureStorage': {
          'isLoggedIn': await secureStorage.read(key: 'isLoggedIn'),
          'userRole': await secureStorage.read(key: 'userRole'),
          'userUid': await secureStorage.read(key: 'userUid'),
          'isGuest': await secureStorage.read(key: 'isGuest'),
        },
        'sharedPreferences': {
          'isLoggedIn': prefs.getString('isLoggedIn'),
          'userRole': prefs.getString('userRole'),
          'saved_email': prefs.getString('saved_email'),
          'remember_me': prefs.getBool('remember_me'),
        },
        'consistency': _checkConsistency(auth.currentUser),
      };
    } catch (e) {
      authState = {'error': e.toString()};
    }

    setState(() => isLoading = false);
  }

  Map<String, dynamic> _checkConsistency(User? firebaseUser) {
    final hasFirebaseUser = firebaseUser != null;
    final secureStorageLoggedIn =
        authState['secureStorage']?['isLoggedIn'] == 'true';

    return {
      'firebaseVsStorage':
          hasFirebaseUser == secureStorageLoggedIn ? 'CONSISTENT' : 'MISMATCH',
      'issues': _detectIssues(hasFirebaseUser, secureStorageLoggedIn),
    };
  }

  List<String> _detectIssues(bool hasFirebaseUser, bool storageLoggedIn) {
    List<String> issues = [];

    if (!hasFirebaseUser && storageLoggedIn) {
      issues.add('Storage says logged in but no Firebase user');
    }
    if (hasFirebaseUser && !storageLoggedIn) {
      issues.add('Firebase user exists but storage says not logged in');
    }

    return issues;
  }

  Future<void> _clearAllData() async {
    try {
      const secureStorage = FlutterSecureStorage();
      final prefs = await SharedPreferences.getInstance();

      await secureStorage.deleteAll();
      await prefs.clear();
      await FirebaseAuth.instance.signOut();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All authentication data cleared'),
          backgroundColor: Colors.green,
        ),
      );

      _loadAuthState();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clearing data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auth Debug'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAuthState,
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearAllData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection('Firebase Auth', authState['firebase']),
                  const SizedBox(height: 16),
                  _buildSection('Secure Storage', authState['secureStorage']),
                  const SizedBox(height: 16),
                  _buildSection(
                      'Shared Preferences', authState['sharedPreferences']),
                  const SizedBox(height: 16),
                  _buildConsistencySection(authState['consistency']),
                  const SizedBox(height: 24),
                  const Text(
                    'Actions:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _clearAllData,
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Clear All Auth Data',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(String title, Map<String, dynamic>? data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (data != null)
              ...data.entries.map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            '${entry.key}:',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            entry.value?.toString() ?? 'null',
                            style: TextStyle(
                              color: entry.value == null ? Colors.grey : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildConsistencySection(Map<String, dynamic>? consistency) {
    if (consistency == null) return const SizedBox();

    final status = consistency['firebaseVsStorage'] as String?;
    final issues = consistency['issues'] as List<String>? ?? [];

    return Card(
      color: status == 'CONSISTENT' ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  status == 'CONSISTENT' ? Icons.check_circle : Icons.error,
                  color: status == 'CONSISTENT' ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Consistency Check: $status',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (issues.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Issues:',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              ...issues.map((issue) => Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: Text('• $issue',
                        style: const TextStyle(color: Colors.red)),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
