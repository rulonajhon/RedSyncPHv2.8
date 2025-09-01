import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/offline_service.dart';
import '../../../models/offline/infusion_log.dart';
import '../../../widgets/offline_indicator.dart';

class LogInfusionScreen extends StatefulWidget {
  const LogInfusionScreen({super.key});

  @override
  State<LogInfusionScreen> createState() => _LogInfusionScreenState();
}

class _LogInfusionScreenState extends State<LogInfusionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _medicationController = TextEditingController();
  final TextEditingController _doseController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isSaving = false;
  String _selectedMedicationType = '';

  // Firebase services and offline service
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final OfflineService _offlineService = OfflineService();

  final List<String> _medicationTypes = [
    'Factor VIII',
    'Factor IX',
    'Factor XI',
    'Desmopressin (DDAVP)',
    'Antifibrinolytic agents',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.now();
    _initOfflineService();
  }

  Future<void> _initOfflineService() async {
    try {
      await _offlineService.initialize();
      print('Offline service initialized successfully');
    } catch (e) {
      print('Error initializing offline service: $e');
    }
  }

  Future<void> _saveInfusion() async {
    if (!_formKey.currentState!.validate() ||
        _selectedDate == null ||
        _selectedTime == null) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final timeStr = _selectedTime!.format(context);
      final user = _auth.currentUser;

      // Create infusion log data using our new model
      final log = InfusionLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        uid: user?.uid ?? 'guest',
        medication: _medicationController.text.trim(),
        doseIU: int.tryParse(_doseController.text.trim()) ?? 0,
        date: dateStr,
        time: timeStr,
        notes: _notesController.text.trim(),
        createdAt: DateTime.now(),
      );

      // Save using our new offline service (handles both local and cloud storage)
      await _offlineService.saveInfusionLogOffline(
        medication: log.medication,
        doseIU: log.doseIU,
        date: log.date,
        time: log.time,
        notes: log.notes,
      );

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Infusion logged successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      print('Error saving infusion log: $e');

      if (!mounted) return;

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Error saving infusion log. Please try again.'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.redAccent,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.redAccent,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Log Infusion',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        foregroundColor: Colors.white,
        backgroundColor: Colors.purple,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          const OfflineIndicator(),
          Expanded(
            child: SafeArea(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      const Text(
                        'Record Infusion',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Keep track of your medication intake',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Medication Type
                      _buildInputLabel('Medication Type'),
                      const SizedBox(height: 8),
                      _buildMedicationSelector(),

                      const SizedBox(height: 24),

                      // Specific Medication Name
                      _buildInputLabel('Medication Name'),
                      const SizedBox(height: 8),
                      _buildCleanInput(
                        controller: _medicationController,
                        hintText: 'Enter specific medication name',
                        validator: (v) => v == null || v.isEmpty
                            ? 'Enter medication name'
                            : null,
                      ),

                      const SizedBox(height: 24),

                      // Dose
                      _buildInputLabel('Dose (IU)'),
                      const SizedBox(height: 8),
                      _buildCleanInput(
                        controller: _doseController,
                        hintText: 'Enter dose amount',
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Enter dose amount' : null,
                      ),

                      const SizedBox(height: 24),

                      // Date & Time Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInputLabel('Date'),
                                const SizedBox(height: 8),
                                _buildDateTimeSelector(
                                  value: _selectedDate != null
                                      ? DateFormat('MMM dd, yyyy')
                                          .format(_selectedDate!)
                                      : 'Select date',
                                  icon: Icons.calendar_today_outlined,
                                  onTap: _pickDate,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInputLabel('Time'),
                                const SizedBox(height: 8),
                                _buildDateTimeSelector(
                                  value: _selectedTime != null
                                      ? _selectedTime!.format(context)
                                      : 'Select time',
                                  icon: Icons.access_time_outlined,
                                  onTap: _pickTime,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Notes
                      _buildInputLabel('Notes (Optional)'),
                      const SizedBox(height: 8),
                      _buildNotesInput(),

                      const SizedBox(height: 25),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveInfusion,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            disabledBackgroundColor: Colors.grey.shade300,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Save Infusion',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildMedicationSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedMedicationType.isEmpty ? null : _selectedMedicationType,
        decoration: InputDecoration(
          hintText: 'Select medication type',
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 15,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        dropdownColor: Colors.white,
        items: _medicationTypes.map((type) {
          return DropdownMenuItem<String>(
            value: type,
            child: Text(
              type,
              style: const TextStyle(fontSize: 15),
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() => _selectedMedicationType = value ?? '');
          if (value == 'Other') {
            _medicationController.clear();
          } else if (value != null) {
            _medicationController.text = value;
          }
        },
      ),
    );
  }

  Widget _buildCleanInput({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 15,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDateTimeSelector({
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.grey.shade600,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color: value.contains('Select')
                      ? Colors.grey.shade500
                      : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextFormField(
        controller: _notesController,
        maxLines: 4,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Any additional notes about this infusion...',
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 15,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}
