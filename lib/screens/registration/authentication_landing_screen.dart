import 'package:flutter/material.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Commented out - not currently used
import 'package:hemophilia_manager/auth/auth.dart';
import 'package:hemophilia_manager/services/firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthenticationLandingScreen extends StatefulWidget {
  const AuthenticationLandingScreen({super.key});

  @override
  State<AuthenticationLandingScreen> createState() =>
      _AuthenticationLandingScreenState();
}

class _AuthenticationLandingScreenState
    extends State<AuthenticationLandingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
          child: Column(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo and App Name Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/images/app_logo.png',
                            width: 100,
                            height: 100,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'RedSyncPH',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent,
                              letterSpacing: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Your hemophilia management companion',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Authentication Options Section
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Primary Actions
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              title: 'Login',
                              icon: Icons.login,
                              isPrimary: true,
                              onTap: () => Navigator.pushReplacementNamed(
                                context,
                                '/login',
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildActionButton(
                              title: 'Register',
                              icon: Icons.person_add,
                              isPrimary: true,
                              onTap: () => Navigator.pushReplacementNamed(
                                context,
                                '/register',
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Divider with text
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.grey.shade300,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'or continue with',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.grey.shade300,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Google Sign In - Temporarily hidden (not implemented)
                      // SizedBox(
                      //   width: double.infinity,
                      //   child: _buildSocialButton(
                      //     title: 'Sign in with Google',
                      //     icon: FontAwesomeIcons.google,
                      //     iconColor: Colors.redAccent,
                      //     onTap: () {
                      //       // TODO: Implement Google Sign In
                      //     },
                      //   ),
                      // ),

                      // const SizedBox(height: 12),

                      // Guest Access
                      SizedBox(
                        width: double.infinity,
                        child: _buildActionButton(
                          title: 'Continue as Guest',
                          icon: Icons.person_outline,
                          isPrimary: false,
                          onTap: () async {
                            // Show info modal bottom sheet
                            final confirmed = await showModalBottomSheet<bool>(
                              context: context,
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              builder: (context) => Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(24),
                                    topRight: Radius.circular(24),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Handle bar
                                      Container(
                                        width: 40,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade300,
                                          borderRadius:
                                              BorderRadius.circular(2),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      // Header
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.blue.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Icon(
                                              Icons.info_outline,
                                              color: Colors.blue,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          const Expanded(
                                            child: Text(
                                              'Guest Mode',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      // Features section
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                              color: Colors.grey.shade200),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: const Icon(
                                                    Icons.check_circle,
                                                    color: Colors.green,
                                                    size: 16,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                const Text(
                                                  'As a guest, you can:',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            _buildGuestFeature(
                                                'Access educational resources'),
                                            _buildGuestFeature(
                                                'Use the dosage calculator'),
                                            _buildGuestFeature(
                                                'Find nearby clinics'),
                                            _buildGuestFeature(
                                                'Try the pre-screening tool'),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      // Warning section
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade50,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: Colors.orange.shade200),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.warning_amber,
                                              color: Colors.orange.shade700,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'Data won\'t be saved between sessions',
                                                style: TextStyle(
                                                  color: Colors.orange.shade700,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 32),
                                      // Action buttons
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              style: OutlinedButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 14),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                              child: const Text('Cancel'),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            flex: 2,
                                            child: ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.redAccent,
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 14),
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                              child: const Text(
                                                'Continue as Guest',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                  ),
                                ),
                              ),
                            );

                            if (confirmed != true) return;

                            try {
                              // Show loading indicator
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const AlertDialog(
                                  content: Row(
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(width: 16),
                                      Text('Signing in as guest...'),
                                    ],
                                  ),
                                ),
                              );

                              // Sign in anonymously
                              final user =
                                  await AuthService().signInAnonymously();

                              if (user != null && mounted) {
                                // Create basic guest profile in Firestore
                                await FirestoreService().createUser(
                                  user.uid,
                                  'Guest User',
                                  'guest@redsyncph.com',
                                  'patient',
                                );

                                // Store guest session data
                                const storage = FlutterSecureStorage();
                                await storage.write(
                                  key: 'isLoggedIn',
                                  value: 'true',
                                );
                                await storage.write(
                                  key: 'userRole',
                                  value: 'patient',
                                );
                                await storage.write(
                                  key: 'userUid',
                                  value: user.uid,
                                );
                                await storage.write(
                                  key: 'isGuest',
                                  value: 'true',
                                );

                                if (mounted) {
                                  Navigator.pop(
                                    context,
                                  ); // Close loading dialog
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    '/user_screen',
                                    (route) => false,
                                  );
                                }
                              }
                            } catch (e) {
                              if (mounted) {
                                Navigator.pop(
                                  context,
                                ); // Close loading dialog if open
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed to continue as guest: ${e.toString()}',
                                    ),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Pre-screening Button
                      SizedBox(
                        width: double.infinity,
                        child: _buildActionButton(
                          title: 'Take Pre-screening Test',
                          icon: Icons.quiz_outlined,
                          isPrimary: false,
                          onTap: () {
                            Navigator.pushNamed(context, '/pre_screening');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Footer Section
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    Text(
                      'By continuing, you agree to our',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            _showTermsOfService();
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                          ),
                          child: const Text(
                            'Terms of Service',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          ' and ',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            _showPrivacyPolicy();
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                          ),
                          child: const Text(
                            'Privacy Policy',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(
          icon,
          size: 18,
          color: isPrimary ? Colors.white : Colors.grey.shade700,
        ),
        label: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: isPrimary ? Colors.white : Colors.grey.shade700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? Colors.redAccent : Colors.grey.shade100,
          foregroundColor: isPrimary ? Colors.white : Colors.grey.shade700,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isPrimary ? Colors.redAccent : Colors.grey.shade300,
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Terms of Service',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RedSync PH Terms of Service',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '1. Acceptance of Terms',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'By using RedSync PH, you agree to these terms and conditions. This app is designed to help manage hemophilia care and connect patients with healthcare providers.',
                ),
                const SizedBox(height: 16),
                const Text(
                  '2. Medical Disclaimer',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This app is for informational purposes only. It is not a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of qualified healthcare providers.',
                ),
                const SizedBox(height: 16),
                const Text(
                  '3. Data Privacy',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'We respect your privacy and are committed to protecting your personal information. Your health data is encrypted and securely stored.',
                ),
                const SizedBox(height: 16),
                const Text(
                  '4. User Responsibilities',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Users are responsible for providing accurate information and using the app responsibly. Medical professionals must verify their credentials.',
                ),
                const SizedBox(height: 16),
                const Text(
                  '5. Emergency Situations',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This app is not intended for emergency situations. In case of a medical emergency, immediately contact local emergency services.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Privacy Policy',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RedSync PH Privacy Policy',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '1. Information We Collect',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'We collect information you provide directly to us, such as when you create an account, update your profile, or use our services. This includes name, email address, and medical information relevant to hemophilia care.',
                ),
                const SizedBox(height: 16),
                const Text(
                  '2. How We Use Your Information',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'We use your information to provide, maintain, and improve our services, communicate with you, and ensure the security of our platform. Medical information is used solely for care management purposes.',
                ),
                const SizedBox(height: 16),
                const Text(
                  '3. Information Sharing',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'We do not sell, trade, or otherwise transfer your personal information to third parties without your consent, except as described in this policy or as required by law.',
                ),
                const SizedBox(height: 16),
                const Text(
                  '4. Data Security',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.',
                ),
                const SizedBox(height: 16),
                const Text(
                  '5. Your Rights',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You have the right to access, update, or delete your personal information. You may also request data portability or object to certain processing activities.',
                ),
                const SizedBox(height: 16),
                const Text(
                  '6. Contact Us',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'If you have any questions about this Privacy Policy, please contact our Data Protection Officer through the app or via email.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  // Widget _buildSocialButton({
  //   required String title,
  //   required IconData icon,
  //   required Color iconColor,
  //   required VoidCallback onTap,
  // }) {
  //   return SizedBox(
  //     height: 48,
  //     child: OutlinedButton.icon(
  //       onPressed: onTap,
  //       icon: Icon(icon, size: 18, color: iconColor),
  //       label: Text(
  //         title,
  //         style: TextStyle(
  //           fontWeight: FontWeight.w600,
  //           fontSize: 14,
  //           color: Colors.grey.shade700,
  //         ),
  //       ),
  //       style: OutlinedButton.styleFrom(
  //         backgroundColor: Colors.white,
  //         side: BorderSide(color: Colors.grey.shade300, width: 1),
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(12),
  //         ),
  //         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildGuestFeature(String feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feature,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
