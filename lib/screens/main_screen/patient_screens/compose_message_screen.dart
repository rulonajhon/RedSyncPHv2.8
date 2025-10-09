import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../shared/chat_screen.dart';
import '../../../services/data_sharing_service.dart';
import '../../../services/doctor_availability_service.dart';
import 'care_provider_screen.dart';

class ComposeMessageScreen extends StatefulWidget {
  const ComposeMessageScreen({super.key});

  @override
  State<ComposeMessageScreen> createState() => _ComposeMessageScreenState();
}

class _ComposeMessageScreenState extends State<ComposeMessageScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DataSharingService _dataSharingService = DataSharingService();
  final DoctorAvailabilityService _availabilityService =
      DoctorAvailabilityService();

  List<Map<String, dynamic>> _healthcareProviders = [];
  List<Map<String, dynamic>> _filteredProviders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHealthcareProviders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHealthcareProviders() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get only healthcare providers who have active data sharing agreements with this patient
      final authorizedProviders =
          await _dataSharingService.getAuthorizedHealthcareProviders();

      setState(() {
        _healthcareProviders = authorizedProviders;
        _filteredProviders = authorizedProviders;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading authorized healthcare providers: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load healthcare providers: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterProviders(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProviders = _healthcareProviders;
      } else {
        _filteredProviders = _healthcareProviders.where((provider) {
          final name = (provider['name'] ?? '').toString().toLowerCase();
          final email = (provider['email'] ?? '').toString().toLowerCase();
          final specialization =
              (provider['specialization'] ?? '').toString().toLowerCase();
          return name.contains(query.toLowerCase()) ||
              email.contains(query.toLowerCase()) ||
              specialization.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _startChatWithProvider(Map<String, dynamic> provider) async {
    // Check doctor availability first
    final availability =
        await _availabilityService.checkDoctorAvailability(provider['id']);

    if (!availability['isAvailable']) {
      _showAvailabilityDialog(provider, availability);
      return;
    }

    // Doctor is available, proceed with chat
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          participant: {
            'id': provider['id'],
            'name': provider['name'],
            'role': provider['role'],
            'profilePicture': provider['profilePicture'],
            'specialization': provider['specialization'],
          },
          currentUserRole: 'patient',
        ),
      ),
    );
  }

  void _showAvailabilityDialog(
      Map<String, dynamic> provider, Map<String, dynamic> availability) {
    String dialogTitle;
    String dialogMessage;
    String buttonText;
    Color iconColor;
    IconData iconData;

    switch (availability['reason']) {
      case 'messages_disabled':
        dialogTitle = 'Messages Disabled';
        dialogMessage =
            'Dr. ${provider['name']} is currently not accepting messages. Please try again later or contact them through other means.';
        buttonText = 'Understood';
        iconColor = Colors.red;
        iconData = FontAwesomeIcons.ban;
        break;
      case 'day_unavailable':
        dialogTitle = 'Not Available Today';
        final availableDays =
            List<String>.from(availability['availableDays'] ?? []);
        dialogMessage =
            'Dr. ${provider['name']} is not available for messages today.\n\nAvailable days: ${availableDays.join(', ')}';
        buttonText = 'Got it';
        iconColor = Colors.orange;
        iconData = FontAwesomeIcons.calendar;
        break;
      case 'time_unavailable':
        dialogTitle = 'Outside Available Hours';
        final availableHours = availability['availableHours'];
        dialogMessage =
            'Dr. ${provider['name']} is currently outside their available hours.\n\nAvailable: ${availableHours['start']} - ${availableHours['end']}';
        buttonText = 'Understood';
        iconColor = Colors.blue;
        iconData = FontAwesomeIcons.clock;
        break;
      default:
        dialogTitle = 'Unavailable';
        dialogMessage = availability['message'] ??
            'This doctor is currently unavailable for messages.';
        buttonText = 'OK';
        iconColor = Colors.grey;
        iconData = FontAwesomeIcons.exclamation;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(iconData, color: iconColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  dialogTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            dialogMessage,
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                buttonText,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'New Message',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.redAccent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(FontAwesomeIcons.arrowLeft, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Header section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade100, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        FontAwesomeIcons.userDoctor,
                        color: Colors.redAccent,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Healthcare Provider',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Message your authorized providers',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        FontAwesomeIcons.shield,
                        color: Colors.blue.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Only providers with active data sharing agreements are shown',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Container(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filterProviders,
                decoration: InputDecoration(
                  hintText: 'Search providers by name or specialization...',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  prefixIcon: Container(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      FontAwesomeIcons.magnifyingGlass,
                      color: Colors.grey.shade500,
                      size: 16,
                    ),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ),

          // Healthcare Providers List
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.redAccent,
                            strokeWidth: 2.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading healthcare providers...',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : _filteredProviders.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _filteredProviders.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final provider = _filteredProviders[index];
                          return _buildProviderItem(provider);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    bool isSearchEmpty = _searchController.text.isNotEmpty &&
        _filteredProviders.isEmpty &&
        _healthcareProviders.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isSearchEmpty
                    ? Colors.grey.shade100
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                isSearchEmpty
                    ? FontAwesomeIcons.magnifyingGlass
                    : FontAwesomeIcons.userShield,
                color: isSearchEmpty
                    ? Colors.grey.shade400
                    : Colors.orange.shade400,
                size: 32,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isSearchEmpty ? 'No providers found' : 'No authorized providers',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearchEmpty
                  ? 'Try adjusting your search criteria'
                  : 'You can only message healthcare providers with active data sharing agreements.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (!isSearchEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    Icon(
                      FontAwesomeIcons.lightbulb,
                      color: Colors.blue.shade600,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Data sharing allows your healthcare provider to access your health data for better care coordination.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _navigateToAddCareProvider,
                  icon: const Icon(FontAwesomeIcons.userPlus, size: 16),
                  label: const Text(
                    'Add Care Provider',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProviderItem(Map<String, dynamic> provider) {
    return InkWell(
      onTap: () => _startChatWithProvider(provider),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Provider Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: provider['profilePicture'] != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        provider['profilePicture'],
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(
                      FontAwesomeIcons.userDoctor,
                      color: Colors.blue.shade600,
                      size: 24,
                    ),
            ),
            const SizedBox(width: 16),

            // Provider Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider['name'] ?? 'Unknown Provider',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (provider['specialization'] != null &&
                      provider['specialization'].isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        provider['specialization'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),

                  // Availability Status
                  FutureBuilder<Map<String, dynamic>>(
                    future: _availabilityService
                        .checkDoctorAvailability(provider['id']),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 10,
                                height: 10,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Checking...',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (!snapshot.hasData) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Status unknown',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        );
                      }

                      final availability = snapshot.data!;
                      final isAvailable = availability['isAvailable'] ?? false;

                      Color statusColor;
                      IconData statusIcon;
                      String statusText;

                      if (isAvailable) {
                        statusColor = Colors.green;
                        statusIcon = FontAwesomeIcons.circle;
                        statusText = 'Available now';
                      } else {
                        switch (availability['reason']) {
                          case 'messages_disabled':
                            statusColor = Colors.red;
                            statusIcon = FontAwesomeIcons.ban;
                            statusText = 'Messages disabled';
                            break;
                          case 'day_unavailable':
                            statusColor = Colors.orange;
                            statusIcon = FontAwesomeIcons.calendar;
                            statusText = 'Not available today';
                            break;
                          case 'time_unavailable':
                            statusColor = Colors.blue;
                            statusIcon = FontAwesomeIcons.clock;
                            statusText = 'Outside office hours';
                            break;
                          default:
                            statusColor = Colors.grey;
                            statusIcon = FontAwesomeIcons.exclamation;
                            statusText = 'Unavailable';
                        }
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: statusColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              statusIcon,
                              color: statusColor,
                              size: isAvailable ? 8 : 10,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 11,
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  if (provider['email'] != null &&
                      provider['email'].isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      provider['email'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Message Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(FontAwesomeIcons.message, color: Colors.white, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'Message',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAddCareProvider() {
    // Navigate to the care provider screen for provider search
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CareProviderScreen()),
    ).then((_) {
      // Refresh the providers list when returning from the care provider screen
      _loadHealthcareProviders();
    });
  }
}
