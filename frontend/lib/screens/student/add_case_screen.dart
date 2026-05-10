import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/case_model.dart';

class AddCaseScreen extends StatefulWidget {
  final Function(CaseModel)? onSave;

  const AddCaseScreen({super.key, this.onSave});

  @override
  State<AddCaseScreen> createState() => _AddCaseScreenState();
}

class _AddCaseScreenState extends State<AddCaseScreen> {
  final ImagePicker picker = ImagePicker();
  XFile? selectedImage;

  final patientIdController = TextEditingController();
  final patientNameController = TextEditingController();
  final ageController = TextEditingController();
  final genderController = TextEditingController();
  final toothController = TextEditingController();
  final diagnosisController = TextEditingController();
  final notesController = TextEditingController();

  Future<void> pickImage() async {
    final XFile? image =
        await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        selectedImage = image;
      });
    }
  }

  void saveCase() {
    if (patientIdController.text.isEmpty ||
        patientNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill Patient ID and Name'),
        ),
      );
      return;
    }

    final newCase = CaseModel(
      patientId: patientIdController.text,
      patientName: patientNameController.text,
      age: ageController.text,
      gender: genderController.text,
      toothNumber: toothController.text,
      diagnosis: diagnosisController.text,
      notes: notesController.text,
      imagePath: selectedImage?.path ?? '',
    );

    if (widget.onSave != null) {
      widget.onSave!(newCase);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Case saved successfully! ✅'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context, newCase);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          'Add New Case',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: patientIdController,
              decoration: const InputDecoration(
                labelText: 'Patient ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: patientNameController,
              decoration: const InputDecoration(
                labelText: 'Patient Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: ageController,
              decoration: const InputDecoration(
                labelText: 'Age',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: genderController,
              decoration: const InputDecoration(
                labelText: 'Gender',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: toothController,
              decoration: const InputDecoration(
                labelText: 'Tooth Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: diagnosisController,
              decoration: const InputDecoration(
                labelText: 'Diagnosis',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Treatment Notes',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'X-Ray Uploads',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            uploadCard('Pre Operative X-Ray'),
            const SizedBox(height: 15),
            uploadCard('Intraoperative X-Ray'),
            const SizedBox(height: 15),
            uploadCard('Post Operative X-Ray'),
            const SizedBox(height: 30),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Clinical Photos',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            uploadCard('Pre Operative Photo'),
            const SizedBox(height: 15),
            uploadCard('Intraoperative Photo'),
            const SizedBox(height: 15),
            uploadCard('Post Operative Photo'),
            const SizedBox(height: 30),
            if (selectedImage != null)
              Column(
                children: [
                  const Text(
                    'Selected Image Preview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Image.network(
                    selectedImage!.path,
                    height: 200,
                  ),
                ],
              ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: saveCase,
                icon: const Icon(Icons.save),
                label: const Text(
                  'Save Case',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget uploadCard(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.upload_file, color: Colors.blue),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: pickImage,
            child: const Text('Upload'),
          ),
        ],
      ),
    );
  }
}