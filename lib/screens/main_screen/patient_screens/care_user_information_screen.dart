import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hemophilia_manager/services/firestore.dart'; // Update with your actual import

class CareUserInformationScreen extends StatefulWidget {
  const CareUserInformationScreen({super.key});

  @override
  State<CareUserInformationScreen> createState() =>
      _CareUserInformationScreenState();
}

class _CareUserInformationScreenState extends State<CareUserInformationScreen> {
  bool _shareData = false;
  bool _isLoading = false;

  Future<void> _toggleDataSharing(bool value) async {
    setState(() => _isLoading = true);

    try {
      final provider =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final currentUser = FirebaseAuth.instance.currentUser;

      if (provider == null || currentUser == null) {
        throw Exception('Missing provider or user information');
      }

      if (value) {
        // Send data sharing request
        await FirebaseFirestore.instance
            .collection('data_sharing_requests')
            .add({
          'patientUid': currentUser.uid,
          'providerUid': provider['id'],
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Send notification to provider
        await FirestoreService().createNotification(
          provider['id'],
          'New data sharing request from ${currentUser.email ?? 'a patient'}',
        );

        _showSnackBar('Data sharing request sent successfully!', Colors.green);
      } else {
        // Remove data sharing
        final existingSharing = await FirebaseFirestore.instance
            .collection('data_sharing')
            .where('patientUid', isEqualTo: currentUser.uid)
            .where('providerUid', isEqualTo: provider['id'])
            .where('active', isEqualTo: true)
            .get();

        if (existingSharing.docs.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('data_sharing')
              .doc(existingSharing.docs.first.id)
              .update({'active': false});

          _showSnackBar('Data sharing disabled', Colors.orange);
        }
      }

      setState(() => _shareData = value);
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Use a post frame callback to ensure the context is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkExistingDataSharing();
    });
  }

  Future<void> _checkExistingDataSharing() async {
    try {
      final provider =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final currentUser = FirebaseAuth.instance.currentUser;

      if (provider != null && currentUser != null) {
        // Check for active data sharing
        final existingSharing = await FirebaseFirestore.instance
            .collection('data_sharing')
            .where('patientUid', isEqualTo: currentUser.uid)
            .where('providerUid', isEqualTo: provider['id'])
            .where('active', isEqualTo: true)
            .get();

        // Also check for pending requests
        final pendingRequests = await FirebaseFirestore.instance
            .collection('data_sharing_requests')
            .where('patientUid', isEqualTo: currentUser.uid)
            .where('providerUid', isEqualTo: provider['id'])
            .where('status', isEqualTo: 'approved')
            .get();

        if (mounted) {
          setState(() {
            _shareData = existingSharing.docs.isNotEmpty ||
                pendingRequests.docs.isNotEmpty;
          });
        }
      }
    } catch (e) {
      print('Error checking existing data sharing: $e');
      if (mounted) {
        setState(() {
          _shareData = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Provider Information',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.redAccent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.redAccent),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (context) => Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ListTile(
                          leading: const Icon(Icons.report_outlined,
                              color: Colors.red),
                          title: const Text('Report Provider'),
                          onTap: () => Navigator.pop(context),
                        ),
                        ListTile(
                          leading: const Icon(Icons.block_outlined,
                              color: Colors.orange),
                          title: const Text('Block Provider'),
                          onTap: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Provider Profile Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.redAccent,
                            Colors.redAccent.shade700,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.local_hospital_rounded,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      provider?['name'] ?? 'Unknown Provider',
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider?['email'] ?? 'No email provided',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.redAccent.withOpacity(0.1),
                            Colors.redAccent.withOpacity(0.05)
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.redAccent.withOpacity(0.3)),
                      ),
                      child: const Text(
                        'Healthcare Professional',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Data Sharing Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _shareData
                        ? [
                            Colors.green.shade50,
                            Colors.green.shade100.withOpacity(0.3)
                          ]
                        : [
                            Colors.red.shade50,
                            Colors.red.shade100.withOpacity(0.3)
                          ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _shareData
                        ? Colors.green.shade200
                        : Colors.red.shade200,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_shareData ? Colors.green : Colors.red)
                          .withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _shareData
                                  ? [Colors.green, Colors.green.shade700]
                                  : [Colors.red.shade400, Colors.red.shade600],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: (_shareData ? Colors.green : Colors.red)
                                    .withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            _shareData
                                ? Icons.shield_rounded
                                : Icons.privacy_tip_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _shareData
                                    ? 'Data Sharing Active'
                                    : 'Share My Data',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: _shareData
                                      ? Colors.green.shade800
                                      : Colors.red.shade800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _shareData
                                    ? 'Connected with ${provider?['name'] ?? 'this provider'}'
                                    : 'Connect with ${provider?['name'] ?? 'this provider'}',
                                style: TextStyle(
                                  color: _shareData
                                      ? Colors.green.shade600
                                      : Colors.red.shade600,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _shareData
                              ? Colors.green.shade200
                              : Colors.red.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _shareData
                                  ? 'Your health data is securely shared with this provider'
                                  : 'Enable secure data sharing with this provider',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _shareData
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _isLoading
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _shareData ? Colors.green : Colors.red,
                                    ),
                                  ),
                                )
                              : Transform.scale(
                                  scale: 1.2,
                                  child: Switch(
                                    value: _shareData,
                                    onChanged: _toggleDataSharing,
                                    activeColor: Colors.green,
                                    inactiveThumbColor: Colors.red.shade300,
                                    inactiveTrackColor: Colors.red.shade100,
                                    trackOutlineColor:
                                        WidgetStateProperty.resolveWith<Color?>(
                                      (Set<WidgetState> states) {
                                        if (states
                                            .contains(WidgetState.selected)) {
                                          return Colors.green.shade300;
                                        }
                                        return Colors.red.shade200;
                                      },
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action Cards
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildActionTile(
                      icon: Icons.info_outline_rounded,
                      title: 'How does sharing my data work?',
                      subtitle: 'Learn about data sharing and privacy',
                      color: Colors.blue,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.security_rounded,
                                    color: Colors.blue,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Data Sharing Information',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            content: const Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'When you share your data:',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16),
                                ),
                                SizedBox(height: 12),
                                Text(
                                    '• Your bleed logs will be visible to this provider'),
                                SizedBox(height: 4),
                                Text(
                                    '• Your medication history will be shared'),
                                SizedBox(height: 4),
                                Text(
                                    '• Your dosage calculations will be accessible'),
                                SizedBox(height: 4),
                                Text('• You can revoke access at any time'),
                                SizedBox(height: 12),
                                Text(
                                  'Your data is encrypted and secure.',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.blue,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                ),
                                child: const Text(
                                  'Got it',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    Divider(height: 1, color: Colors.grey.shade200),
                    _buildActionTile(
                      icon: Icons.email_outlined,
                      title: 'Contact Provider',
                      subtitle: provider?['email'] ?? 'No email available',
                      color: Colors.orange,
                      onTap: () {
                        // TODO: Implement email functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Email functionality coming soon!'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      },
                    ),
                    if (_shareData) ...[
                      Divider(height: 1, color: Colors.grey.shade200),
                      _buildActionTile(
                        icon: Icons.message_outlined,
                        title: 'Send Message',
                        subtitle: 'Chat with your healthcare provider',
                        color: Colors.green,
                        onTap: () {
                          Navigator.pushNamed(context, '/messages');
                        },
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: color,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
