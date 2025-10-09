import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hemophilia_manager/auth/auth.dart';
import 'package:hemophilia_manager/services/firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CreateAccPage extends StatefulWidget {
  const CreateAccPage({super.key});

  @override
  State<CreateAccPage> createState() => _CreateAccPageState();
}

class _CreateAccPageState extends State<CreateAccPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  // final TextEditingController _phoneController = TextEditingController(); // Currently not used
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _showRoleSelection = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _createdUid;

  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final name = _nameController.text.trim();
    // final phone = _phoneController.text.trim(); // Currently not used

    if (password != confirmPassword) {
      _showNotice('Passwords do not match');
      return;
    }

    // Show terms and conditions popup before proceeding
    _showTermsForRegistration(email, password, name);
  }

  void _showTermsForRegistration(String email, String password, String name) {
    showDialog(
      context: context,
      barrierDismissible: false, // User must interact with dialog
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Terms and Conditions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'RedSync PH Terms of Service',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  '1. Acceptance of Terms',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Text(
                  'By using RedSync PH, you agree to these terms and conditions. This app is designed to help manage hemophilia care and connect patients with healthcare providers.',
                ),
                SizedBox(height: 16),
                Text(
                  '2. Medical Disclaimer',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Text(
                  'This app is for informational purposes only. It is not a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of qualified healthcare providers.',
                ),
                SizedBox(height: 16),
                Text(
                  '3. Data Privacy',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Text(
                  'We respect your privacy and are committed to protecting your personal information. Your health data is encrypted and securely stored. We will never share your personal information without your explicit consent.',
                ),
                SizedBox(height: 16),
                Text(
                  '4. User Responsibilities',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Text(
                  'Users are responsible for providing accurate information and using the app responsibly. Medical professionals must verify their credentials through our verification process.',
                ),
                SizedBox(height: 16),
                Text(
                  '5. Emergency Situations',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Text(
                  'This app is not intended for emergency situations. In case of a medical emergency, immediately contact local emergency services or go to the nearest hospital.',
                ),
                SizedBox(height: 16),
                Text(
                  '6. Data Collection',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Text(
                  'We collect minimal necessary data to provide our services including: name, email, medical information (for patients), and professional credentials (for healthcare providers). Location data is used only for clinic locator services.',
                ),
                SizedBox(height: 16),
                Text(
                  'By continuing, you acknowledge that you have read and agree to these terms and our Privacy Policy.',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _proceedWithRegistration(email, password, name);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('I Agree'),
            ),
          ],
        );
      },
    );
  }

  void _proceedWithRegistration(
      String email, String password, String name) async {
    setState(() => _isLoading = true);
    try {
      final user = await AuthService().createAccount(email, password);
      if (user != null) {
        _createdUid = user.uid;
        // Store user info in Firestore with temporary role
        await FirestoreService().createUser(user.uid, name, email, 'pending');
        setState(() {
          _showRoleSelection = true;
        });
      } else {
        _showNotice('Registration failed');
      }
    } catch (e) {
      _showNotice(e.toString());
    }
    setState(() => _isLoading = false);
  }

  void _showNotice(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Notice'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _selectRole(String role) async {
    if (_createdUid == null) return;
    setState(() => _isLoading = true);

    // For medical professionals, add verification status and expiry date
    Map<String, dynamic>? extraData;
    if (role == 'medical') {
      final expiryDate = DateTime.now().add(const Duration(days: 10));
      extraData = {
        'isVerified': false,
        'verificationExpiry': expiryDate.toIso8601String(),
        'verificationDocuments': [],
        'verificationStatus': 'pending', // pending, approved, rejected
      };
    }

    await FirestoreService().updateUser(
      _createdUid!,
      _nameController.text.trim(),
      _emailController.text.trim(),
      role,
      extra: extraData,
    );

    // Store authentication data in secure storage
    final secureStorage = const FlutterSecureStorage();
    await secureStorage.write(key: 'isLoggedIn', value: 'true');
    await secureStorage.write(key: 'userRole', value: role);
    await secureStorage.write(key: 'userUid', value: _createdUid!);

    setState(() => _isLoading = false);

    // Navigate to appropriate screen and clear navigation stack
    if (role == 'medical') {
      Navigator.pushNamedAndRemoveUntil(
          context, '/healthcare_main', (route) => false);
    } else if (role == 'caregiver') {
      Navigator.pushNamedAndRemoveUntil(
          context,
          '/user_screen',
          (route) =>
              false); // Fixed: caregiver should go to user_screen, not caregiver_main
    } else {
      Navigator.pushNamedAndRemoveUntil(
          context, '/user_screen', (route) => false);
    }
  }

  Widget _buildPasswordToggleIcon(bool obscureText, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(
        obscureText ? Icons.visibility : Icons.visibility_off,
        color: Colors.grey.shade600,
      ),
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
            child: !_showRoleSelection
                ? Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 12),
                        Image.asset('assets/images/app_logo.png',
                            width: 80, height: 80),
                        const SizedBox(height: 18),
                        const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Join RedSyncPH and start managing your hemophilia care.',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        _buildInputField(
                          controller: _nameController,
                          label: 'Full Name',
                          icon: Icons.person_outline,
                          keyboardType: TextInputType.name,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Enter name'
                              : null,
                        ),
                        const SizedBox(height: 18),
                        _buildInputField(
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Enter email';
                            if (!value.contains('@'))
                              return 'Enter valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        _buildInputField(
                          controller: _passwordController,
                          label: 'Password',
                          icon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          suffixIcon:
                              _buildPasswordToggleIcon(_obscurePassword, () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          }),
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Enter password';
                            if (value.length < 6)
                              return 'Password must be at least 6 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        _buildInputField(
                          controller: _confirmPasswordController,
                          label: 'Confirm Password',
                          icon: Icons.lock_outline,
                          obscureText: _obscureConfirmPassword,
                          suffixIcon: _buildPasswordToggleIcon(
                              _obscureConfirmPassword, () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          }),
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Confirm your password';
                            if (value != _passwordController.text)
                              return 'Passwords do not match';
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text(
                                    'Register',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'By clicking Register, you will be asked to review and accept our Terms and Conditions.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Already have an account?',
                              style: TextStyle(
                                  color: Colors.black87, fontSize: 14),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacementNamed(
                                    context, '/login');
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                padding: EdgeInsets.zero,
                              ),
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      const Text(
                        'Select Your Role',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _roleTile(
                        icon: FontAwesomeIcons.person,
                        title: 'I\'m a Patient',
                        subtitle: 'I want to track my own health',
                        color: Colors.redAccent,
                        onTap: () => _selectRole('patient'),
                      ),
                      const SizedBox(height: 12),
                      _roleTile(
                        icon: FontAwesomeIcons.personBreastfeeding,
                        title: 'I\'m a Caregiver',
                        subtitle: 'I want to track someone else\'s health',
                        color: Colors.orangeAccent,
                        onTap: () => _selectRole('caregiver'),
                      ),
                      const SizedBox(height: 12),
                      _roleTile(
                        icon: FontAwesomeIcons.userDoctor,
                        title: 'I\'m a Medical Professional',
                        subtitle:
                            'I want to track patients who have hemophilia',
                        color: Colors.blueAccent,
                        onTap: () => _selectRole('medical'),
                      ),
                      const SizedBox(height: 24),
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator()),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.redAccent),
        suffixIcon: suffixIcon,
        border: const UnderlineInputBorder(),
        labelStyle: TextStyle(color: Colors.grey.shade700),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
    );
  }

  Widget _roleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      tileColor: color.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      leading: Icon(icon, size: 32, color: color),
      title: Text(
        title,
        style:
            TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 17),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.black87, fontSize: 14),
      ),
      trailing: Icon(Icons.arrow_forward_ios, color: color, size: 20),
      onTap: onTap,
    );
  }
}
