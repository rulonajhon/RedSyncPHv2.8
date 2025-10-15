import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/offline_service.dart';
import '../../../services/ai_emergency_service.dart';
import '../../../widgets/offline_indicator.dart';

class LogBleed extends StatefulWidget {
  const LogBleed({super.key});

  @override
  State<LogBleed> createState() => _LogBleedState();
}

class _LogBleedState extends State<LogBleed> {
  final PageController _pageController = PageController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _specificRegionController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final OfflineService _offlineService = OfflineService();

  int _currentPage = 0;
  bool _isSaving = false;

  final List<String> _pageTitles = [
    'Date & Time',
    'Body Region',
    'Severity Level',
    'Additional Notes',
    'Review & Save',
  ];

  String _bodyRegion = '';
  String _specificRegion = '';
  String _severity = '';

  final List<Map<String, dynamic>> _bodyRegions = [
    {
      'name': 'Head & Face',
      'icon': Icons.face,
      'regions': ['Forehead', 'Temple', 'Eye area', 'Nose', 'Mouth', 'Jaw']
    },
    {
      'name': 'Neck',
      'icon': Icons.person_outline,
      'regions': [
        'Front neck',
        'Back neck',
        'Left Side of the neck',
        'Right Side of the neck'
      ]
    },
    {
      'name': 'Chest',
      'icon': Icons.favorite_outline,
      'regions': ['Upper chest', 'Lower chest', 'Ribs']
    },
    {
      'name': 'Arms & Hands',
      'icon': Icons.back_hand,
      'regions': [
        'Left Shoulder',
        'Right Shoulder',
        'Upper arm',
        'Lower arm',
        'Left Elbow',
        'Right Elbow',
        'Left Forearm',
        'Right Forearm',
        'Left Wrist',
        'Right Wrist',
        'Left Hand',
        'Right Hand',
        'Left Fingers',
        'Right Fingers'
      ]
    },
    {
      'name': 'Abdomen',
      'icon': Icons.circle_outlined,
      'regions': [
        'Upper abdomen',
        'Lower abdomen',
        'Left abdomen',
        'Right abdomen'
      ]
    },
    {
      'name': 'Legs & Feet',
      'icon': Icons.directions_walk,
      'regions': [
        'Hip',
        'Thigh',
        'Left Thigh',
        'Right Thigh',
        'Knee',
        'Left Knee',
        'Right Knee',
        'Shin',
        'Left Calf',
        'Right Calf',
        'Ankle',
        'Left Ankle',
        'Right Ankle',
        'Foot',
        'Left Foot',
        'Right Foot',
        'Toes',
        'Left Toes',
        'Right Toes'
      ]
    },
  ];

  final List<Map<String, dynamic>> _severityLevels = [
    {
      'name': 'Mild',
      'icon': Icons.sentiment_satisfied,
      'color': Colors.green,
      'description': 'Minor bleeding, easily controlled'
    },
    {
      'name': 'Moderate',
      'icon': Icons.sentiment_neutral,
      'color': Colors.orange,
      'description': 'Noticeable bleeding, manageable'
    },
    {
      'name': 'Severe',
      'icon': Icons.sentiment_very_dissatisfied,
      'color': Colors.red,
      'description': 'Heavy bleeding, requires attention'
    },
  ];

  @override
  void initState() {
    super.initState();
    _setCurrentDateTime();
    _initOfflineService();
  }

  Future<void> _initOfflineService() async {
    try {
      await _offlineService.initialize();
    } catch (e) {
      print('Error initializing offline service: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _specificRegionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.redAccent),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _dateController.text = DateFormat('MMM dd, yyyy').format(picked);
    }
  }

  Future<void> _pickTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.redAccent),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final now = DateTime.now();
      final dt =
          DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      _timeController.text = DateFormat('hh:mm a').format(dt);
    }
  }

  void _setCurrentDateTime() {
    final now = DateTime.now();
    _dateController.text = DateFormat('MMM dd, yyyy').format(now);
    _timeController.text = DateFormat('hh:mm a').format(now);
  }

  void _nextPage() {
    if (_canProceed()) {
      if (_currentPage < 4) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      _showValidationMessage();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _canProceed() {
    switch (_currentPage) {
      case 0:
        return _dateController.text.isNotEmpty &&
            _timeController.text.isNotEmpty;
      case 1:
        return _bodyRegion.isNotEmpty;
      case 2:
        return _severity.isNotEmpty;
      case 3:
        return true; // Notes are optional
      default:
        return true;
    }
  }

  void _showValidationMessage() {
    String message = '';
    switch (_currentPage) {
      case 0:
        message = 'Please select both date and time';
        break;
      case 1:
        message = 'Please select a body region';
        break;
      case 2:
        message = 'Please select severity level';
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _saveLog() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        // Save using offline service which handles both offline and online scenarios
        await _offlineService.saveBleedLogOffline(
          date: _dateController.text,
          time: _timeController.text,
          bodyRegion: _bodyRegion,
          severity: _severity,
          specificRegion: _specificRegion,
          notes: _notesController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Bleed log saved successfully!'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );

          // Show emergency first-aid guidance after successful save
          _showEmergencyGuidance();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showEmergencyGuidance() async {
    // Show loading dialog while AI generates guidance
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Generate AI-powered guidance
      final guidance = await AIEmergencyService.generateEmergencyGuidance(
        severity: _severity,
        bodyRegion: _bodyRegion,
        notes: _notesController.text.trim(),
        dateTime: DateTime.now(),
        // Add more context if available from user profile
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show AI guidance or fallback to static guidance
      _showGuidanceModal(guidance);
    } catch (e) {
      // Close loading dialog and show fallback
      if (mounted) Navigator.pop(context);
      final fallbackGuidance = _getEmergencyGuidance(_severity, _bodyRegion);
      _showGuidanceModal(fallbackGuidance);
    }
  }

  void _showGuidanceModal(Map<String, dynamic> guidance) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: guidance['urgencyColor'].withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: guidance['urgencyColor'].withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          guidance['icon'],
                          size: 32,
                          color: guidance['urgencyColor'],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              guidance['title'],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: guidance['urgencyColor'],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              guidance['subtitle'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (guidance['aiGenerated'] == true)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.psychology,
                                color: Colors.purple.shade600,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'AI',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.purple.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Immediate Actions
                    _buildGuidanceSection(
                      'Immediate Actions',
                      Icons.flash_on,
                      guidance['immediateActions'],
                      Colors.orange,
                    ),

                    const SizedBox(height: 20),

                    // First Aid Steps
                    _buildGuidanceSection(
                      'First Aid Steps',
                      Icons.healing,
                      guidance['firstAidSteps'],
                      Colors.blue,
                    ),

                    const SizedBox(height: 20),

                    // When to Seek Help
                    _buildGuidanceSection(
                      'Seek Medical Help If',
                      Icons.local_hospital,
                      guidance['whenToSeekHelp'],
                      Colors.red,
                    ),

                    if (guidance['additionalTips'].isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildGuidanceSection(
                        'Monitor For',
                        Icons.visibility,
                        guidance['additionalTips'],
                        Colors.purple,
                      ),
                    ],

                    // Compact recovery info for AI guidance
                    if (guidance['aiGenerated'] == true &&
                        guidance['estimatedRecovery'] != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.access_time,
                                color: Colors.blue.shade600, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Expected Recovery: ${guidance['estimatedRecovery']}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade700,
                                ),
                                overflow: TextOverflow.visible,
                                softWrap: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Emergency Contact
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.emergency,
                                  color: Colors.red.shade600, size: 24),
                              const SizedBox(width: 12),
                              Text(
                                'Emergency Contact',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'If this is a severe bleeding emergency, call 911 immediately or go to the nearest emergency room.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Action button
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: guidance['urgencyColor'],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Got it',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidanceSection(
      String title, IconData icon, List<String> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final item = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$index',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Map<String, dynamic> _getEmergencyGuidance(
      String severity, String bodyRegion) {
    // Determine urgency level and basic guidance based on severity
    Color urgencyColor;
    IconData icon;
    String title;
    String subtitle;
    List<String> immediateActions;
    List<String> firstAidSteps;
    List<String> whenToSeekHelp;
    List<String> additionalTips;

    // Base guidance by severity
    switch (severity.toLowerCase()) {
      case 'severe':
        urgencyColor = Colors.red;
        icon = Icons.medical_services;
        title = 'SEVERE Bleeding Episode';
        subtitle = 'Immediate medical attention may be required';
        immediateActions = [
          'Stay calm and sit or lie down immediately',
          'Do not move the affected area unless necessary',
          'Apply direct pressure if external bleeding is visible',
          'Contact your healthcare provider or emergency services',
        ];
        whenToSeekHelp = [
          'Immediately - this is a medical emergency',
          'If bleeding doesn\'t stop within 15-20 minutes',
          'If you experience dizziness, weakness, or rapid heartbeat',
          'If the joint becomes very swollen or painful',
        ];
        break;

      case 'moderate':
        urgencyColor = Colors.orange;
        icon = Icons.warning;
        title = 'MODERATE Bleeding Episode';
        subtitle = 'Requires prompt treatment and monitoring';
        immediateActions = [
          'Stop current activity and rest the affected area',
          'Apply ice wrapped in a cloth to reduce swelling',
          'Elevate the affected area if possible',
          'Consider taking your prescribed clotting factor',
        ];
        whenToSeekHelp = [
          'If bleeding continues for more than 30 minutes',
          'If pain becomes severe or worsens',
          'If swelling increases significantly',
          'If you develop fever or signs of infection',
        ];
        break;

      default: // mild
        urgencyColor = Colors.green;
        icon = Icons.healing;
        title = 'MILD Bleeding Episode';
        subtitle = 'Monitor closely and apply basic first aid';
        immediateActions = [
          'Rest and avoid further stress to the area',
          'Apply ice for 15-20 minutes to reduce inflammation',
          'Keep the affected area elevated when possible',
          'Monitor for any worsening symptoms',
        ];
        whenToSeekHelp = [
          'If bleeding persists for more than 1 hour',
          'If symptoms worsen or new symptoms develop',
          'If you have concerns about your condition',
          'As part of your regular healthcare follow-up',
        ];
    }

    // Location-specific guidance
    if (bodyRegion.toLowerCase().contains('joint') ||
        bodyRegion.toLowerCase().contains('knee') ||
        bodyRegion.toLowerCase().contains('elbow') ||
        bodyRegion.toLowerCase().contains('ankle') ||
        bodyRegion.toLowerCase().contains('shoulder')) {
      firstAidSteps = [
        'Rest: Stop all activity and avoid putting weight on the joint',
        'Ice: Apply cold pack for 15-20 minutes, repeat every 2-3 hours',
        'Compression: Use elastic bandage if recommended by your doctor',
        'Elevation: Raise the affected limb above heart level when possible',
        'Factor: Consider clotting factor replacement as prescribed',
      ];

      additionalTips = [
        'Joint bleeds can cause long-term damage if not treated properly',
        'Keep the joint immobilized until bleeding stops',
        'Gentle range-of-motion exercises may help after acute phase',
        'Document the episode for your healthcare provider',
      ];
    } else if (bodyRegion.toLowerCase().contains('muscle') ||
        bodyRegion.toLowerCase().contains('arm') ||
        bodyRegion.toLowerCase().contains('leg')) {
      firstAidSteps = [
        'Immediately stop the activity that caused the bleeding',
        'Apply gentle pressure around (not directly on) the affected area',
        'Use ice packs wrapped in cloth for 15-20 minutes',
        'Keep the area elevated and supported',
        'Avoid massage or heat application',
      ];

      additionalTips = [
        'Muscle bleeds can be very painful and cause compartment syndrome',
        'Watch for increasing tightness or numbness',
        'Gentle stretching may help prevent stiffness later',
        'Maintain hydration and rest',
      ];
    } else if (bodyRegion.toLowerCase().contains('head') ||
        bodyRegion.toLowerCase().contains('neck') ||
        bodyRegion.toLowerCase().contains('face')) {
      urgencyColor = Colors.red; // Head bleeds are always more serious

      firstAidSteps = [
        'Keep head elevated and avoid sudden movements',
        'Apply gentle pressure to external bleeding only',
        'Do NOT apply pressure to eyes, ears, or inside mouth',
        'Monitor for changes in consciousness or vision',
        'Seek immediate medical attention',
      ];

      whenToSeekHelp = [
        'IMMEDIATELY - head/neck bleeds are medical emergencies',
        'Any change in vision, hearing, or consciousness',
        'Severe headache or neck pain',
        'Difficulty speaking or swallowing',
      ];

      additionalTips = [
        'Head and neck bleeds can be life-threatening',
        'Do not give anything by mouth if consciousness is altered',
        'Keep airway clear',
        'Call emergency services if in doubt',
      ];
    } else {
      // General/other locations
      firstAidSteps = [
        'Clean your hands before providing first aid',
        'Apply direct pressure to external bleeding with clean cloth',
        'Use ice to reduce swelling and pain',
        'Keep the affected area at rest',
        'Monitor the area for changes in size, color, or pain',
      ];

      additionalTips = [
        'Keep a record of bleeding episodes for your doctor',
        'Take photos if safe to do so for medical documentation',
        'Stay hydrated and get adequate rest',
        'Follow up with your healthcare team as recommended',
      ];
    }

    return {
      'urgencyColor': urgencyColor,
      'icon': icon,
      'title': title,
      'subtitle': subtitle,
      'immediateActions': immediateActions,
      'firstAidSteps': firstAidSteps,
      'whenToSeekHelp': whenToSeekHelp,
      'additionalTips': additionalTips,
    };
  }

  Widget _buildDateTimePage() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.schedule,
                size: 48,
                color: Colors.redAccent,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'When did the bleeding occur?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select the date and time when you noticed the bleeding',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.calendar_today,
                        color: Colors.redAccent, size: 20),
                  ),
                  title: const Text('Date',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(_dateController.text.isEmpty
                      ? 'Select date'
                      : _dateController.text),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: _pickDate,
                ),
                Divider(height: 1, color: Colors.grey.shade200),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.access_time,
                        color: Colors.redAccent, size: 20),
                  ),
                  title: const Text('Time',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(_timeController.text.isEmpty
                      ? 'Select time'
                      : _timeController.text),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: _pickTime,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Current date and time are pre-selected. Change if needed.',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyRegionPage() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.accessibility_new,
                size: 48,
                color: Colors.redAccent,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Where did the bleeding occur?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select the body region where you experienced bleeding',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.all(3),
                itemCount: _bodyRegions.length,
                separatorBuilder: (context, index) =>
                    Divider(height: 1, color: Colors.grey.shade200),
                itemBuilder: (context, index) {
                  final region = _bodyRegions[index];
                  final isSelected = _bodyRegion == region['name'];

                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.redAccent.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        region['icon'],
                        color: isSelected
                            ? Colors.redAccent
                            : Colors.grey.shade600,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      region['name'],
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.redAccent : Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      '${region['regions'].length} areas',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle,
                            color: Colors.redAccent)
                        : const Icon(Icons.chevron_right, color: Colors.grey),
                    selected: isSelected,
                    selectedTileColor: Colors.redAccent.withOpacity(0.05),
                    onTap: () {
                      setState(() {
                        _bodyRegion = region['name'];
                        _specificRegion = '';
                      });
                      _showSpecificRegionDialog(region);
                    },
                  );
                },
              ),
            ),
          ),
          if (_bodyRegion.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Selected: $_bodyRegion${_specificRegion.isNotEmpty ? ' - $_specificRegion' : ''}',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showSpecificRegionDialog(Map<String, dynamic> region) {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(region['icon'], color: Colors.redAccent),
                const SizedBox(width: 12),
                Text(
                  'Specific area in ${region['name']}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Select a specific area (optional)',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: ListView.separated(
                itemCount: region['regions'].length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: Colors.grey.shade300,
                ),
                itemBuilder: (context, index) {
                  final specificArea = region['regions'][index];
                  return ListTile(
                    title: Text(specificArea),
                    trailing: _specificRegion == specificArea
                        ? const Icon(Icons.check, color: Colors.redAccent)
                        : null,
                    onTap: () {
                      setState(() {
                        _specificRegion = specificArea;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Skip'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeverityPage() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.thermostat,
                size: 48,
                color: Colors.redAccent,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'How severe was the bleeding?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Rate the severity level to help track your condition',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: _severityLevels.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final level = _severityLevels[index];
                final isSelected = _severity == level['name'];

                return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? level['color'] as Color
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (level['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          level['icon'],
                          color: level['color'] as Color,
                          size: 24,
                        ),
                      ),
                      title: Text(
                        level['name'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? level['color'] as Color
                              : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        level['description'],
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle,
                              color: level['color'] as Color)
                          : null,
                      onTap: () {
                        setState(() {
                          _severity = level['name'];
                        });
                      },
                    ));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesPage() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.note_add,
                  size: 48,
                  color: Colors.redAccent,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Additional Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add any additional details about this episode (optional)',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _notesController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText:
                      'What were you doing? Any triggers? Pain level? Treatment taken?',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline,
                      color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Include details that help identify patterns or triggers',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                      ),
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

  Widget _buildReviewPage() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.fact_check,
                size: 48,
                color: Colors.redAccent,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Review Your Entry',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please review the information before saving',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ListView(
                padding: const EdgeInsets.all(3),
                children: [
                  _buildReviewItem(
                      'Date', _dateController.text, Icons.calendar_today),
                  _buildReviewItem(
                      'Time', _timeController.text, Icons.access_time),
                  _buildReviewItem(
                      'Body Region', _bodyRegion, Icons.accessibility_new),
                  if (_specificRegion.isNotEmpty)
                    _buildReviewItem(
                        'Specific Area', _specificRegion, Icons.location_on),
                  _buildReviewItem('Severity', _severity, Icons.thermostat),
                  if (_notesController.text.trim().isNotEmpty)
                    _buildReviewItem(
                        'Notes', _notesController.text.trim(), Icons.note),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveLog,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Saving...' : 'Save Bleed Log'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(String label, String value, IconData icon) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      leading: Icon(icon, color: Colors.redAccent, size: 20),
      title: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        value.isEmpty ? 'Not specified' : value,
        style: TextStyle(
          fontSize: 13,
          color: value.isEmpty ? Colors.grey : Colors.black87,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          _pageTitles[_currentPage],
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          const OfflineIndicator(),
          Expanded(
            child: SafeArea(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Step ${_currentPage + 1} of 5',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${(((_currentPage + 1) / 5) * 100).round()}%',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (_currentPage + 1) / 5,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (page) =>
                          setState(() => _currentPage = page),
                      children: [
                        _buildDateTimePage(),
                        _buildBodyRegionPage(),
                        _buildSeverityPage(),
                        _buildNotesPage(),
                        _buildReviewPage(),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        if (_currentPage > 0)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _prevPage,
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Back'),
                            ),
                          ),
                        if (_currentPage > 0) const SizedBox(width: 12),
                        if (_currentPage < 4)
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _nextPage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Continue'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// TODO: Add insert image or capture functionality
