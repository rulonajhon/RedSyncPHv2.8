import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/enhanced_medication_service.dart';

class EditMedicationReminderScreen extends StatefulWidget {
  const EditMedicationReminderScreen({super.key});

  @override
  State<EditMedicationReminderScreen> createState() =>
      _EditMedicationReminderScreenState();
}

class _EditMedicationReminderScreenState
    extends State<EditMedicationReminderScreen> {
  final _enhancedMedicationService = EnhancedMedicationService();

  final _medicationNameController = TextEditingController();
  final _doseController = TextEditingController();
  final _notesController = TextEditingController();

  String _medType = 'IV Injection';
  String _frequency = 'Daily';
  TimeOfDay _selectedTime = TimeOfDay.now();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  bool _notification = true;
  bool _isLoading = false;

  Map<String, dynamic>? _originalReminder;
  String? _medicationId;

  final List<String> _medTypes = [
    'IV Injection',
    'Oral',
    'Tablet',
    'Capsule',
    'Liquid',
  ];

  final List<String> _frequencies = [
    'Once',
    'Daily',
    'Every 3 Days',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices();
    });
  }

  Future<void> _initializeServices() async {
    try {
      await _enhancedMedicationService.initialize();
    } catch (e) {
      print('⚠️ Warning: Failed to initialize services in screen: $e');
    }

    // Get arguments from route
    final arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (arguments != null) {
      _originalReminder = arguments['reminder'] as Map<String, dynamic>?;
      _medicationId = arguments['medicationId'] as String?;

      if (_originalReminder != null) {
        // Populate form fields with existing data
        _medicationNameController.text =
            _originalReminder!['medicationName'] ?? '';
        _doseController.text = _originalReminder!['dose'] ?? '';
        _medType = _originalReminder!['medType'] ?? 'IV Injection';
        _frequency = _originalReminder!['frequency'] ?? 'Daily';
        _notesController.text = _originalReminder!['notes'] ?? '';

        // Parse time
        if (_originalReminder!['time'] != null) {
          try {
            final timeParts = _originalReminder!['time'].split(':');
            _selectedTime = TimeOfDay(
              hour: int.parse(timeParts[0]),
              minute: int.parse(timeParts[1]),
            );
          } catch (e) {
            print('Error parsing time: $e');
          }
        }

        // Parse dates
        final startDateStr = _originalReminder!['startDate'];
        if (startDateStr != null) {
          try {
            _startDate = DateTime.parse(startDateStr);
          } catch (e) {
            print('Error parsing start date: $e');
          }
        }

        final endDateStr = _originalReminder!['endDate'];
        if (endDateStr != null) {
          try {
            _endDate = DateTime.parse(endDateStr);
          } catch (e) {
            print('Error parsing end date: $e');
          }
        }

        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Edit Reminder',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, size: 20),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _updateReminder,
              child: const Text(
                'Save',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.blue,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: 'Medication Details',
              children: [
                _buildInputField(
                  label: 'Medication Name',
                  controller: _medicationNameController,
                  hint: 'Enter medication name',
                  icon: Icons.medication_liquid,
                ),
                const SizedBox(height: 20),
                _buildInputField(
                  label: 'Dosage',
                  controller: _doseController,
                  hint: 'e.g., 500mg, 2 tablets',
                  icon: Icons.medical_information,
                ),
                const SizedBox(height: 20),
                _buildDropdownField(
                  label: 'Type',
                  value: _medType,
                  items: _medTypes,
                  onChanged: (value) => setState(() => _medType = value!),
                  icon: Icons.local_hospital,
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildSection(
              title: 'Schedule',
              children: [
                _buildTimeSelector(),
                const SizedBox(height: 20),
                _buildDropdownField(
                  label: 'Frequency',
                  value: _frequency,
                  items: _frequencies,
                  onChanged: (value) => setState(() => _frequency = value!),
                  icon: Icons.repeat,
                ),
                const SizedBox(height: 20),
                _buildDateRangeSection(),
              ],
            ),
            const SizedBox(height: 32),
            _buildSection(
              title: 'Additional Options',
              children: [
                _buildInputField(
                  label: 'Notes (Optional)',
                  controller: _notesController,
                  hint: 'Add any additional notes or instructions...',
                  icon: Icons.note_alt_outlined,
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                _buildNotificationSection(),
              ],
            ),
            const SizedBox(height: 18),
            _buildActionButtons(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
            prefixIcon: Icon(
              icon,
              color: Colors.grey,
              size: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: Colors.grey,
              size: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: const TextStyle(fontSize: 16),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTimeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reminder Time',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectTime,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.access_time,
                  color: Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 16),
                Text(
                  _selectedTime.format(context),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Schedule Period',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _selectDate(true),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start Date',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => _selectDate(false),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'End Date',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_endDate.day}/${_endDate.month}/${_endDate.year}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildNotificationSection() {
    return Row(
      children: [
        const Icon(
          Icons.notifications_outlined,
          size: 20,
          color: Colors.grey,
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Text(
            'Enable Notifications',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        Switch(
          value: _notification,
          onChanged: (value) {
            setState(() {
              _notification = value;
            });
          },
          activeColor: Colors.blue,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: TextButton.icon(
        onPressed: _isLoading ? null : _deleteReminder,
        icon: const Icon(Icons.delete_outline, size: 18),
        label: const Text(
          'Delete Reminder',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        style: TextButton.styleFrom(
          foregroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(
              color: Colors.red,
              width: .5,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // Ensure end date is after start date
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 7));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _updateReminder() async {
    if (_isLoading) return;

    // Validate required fields
    if (_medicationNameController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a medication name');
      return;
    }

    if (_doseController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter the dosage');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorSnackBar('User not authenticated');
        return;
      }

      if (_medicationId == null) {
        _showErrorSnackBar('No medication ID found');
        return;
      }

      // Delete the existing schedule
      await _enhancedMedicationService.deleteMedicationSchedule(_medicationId!);

      // Create updated schedule
      final timeString =
          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

      // Determine days of week based on frequency
      List<String> daysOfWeek;
      switch (_frequency) {
        case 'Daily':
          daysOfWeek = ['1', '2', '3', '4', '5', '6', '7']; // All days
          break;
        case 'Every 3 Days':
          // For every 3 days, we'll use a custom approach
          daysOfWeek = ['1', '4', '7']; // Example pattern
          break;
        case 'Once':
        default:
          // Get the start date's day of week
          final dayOfWeek = _startDate.weekday;
          daysOfWeek = [dayOfWeek.toString()];
          break;
      }

      await _enhancedMedicationService.createMedicationSchedule(
        medicationName: _medicationNameController.text.trim(),
        medType: _medType,
        dose: _doseController.text.trim(),
        frequency: _frequency,
        startDate: _startDate.toIso8601String().split('T')[0],
        endDate: _endDate.toIso8601String().split('T')[0],
        time: timeString,
        daysOfWeek: daysOfWeek,
        notes: _notesController.text.trim(),
      );

      // Return success result
      Navigator.pop(context, true);
    } catch (e) {
      print('Error updating reminder: $e');
      _showErrorSnackBar('Failed to update reminder: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteReminder() async {
    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Delete Reminder',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: const Text(
          'Are you sure you want to delete this medication reminder? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorSnackBar('User not authenticated');
        return;
      }

      if (_medicationId == null) {
        _showErrorSnackBar('No medication ID found');
        return;
      }

      // Delete the medication schedule
      await _enhancedMedicationService.deleteMedicationSchedule(_medicationId!);

      // Return success result
      Navigator.pop(context, true);
    } catch (e) {
      print('Error deleting reminder: $e');
      _showErrorSnackBar('Failed to delete reminder: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _medicationNameController.dispose();
    _doseController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
