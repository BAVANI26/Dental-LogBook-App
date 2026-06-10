import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';

class AddCaseScreen extends StatefulWidget {
  const AddCaseScreen({super.key});

  @override
  State<AddCaseScreen> createState() => _AddCaseScreenState();
}

class _AddCaseScreenState extends State<AddCaseScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _patientNameController = TextEditingController();
  final _patientIdController = TextEditingController();
  final _ageController = TextEditingController();
  final _toothNumberController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedGender;
  String? _selectedProcedureType;

  // Use XFile instead of File (cross-platform)
  XFile? _xrayPreOp, _xrayIntraOp, _xrayPostOp;
  XFile? _photoPreOp, _photoIntraOp, _photoPostOp;

  // Store bytes for web preview
  Uint8List? _xrayPreBytes, _xrayIntraBytes, _xrayPostBytes;
  Uint8List? _photoPreBytes, _photoIntraBytes, _photoPostBytes;

  String? _xrayPreMsg, _xrayIntraMsg, _xrayPostMsg;
  String? _photoPreMsg, _photoIntraMsg, _photoPostMsg;

  final ImagePicker _picker = ImagePicker();

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _procedureTypes = [
    'Extraction',
    'Root Canal Treatment',
    'Scaling & Polishing',
    'Composite Filling',
    'Crown & Bridge',
    'Orthodontic Treatment',
    'Implant Placement',
    'Denture Fabrication',
    'Surgical Procedure',
    'Periodontal Treatment',
    'Other',
  ];

  @override
  void dispose() {
    _patientNameController.dispose();
    _patientIdController.dispose();
    _ageController.dispose();
    _toothNumberController.dispose();
    _diagnosisController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String field) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    // Read bytes for web preview
    final bytes = await picked.readAsBytes();

    setState(() {
      switch (field) {
        case 'xrayPreOp':
          _xrayPreOp = picked; _xrayPreBytes = bytes;
          _xrayPreMsg = 'X-ray image uploaded successfully ✓';
          break;
        case 'xrayIntraOp':
          _xrayIntraOp = picked; _xrayIntraBytes = bytes;
          _xrayIntraMsg = 'X-ray image uploaded successfully ✓';
          break;
        case 'xrayPostOp':
          _xrayPostOp = picked; _xrayPostBytes = bytes;
          _xrayPostMsg = 'X-ray image uploaded successfully ✓';
          break;
        case 'photoPreOp':
          _photoPreOp = picked; _photoPreBytes = bytes;
          _photoPreMsg = 'Clinical photo uploaded successfully ✓';
          break;
        case 'photoIntraOp':
          _photoIntraOp = picked; _photoIntraBytes = bytes;
          _photoIntraMsg = 'Clinical photo uploaded successfully ✓';
          break;
        case 'photoPostOp':
          _photoPostOp = picked; _photoPostBytes = bytes;
          _photoPostMsg = 'Clinical photo uploaded successfully ✓';
          break;
      }
    });
  }

  /// Upload using bytes (works on both Web and Mobile)
  Future<String?> _uploadImage(XFile xfile, String path) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      final bytes = await xfile.readAsBytes();
      final task = await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      return await task.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  bool _isNetworkError(dynamic e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('network') ||
        msg.contains('socket') ||
        msg.contains('connection') ||
        msg.contains('unavailable') ||
        msg.contains('failed-precondition');
  }

  Future<void> _saveCase() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGender == null) {
      _showSnack('Please select Gender!');
      return;
    }
    if (_selectedProcedureType == null) {
      _showSnack('Please select Procedure Type!');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final caseRef = FirebaseFirestore.instance.collection('cases').doc();
      final caseId = caseRef.id;
      final basePath = 'cases/$uid/$caseId';

      String? xrayPreUrl, xrayIntraUrl, xrayPostUrl;
      String? photoPreUrl, photoIntraUrl, photoPostUrl;

      if (_xrayPreOp != null) xrayPreUrl = await _uploadImage(_xrayPreOp!, '$basePath/xray_pre.jpg');
      if (_xrayIntraOp != null) xrayIntraUrl = await _uploadImage(_xrayIntraOp!, '$basePath/xray_intra.jpg');
      if (_xrayPostOp != null) xrayPostUrl = await _uploadImage(_xrayPostOp!, '$basePath/xray_post.jpg');
      if (_photoPreOp != null) photoPreUrl = await _uploadImage(_photoPreOp!, '$basePath/photo_pre.jpg');
      if (_photoIntraOp != null) photoIntraUrl = await _uploadImage(_photoIntraOp!, '$basePath/photo_intra.jpg');
      if (_photoPostOp != null) photoPostUrl = await _uploadImage(_photoPostOp!, '$basePath/photo_post.jpg');

      await caseRef.set({
        'userId': uid,
        'patientName': _patientNameController.text.trim(),
        'patientId': _patientIdController.text.trim(),
        'age': _ageController.text.trim(),
        'gender': _selectedGender,
        'toothNumber': _toothNumberController.text.trim(),
        'procedureType': _selectedProcedureType,
        'diagnosis': _diagnosisController.text.trim(),
        'notes': _notesController.text.trim(),
        'xrayPreOp': xrayPreUrl ?? '',
        'xrayIntraOp': xrayIntraUrl ?? '',
        'xrayPostOp': xrayPostUrl ?? '',
        'photoPreOp': photoPreUrl ?? '',
        'photoIntraOp': photoIntraUrl ?? '',
        'photoPostOp': photoPostUrl ?? '',
        'status': 'draft',
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() => _isLoading = false);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Case saved as Draft successfully! ✅'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;

      if (_isNetworkError(e)) {
        _showSnack('No internet connection. Please check your network and try again.', isError: true);
      } else {
        _showSnack('Error saving case. Please try again.', isError: true);
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  /// Web-safe image widget — uses Image.memory on web, Image.file on mobile
  Widget _buildImagePreview(XFile? xfile, Uint8List? bytes) {
    if (xfile == null) {
      return const Icon(Icons.add_photo_alternate, color: Color(0xFF2A3F60), size: 28);
    }
    if (kIsWeb) {
      return bytes != null
          ? Image.memory(bytes, fit: BoxFit.cover)
          : const Icon(Icons.image, color: Color(0xFFC9A84C), size: 28);
    } else {
      return Image.file(File(xfile.path), fit: BoxFit.cover);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F2040),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFC9A84C)),
        title: RichText(
          text: const TextSpan(children: [
            TextSpan(text: 'Add ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            TextSpan(text: 'Case', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFC9A84C))),
          ]),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Patient Information'),
                  const SizedBox(height: 12),
                  _buildTextField(_patientNameController, 'Patient Name', Icons.person, required: true),
                  const SizedBox(height: 12),
                  _buildTextField(_patientIdController, 'Patient ID', Icons.badge, required: true),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_ageController, 'Age', Icons.cake, required: true, keyboardType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildDropdown('Gender', _genders, _selectedGender, (val) => setState(() => _selectedGender = val), Icons.wc)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(_toothNumberController, 'Tooth Number (e.g. 11, 21)', Icons.numbers),
                  const SizedBox(height: 24),

                  _sectionTitle('Case Information'),
                  const SizedBox(height: 12),
                  _buildDropdown('Procedure Type', _procedureTypes, _selectedProcedureType, (val) => setState(() => _selectedProcedureType = val), Icons.medical_services),
                  const SizedBox(height: 12),
                  _buildTextField(_diagnosisController, 'Diagnosis', Icons.local_hospital, required: true),
                  const SizedBox(height: 12),
                  _buildTextField(_notesController, 'Treatment Notes', Icons.notes, required: true, maxLines: 4),
                  const SizedBox(height: 24),

                  _sectionTitle('X-Ray Images'),
                  const SizedBox(height: 4),
                  const Text('Optional — add pre/intra/post operative X-rays', style: TextStyle(fontSize: 12, color: Color(0xFF8899BB))),
                  const SizedBox(height: 12),
                  _imagePickerRow(
                    label: 'Pre Operative',
                    xfile: _xrayPreOp, bytes: _xrayPreBytes,
                    statusMessage: _xrayPreMsg,
                    onTap: () => _pickImage('xrayPreOp'),
                    onRemove: () => setState(() { _xrayPreOp = null; _xrayPreBytes = null; _xrayPreMsg = null; }),
                  ),
                  const SizedBox(height: 10),
                  _imagePickerRow(
                    label: 'Intraoperative',
                    xfile: _xrayIntraOp, bytes: _xrayIntraBytes,
                    statusMessage: _xrayIntraMsg,
                    onTap: () => _pickImage('xrayIntraOp'),
                    onRemove: () => setState(() { _xrayIntraOp = null; _xrayIntraBytes = null; _xrayIntraMsg = null; }),
                  ),
                  const SizedBox(height: 10),
                  _imagePickerRow(
                    label: 'Post Operative',
                    xfile: _xrayPostOp, bytes: _xrayPostBytes,
                    statusMessage: _xrayPostMsg,
                    onTap: () => _pickImage('xrayPostOp'),
                    onRemove: () => setState(() { _xrayPostOp = null; _xrayPostBytes = null; _xrayPostMsg = null; }),
                  ),
                  const SizedBox(height: 24),

                  _sectionTitle('Clinical Photos'),
                  const SizedBox(height: 4),
                  const Text('Optional — add pre/intra/post operative clinical photos', style: TextStyle(fontSize: 12, color: Color(0xFF8899BB))),
                  const SizedBox(height: 12),
                  _imagePickerRow(
                    label: 'Pre Operative',
                    xfile: _photoPreOp, bytes: _photoPreBytes,
                    statusMessage: _photoPreMsg,
                    onTap: () => _pickImage('photoPreOp'),
                    onRemove: () => setState(() { _photoPreOp = null; _photoPreBytes = null; _photoPreMsg = null; }),
                  ),
                  const SizedBox(height: 10),
                  _imagePickerRow(
                    label: 'Intraoperative',
                    xfile: _photoIntraOp, bytes: _photoIntraBytes,
                    statusMessage: _photoIntraMsg,
                    onTap: () => _pickImage('photoIntraOp'),
                    onRemove: () => setState(() { _photoIntraOp = null; _photoIntraBytes = null; _photoIntraMsg = null; }),
                  ),
                  const SizedBox(height: 10),
                  _imagePickerRow(
                    label: 'Post Operative',
                    xfile: _photoPostOp, bytes: _photoPostBytes,
                    statusMessage: _photoPostMsg,
                    onTap: () => _pickImage('photoPostOp'),
                    onRemove: () => setState(() { _photoPostOp = null; _photoPostBytes = null; _photoPostMsg = null; }),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveCase,
                      icon: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFF0A1628), strokeWidth: 2))
                          : const Icon(Icons.save),
                      label: Text(
                        _isLoading ? 'Saving...' : 'Save as Draft',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC9A84C),
                        foregroundColor: const Color(0xFF0A1628),
                        disabledBackgroundColor: const Color(0xFF8B7035),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      'You can submit to faculty from My Cases tab',
                      style: TextStyle(fontSize: 12, color: Color(0xFF8899BB)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFC9A84C)));
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      validator: required
          ? (val) => (val == null || val.trim().isEmpty) ? '$label is required' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF8899BB)),
        prefixIcon: Icon(icon, color: const Color(0xFFC9A84C)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2A3F60)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFC9A84C)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: const Color(0xFF0F2040),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String? value,
    ValueChanged<String?> onChanged,
    IconData icon,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      dropdownColor: const Color(0xFF0F2040),
      style: const TextStyle(color: Colors.white),
      icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFC9A84C)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF8899BB)),
        prefixIcon: Icon(icon, color: const Color(0xFFC9A84C)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2A3F60)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFC9A84C)),
        ),
        filled: true,
        fillColor: const Color(0xFF0F2040),
      ),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
    );
  }

  Widget _imagePickerRow({
    required String label,
    required XFile? xfile,
    required Uint8List? bytes,
    required String? statusMessage,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2040),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: xfile != null ? const Color(0xFFC9A84C).withOpacity(0.5) : const Color(0xFF2A3F60)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF0A1628),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF2A3F60)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildImagePreview(xfile, bytes),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 4),
                Text(
                  statusMessage ?? (xfile != null ? 'Image selected ✓' : 'Tap to select image'),
                  style: TextStyle(
                    fontSize: 12,
                    color: xfile != null ? Colors.green : const Color(0xFF8899BB),
                  ),
                ),
              ],
            ),
          ),
          if (xfile != null)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red, size: 20),
              onPressed: onRemove,
            )
          else
            TextButton(
              onPressed: onTap,
              child: const Text('Select', style: TextStyle(color: Color(0xFFC9A84C), fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}