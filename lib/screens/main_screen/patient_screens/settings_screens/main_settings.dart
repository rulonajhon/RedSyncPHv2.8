import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hemophilia_manager/auth/auth.dart';
import 'package:hemophilia_manager/services/firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserSettings extends StatefulWidget {
  const UserSettings({super.key});

  @override
  State<UserSettings> createState() => _UserSettingsState();
}

class _UserSettingsState extends State<UserSettings> {
  String? _name;
  String? _email;
  String? _photoUrl;
  String? _userRole; // Add user role tracking

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = AuthService().currentUser;
    if (user != null) {
      setState(() {
        _email = user.email;
        _photoUrl = user.photoURL;
      });
      // Get extra info from Firestore using the public method
      final userData = await FirestoreService().getUser(user.uid);
      if (userData != null) {
        setState(() {
          _name = userData['name'] ?? '';
          _userRole = userData['role'] ?? '';
        });
      }
    }
  }

  void _navigateToEditProfile() {
    String route;
    switch (_userRole) {
      case 'patient':
        route = '/user_info_settings';
        break;
      case 'caregiver':
        route = '/caregiver_info_settings';
        break;
      case 'medical':
        route = '/medical_info_settings';
        break;
      default:
        route = '/user_info_settings'; // Default fallback
    }
    Navigator.pushNamed(context, route);
  }

  void _logout() async {
    await AuthService().signOut();
    // Clear all secure storage keys related to login
    await _secureStorage.delete(key: 'isLoggedIn');
    await _secureStorage.delete(key: 'userRole');
    await _secureStorage.delete(key: 'userUid');
    await _secureStorage.delete(key: 'saved_email');
    await _secureStorage.delete(key: 'saved_password');
    await _secureStorage.delete(key: 'remember_me');
    await _secureStorage.deleteAll(); // As backup, clear everything

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You have been logged out.'),
        backgroundColor: Colors.redAccent,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pushReplacementNamed(context, '/authentication');
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Delete Account?',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final user = AuthService().currentUser;
      if (user != null) {
        // Delete from Firestore
        await FirestoreService().deleteUser(user.uid);
        // Delete from Firebase Auth
        await user.delete();
        // Sign out and navigate to homepage
        await AuthService().signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account deleted.'),
              backgroundColor: Colors.redAccent,
            ),
          );
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/homepage',
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete account: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showUnderDevelopmentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Under Development'),
        content: const Text('This feature is currently under development.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.redAccent,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Profile Section
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: _photoUrl != null && _photoUrl!.isNotEmpty
                      ? NetworkImage(_photoUrl!)
                      : null,
                  child: _photoUrl == null || _photoUrl!.isEmpty
                      ? const Icon(Icons.person, size: 36, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _name ?? 'Loading...',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _email ?? 'Loading...',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _navigateToEditProfile,
                        icon: const Icon(Icons.edit,
                            size: 18, color: Colors.redAccent),
                        label: const Text(
                          'Edit Profile',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Settings Section Header
            const Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: Text(
                'General',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            // Settings List
            _settingsTile(
              icon: FontAwesomeIcons.language,
              title: 'Language',
              onTap: _showUnderDevelopmentDialog,
            ),
            _settingsTile(
              icon: FontAwesomeIcons.lock,
              title: 'Password',
              onTap: () => Navigator.pushNamed(context, '/change_password'),
            ),
            _settingsTile(
              icon: FontAwesomeIcons.bell,
              title: 'Notification and Sounds',
              onTap: _showUnderDevelopmentDialog,
            ),

            const SizedBox(height: 24),

            // Info Section Header
            const Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Info & Support',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            _settingsTile(
              icon: FontAwesomeIcons.circleInfo,
              title: 'About Us',
              onTap: _showUnderDevelopmentDialog,
            ),
            _settingsTile(
              icon: FontAwesomeIcons.broom,
              title: 'Clear cache',
              onTap: _showUnderDevelopmentDialog,
            ),
            _settingsTile(
              icon: FontAwesomeIcons.fileContract,
              title: 'Terms and Privacy Policy',
              onTap: _showUnderDevelopmentDialog,
            ),

            const SizedBox(height: 24),

            // Danger Section Header
            const Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Account',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            _settingsTile(
              icon: FontAwesomeIcons.trashCan,
              title: 'Delete Account',
              iconColor: Colors.red,
              textColor: Colors.red,
              onTap: _deleteAccount,
            ),
            
            const SizedBox(height: 16),

            Center(
                child: const Text(
              'Version 1.0.0 Alpha',
              style: TextStyle(color: Colors.grey),
            )),

            const SizedBox(height: 16),

            // Logout Button
            Center(
              child: TextButton.icon(
                onPressed: _logout,
                icon:
                    const Icon(Icons.logout, color: Colors.blueGrey, size: 22),
                label: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Widget? trailing,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.redAccent, size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? Colors.black87,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      minLeadingWidth: 32,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      dense: true,
    );
  }
}

class CustomSettingsListTile extends StatelessWidget {
  final String tileTitle;
  final IconData tileIcon;
  final Color iconBg;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? textColor;

  const CustomSettingsListTile({
    super.key,
    required this.tileTitle,
    required this.tileIcon,
    required this.iconBg,
    this.onTap,
    this.trailing,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(tileTitle, style: TextStyle(color: textColor)),
      leading: Container(
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(tileIcon, color: Colors.white),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
