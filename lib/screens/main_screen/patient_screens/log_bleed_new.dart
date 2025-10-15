import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/firestore.dart';
import '../../../services/ai_emergency_service.dart';

// Simple BleedLog class for this screen
class BleedLog {
  String date;
  String time;
  String bodyRegion;
  String severity;
  String? specificRegion;
  String? notes;
  String? photoUrl;

  BleedLog({
    required this.date,
    required this.time,
    required this.bodyRegion,
    required this.severity,
    this.specificRegion,
    this.notes,
    this.photoUrl,
  });
}

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
  final FirestoreService _firestoreService = FirestoreService();

  int _currentPage = 0;
  bool _isSaving = false;

  final List<String> _pageTitles = [
    'When did this happen?',
    'Which body region?',
    'How severe was it?',
    'Additional notes',
    'Add a photo',
    'Review & Save',
  ];

  final List<String> _pageSubtitles = [
    'Select the date and time of the bleed',
    'Tap the area where the bleed occurred',
    'Rate the severity of the bleed',
    'Add any additional information (optional)',
    'Upload a photo (optional)',
    'Check your information before saving',
  ];

  String _bodyRegion = '';
  String _specificRegion = '';
  String _severity = '';
  bool _showSpecificInput = false;

  final Map<String, List<String>> _regionOptions = {
    'Head': ['Forehead', 'Temple', 'Eye area', 'Nose', 'Mouth', 'Jaw', 'Other'],
    'Neck': ['Front', 'Back', 'Side', 'Other'],
    'Chest': ['Upper chest', 'Lower chest', 'Ribs', 'Other'],
    'Arm': [
      'Shoulder',
      'Upper arm',
      'Elbow',
      'Forearm',
      'Wrist',
      'Hand',
      'Fingers',
      'Other',
    ],
    'Abdomen': ['Upper abdomen', 'Lower abdomen', 'Side', 'Other'],
    'Leg': [
      'Hip',
      'Thigh',
      'Knee',
      'Shin',
      'Calf',
      'Ankle',
      'Foot',
      'Toes',
      'Other',
    ],
    'Foot': ['Heel', 'Arch', 'Toes', 'Top of foot', 'Ankle', 'Other'],
    'Other': ['Specify location'],
  };

  @override
  void initState() {
    super.initState();
    _setCurrentDateTime();
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
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _pickTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final now = DateTime.now();
      final dt = DateTime(
        now.year,
        now.month,
        now.day,
        picked.hour,
        picked.minute,
      );
      _timeController.text = DateFormat('hh:mm a').format(dt);
    }
  }

  void _setCurrentDateTime() {
    final now = DateTime.now();
    _dateController.text = DateFormat('yyyy-MM-dd').format(now);
    _timeController.text = DateFormat('hh:mm a').format(now);
  }

  void _nextPage() {
    if (_currentPage < 5) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
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

  Future<void> _saveLog() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final finalBodyRegion = _specificRegion.isNotEmpty
          ? '$_bodyRegion - $_specificRegion'
          : _bodyRegion;

      // Save to Firestore
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await _firestoreService.saveBleedLog(
          uid: uid,
          date: _dateController.text,
          time: _timeController.text,
          bodyRegion: finalBodyRegion,
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
                  Expanded(child: Text('Bleed log saved successfully!')),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Show emergency first-aid guidance after successful save
          _showEmergencyGuidance();
        }
      } else {
        throw Exception('User not authenticated');
      }
    } catch (e) {
      print('Error saving bleed log: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save bleed log: ${e.toString()}'),
            backgroundColor: Colors.red,
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
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

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
    return Column(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.schedule,
                size: 80,
                color: Colors.redAccent.withOpacity(0.7),
              ),
              const SizedBox(height: 40),
              Text(
                'Date and time have been set to now. Tap to change if needed.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Colors.redAccent,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Date',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _dateController.text.isEmpty
                                  ? 'Select Date'
                                  : _dateController.text,
                              style: TextStyle(
                                fontSize: 16,
                                color: _dateController.text.isEmpty
                                    ? Colors.grey
                                    : Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickTime,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: Colors.redAccent,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Time',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _timeController.text.isEmpty
                                  ? 'Select Time'
                                  : _timeController.text,
                              style: TextStyle(
                                fontSize: 16,
                                color: _timeController.text.isEmpty
                                    ? Colors.grey
                                    : Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBodyRegionPage() {
    final regions = [
      {'name': 'Head', 'icon': Icons.face},
      {'name': 'Neck', 'icon': Icons.person},
      {'name': 'Chest', 'icon': Icons.favorite},
      {'name': 'Arm', 'icon': Icons.back_hand},
      {'name': 'Abdomen', 'icon': Icons.circle},
      {'name': 'Leg', 'icon': Icons.directions_walk},
      {'name': 'Foot', 'icon': Icons.directions_run},
      {'name': 'Other', 'icon': Icons.more_horiz},
    ];

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Icon(
                  Icons.accessibility_new,
                  size: 60,
                  color: Colors.redAccent.withOpacity(0.7),
                ),
                const SizedBox(height: 24),

                // Body Region Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                  ),
                  itemCount: regions.length,
                  itemBuilder: (context, index) {
                    final region = regions[index];
                    final isSelected = _bodyRegion == region['name'];

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _bodyRegion = region['name'] as String;
                          _specificRegion = '';
                          _specificRegionController.clear();
                          _showSpecificInput = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.redAccent.withOpacity(0.1)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.redAccent
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              region['icon'] as IconData,
                              size: 28,
                              color: isSelected
                                  ? Colors.redAccent
                                  : Colors.grey.shade600,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              region['name'] as String,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: isSelected
                                    ? Colors.redAccent
                                    : Colors.grey.shade700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Specific Region Selection
                if (_bodyRegion.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Be more specific (optional)',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (!_showSpecificInput) ...[
                          DropdownButtonFormField<String>(
                            value: _specificRegion.isEmpty
                                ? null
                                : _specificRegion,
                            decoration: InputDecoration(
                              hintText: 'Select specific area',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items: _regionOptions[_bodyRegion]?.map((option) {
                                  return DropdownMenuItem<String>(
                                    value: option,
                                    child: Text(option),
                                  );
                                }).toList() ??
                                [],
                            onChanged: (value) {
                              setState(() {
                                _specificRegion = value ?? '';
                                if (value == 'Other' ||
                                    value == 'Specify location') {
                                  _showSpecificInput = true;
                                  _specificRegionController.clear();
                                }
                              });
                            },
                          ),
                        ] else ...[
                          TextField(
                            controller: _specificRegionController,
                            decoration: InputDecoration(
                              hintText: 'Type specific location...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.check,
                                    color: Colors.green),
                                onPressed: () {
                                  setState(() {
                                    _specificRegion =
                                        _specificRegionController.text;
                                    _showSpecificInput = false;
                                  });
                                },
                              ),
                            ),
                            onSubmitted: (value) {
                              setState(() {
                                _specificRegion = value;
                                _showSpecificInput = false;
                              });
                            },
                          ),
                        ],
                        if (_specificRegion.isNotEmpty &&
                            !_showSpecificInput) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Selected: $_specificRegion',
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeverityPage() {
    final severityLevels = [
      {
        'name': 'Mild',
        'icon': Icons.sentiment_satisfied,
        'color': Colors.green,
      },
      {
        'name': 'Moderate',
        'icon': Icons.sentiment_neutral,
        'color': Colors.orange,
      },
      {
        'name': 'Severe',
        'icon': Icons.sentiment_very_dissatisfied,
        'color': Colors.red,
      },
    ];

    return Column(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.thermostat,
                size: 80,
                color: Colors.redAccent.withOpacity(0.7),
              ),
              const SizedBox(height: 40),
              ...severityLevels.map((level) {
                final isSelected = _severity == level['name'];

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _severity = level['name'] as String),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (level['color'] as Color).withOpacity(0.1)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? level['color'] as Color
                              : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            level['icon'] as IconData,
                            size: 32,
                            color: isSelected
                                ? level['color'] as Color
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            level['name'] as String,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? level['color'] as Color
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotesPage() {
    return Column(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.note_add,
                size: 80,
                color: Colors.redAccent.withOpacity(0.7),
              ),
              const SizedBox(height: 40),
              Text(
                'Add any additional information about this bleed episode',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _notesController,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText:
                        'e.g., What were you doing when it happened? Any triggers? Pain level? Treatment taken?',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline,
                        color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tip: Include details that might help you and your healthcare provider understand patterns',
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
      ],
    );
  }

  Widget _buildPhotoPage() {
    return Column(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_camera,
                size: 80,
                color: Colors.redAccent.withOpacity(0.7),
              ),
              const SizedBox(height: 40),
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo,
                      size: 48,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No photo selected',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement camera
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement gallery
                      },
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewPage() {
    return Column(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.fact_check,
                size: 80,
                color: Colors.redAccent.withOpacity(0.7),
              ),
              const SizedBox(height: 40),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildReviewItem(
                      'Date',
                      _dateController.text,
                      Icons.calendar_today,
                    ),
                    const Divider(height: 24),
                    _buildReviewItem(
                      'Time',
                      _timeController.text,
                      Icons.access_time,
                    ),
                    const Divider(height: 24),
                    _buildReviewItem(
                      'Body Region',
                      _bodyRegion,
                      Icons.accessibility_new,
                    ),
                    const Divider(height: 24),
                    _buildReviewItem('Severity', _severity, Icons.thermostat),
                    if (_notesController.text.trim().isNotEmpty) ...[
                      const Divider(height: 24),
                      _buildReviewItem(
                        'Notes',
                        _notesController.text.trim(),
                        Icons.note,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving
                      ? null
                      : () async {
                          await _saveLog();
                          if (!mounted) return;
                          Navigator.pushReplacementNamed(
                            context,
                            '/user_screen',
                          );
                        },
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Saving...' : 'Save Bleed Log'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.redAccent, size: 20),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? 'Not selected' : value,
            style: TextStyle(
              color: value.isEmpty ? Colors.grey : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _pageTitles[_currentPage],
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _pageSubtitles[_currentPage],
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: (_currentPage + 1) / 6,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  children: [
                    _buildDateTimePage(),
                    _buildBodyRegionPage(),
                    _buildSeverityPage(),
                    _buildNotesPage(),
                    _buildPhotoPage(),
                    _buildReviewPage(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _prevPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.grey.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 16),
                  if (_currentPage < 5)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Next'),
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
}

// TODO: Turn each into Vertical Multi Step Form
