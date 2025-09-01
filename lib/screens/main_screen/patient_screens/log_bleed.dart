import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/offline_service.dart';
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
            ),
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
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
