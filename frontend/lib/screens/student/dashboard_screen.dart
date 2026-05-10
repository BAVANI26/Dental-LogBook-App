import 'package:flutter/material.dart';
import '../../models/case_model.dart';
import 'add_case_screen.dart';
import 'my_cases_screen.dart';

class DashboardScreen extends StatelessWidget {
  final List<CaseModel> cases;
  final Function(CaseModel) onAddCase;

  const DashboardScreen({
    super.key,
    required this.cases,
    required this.onAddCase,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          'LogoDent Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome Back 👋',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Track your dental cases easily',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  dashboardCard('Total Cases', '${cases.length}', Icons.folder),
                  dashboardCard('Completed', '${cases.length}', Icons.check_circle),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  dashboardCard('Pending', '0', Icons.pending),
                  dashboardCard('This Month', '${cases.length}', Icons.calendar_month),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final newCase = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddCaseScreen(onSave: onAddCase),
                      ),
                    );
                    if (newCase != null) {
                      onAddCase(newCase);
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text(
                    'Add New Case',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MyCasesScreen(cases: cases),
                      ),
                    );
                  },
                  icon: const Icon(Icons.folder),
                  label: const Text(
                    'My Cases',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget dashboardCard(String title, String value, IconData icon) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.blue),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(title, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}