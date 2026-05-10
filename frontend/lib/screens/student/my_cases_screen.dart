import 'package:flutter/material.dart';
import '../../models/case_model.dart';

class MyCasesScreen extends StatelessWidget {
  final List<CaseModel> cases;

  const MyCasesScreen({super.key, required this.cases});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          'My Cases',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: cases.isEmpty
          ? const Center(
              child: Text(
                'No cases added yet.\nGo back and add a case!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: cases.length,
              itemBuilder: (context, index) {
                final c = cases[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.patientName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Patient ID: ${c.patientId}'),
                        Text('Age: ${c.age}  |  Gender: ${c.gender}'),
                        Text('Tooth No: ${c.toothNumber}'),
                        Text('Diagnosis: ${c.diagnosis}'),
                        Text('Notes: ${c.notes}'),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}