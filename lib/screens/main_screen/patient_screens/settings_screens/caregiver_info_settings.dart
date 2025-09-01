import 'package:flutter/material.dart';
import 'package:hemophilia_manager/auth/auth.dart';
import 'package:hemophilia_manager/services/firestore.dart';

class CaregiverInfoSettings extends StatefulWidget {
  const CaregiverInfoSettings({super.key});

  @override
  State<CaregiverInfoSettings> createState() => _CaregiverInfoSettingsState();
}

class _CaregiverInfoSettingsState extends State<CaregiverInfoSettings> {
  String gender = 'Male';
  DateTime? dob;
  String relationship = 'Parent';
  String name = '';
  String email = '';
  String photoUrl = '';
  String patientName = '';
  String patientAge = '';
  String patientHemophiliaType = 'Hemophilia A';
  DateTime? patientDob;
  String patientGender = 'Male';
  String patientWeight = '';
  String patientBloodType = '';
  bool _isLoading = false;

  final List<String> genderOptions = ['Male', 'Female', 'Other'];
  final List<String> relationshipOptions = ['Parent', 'Spouse', 'Sibling', 'Guardian', 'Other'];
  final List<String> hemophiliaTypeOptions = ['Hemophilia A', 'Hemophilia B', 'Hemophilia C'];
  final List<String> bloodTypeOptions = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Not specified'];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    setState(() => _isLoading = true);
    final user = AuthService().currentUser;
    if (user != null) {
      email = user.email ?? '';
      photoUrl = user.photoURL ?? '';
      final userData = await FirestoreService().getUser(user.uid);
      if (userData != null) {
        setState(() {
          name = userData['name'] ?? '';
          gender = userData['gender'] ?? gender;
          relationship = userData['relationship'] ?? relationship;
          patientName = userData['patientName'] ?? patientName;
          patientAge = userData['patientAge'] ?? patientAge;
          patientHemophiliaType = userData['patientHemophiliaType'] ?? patientHemophiliaType;
          patientGender = userData['patientGender'] ?? patientGender;
          patientWeight = userData['patientWeight'] ?? patientWeight;
          patientBloodType = userData['patientBloodType'] ?? patientBloodType;
          dob = userData['dob'] != null
              ? DateTime.tryParse(userData['dob'])
              : dob;
          patientDob = userData['patientDob'] != null
              ? DateTime.tryParse(userData['patientDob'])
              : patientDob;
        });
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    final user = AuthService().currentUser;
    if (user != null) {
      await FirestoreService().updateUser(
        user.uid,
        name,
        email,
        null,
        extra: {
          'gender': gender,
          'relationship': relationship,
          'patientName': patientName,
          'patientAge': patientAge,
          'patientHemophiliaType': patientHemophiliaType,
          'patientGender': patientGender,
          'patientWeight': patientWeight,
          'patientBloodType': patientBloodType,
          'dob': dob?.toIso8601String(),
          'patientDob': patientDob?.toIso8601String(),
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated!'),
          backgroundColor: Colors.green,
        ),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Caregiver Profile',  
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Profile Header Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey.shade300,
                              backgroundImage: photoUrl.isNotEmpty
                                  ? NetworkImage(photoUrl)
                                  : null,
                              child: photoUrl.isEmpty
                                  ? Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Colors.grey.shade600,
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          name.isEmpty ? 'Loading...' : name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Caregiver',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Personal Information Section
                  _buildSectionHeader('Personal Information', Icons.person_outline),
                  const SizedBox(height: 16),
                  
                  _buildInfoTile(
                    icon: Icons.wc,
                    title: 'Gender',
                    value: gender,
                    onTap: () => _showGenderDialog(),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildInfoTile(
                    icon: Icons.cake,
                    title: 'Date of Birth',
                    value: dob == null
                        ? 'Not set'
                        : '${dob!.day}/${dob!.month}/${dob!.year}',
                    onTap: () => _selectDateOfBirth(),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Caregiving Information Section
                  _buildSectionHeader('Caregiving Information', Icons.family_restroom),
                  const SizedBox(height: 16),
                  
                  _buildInfoTile(
                    icon: Icons.people,
                    title: 'Relationship to Patient',
                    value: relationship,
                    onTap: () => _showRelationshipDialog(),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Patient Information Section
                  _buildSectionHeader('Patient Information', Icons.local_hospital),
                  const SizedBox(height: 16),
                  
                  _buildPatientNameTile(),
                  
                  const SizedBox(height: 16),
                  
                  _buildPatientAgeTile(),
                  
                  const SizedBox(height: 16),
                  
                  _buildInfoTile(
                    icon: Icons.wc,
                    title: 'Patient Gender',
                    value: patientGender,
                    onTap: () => _showPatientGenderDialog(),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildInfoTile(
                    icon: Icons.cake,
                    title: 'Patient Date of Birth',
                    value: patientDob == null
                        ? 'Not set'
                        : '${patientDob!.day}/${patientDob!.month}/${patientDob!.year}',
                    onTap: () => _selectPatientDateOfBirth(),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildInfoTile(
                    icon: Icons.medical_services,
                    title: 'Hemophilia Type',
                    value: patientHemophiliaType,
                    onTap: () => _showHemophiliaTypeDialog(),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildPatientWeightTile(),
                  
                  const SizedBox(height: 16),
                  
                  _buildInfoTile(
                    icon: Icons.bloodtype,
                    title: 'Blood Type',
                    value: patientBloodType.isEmpty ? 'Not specified' : patientBloodType,
                    onTap: () => _showBloodTypeDialog(),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveProfile,
                      icon: const Icon(
                        Icons.save,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.redAccent,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.grey.shade600,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientNameTile() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.person_outline,
              color: Colors.grey.shade600,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Patient Name',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Enter patient name',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  controller: TextEditingController(text: patientName),
                  onChanged: (val) => setState(() => patientName = val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showGenderDialog() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Select Gender',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: genderOptions.map((g) => 
            ListTile(
              title: Text(g),
              onTap: () => Navigator.pop(context, g),
              trailing: gender == g ? const Icon(Icons.check, color: Colors.redAccent) : null,
              contentPadding: EdgeInsets.zero,
            ),
          ).toList(),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    if (selected != null) setState(() => gender = selected);
  }

  Future<void> _showRelationshipDialog() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Select Relationship',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: relationshipOptions.map((r) => 
            ListTile(
              title: Text(r),
              onTap: () => Navigator.pop(context, r),
              trailing: relationship == r ? const Icon(Icons.check, color: Colors.redAccent) : null,
              contentPadding: EdgeInsets.zero,
            ),
          ).toList(),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    if (selected != null) setState(() => relationship = selected);
  }

  Future<void> _selectDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dob ?? DateTime(1980, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
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
    if (picked != null) setState(() => dob = picked);
  }

  Future<void> _selectPatientDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: patientDob ?? DateTime(2010, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
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
    if (picked != null) setState(() => patientDob = picked);
  }

  Widget _buildPatientAgeTile() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.calendar_today,
              color: Colors.grey.shade600,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Patient Age',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Enter patient age',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: patientAge),
                  onChanged: (val) => setState(() => patientAge = val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientWeightTile() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.monitor_weight,
              color: Colors.grey.shade600,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Patient Weight (kg)',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Enter patient weight',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: patientWeight),
                  onChanged: (val) => setState(() => patientWeight = val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPatientGenderDialog() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Select Patient Gender',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: genderOptions.map((g) => 
            ListTile(
              title: Text(g),
              onTap: () => Navigator.pop(context, g),
              trailing: patientGender == g ? const Icon(Icons.check, color: Colors.redAccent) : null,
              contentPadding: EdgeInsets.zero,
            ),
          ).toList(),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    if (selected != null) setState(() => patientGender = selected);
  }

  Future<void> _showHemophiliaTypeDialog() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Select Hemophilia Type',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: hemophiliaTypeOptions.map((h) => 
            ListTile(
              title: Text(h),
              onTap: () => Navigator.pop(context, h),
              trailing: patientHemophiliaType == h ? const Icon(Icons.check, color: Colors.redAccent) : null,
              contentPadding: EdgeInsets.zero,
            ),
          ).toList(),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    if (selected != null) setState(() => patientHemophiliaType = selected);
  }

  Future<void> _showBloodTypeDialog() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Select Blood Type',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: bloodTypeOptions.map((b) => 
            ListTile(
              title: Text(b),
              onTap: () => Navigator.pop(context, b),
              trailing: patientBloodType == b ? const Icon(Icons.check, color: Colors.redAccent) : null,
              contentPadding: EdgeInsets.zero,
            ),
          ).toList(),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    if (selected != null) setState(() => patientBloodType = selected);
  }
}
