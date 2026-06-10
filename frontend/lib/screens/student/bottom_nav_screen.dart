import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/login_screen.dart';
import 'dashboard_screen.dart';
import 'add_case_screen.dart';
import 'my_cases_screen.dart';
import 'notifications_screen.dart';

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({super.key});

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const DashboardScreen(),
      const AddCaseScreen(),
      const MyCasesScreen(),
      const NotificationsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: const Color(0xFFC9A84C),
        unselectedItemColor: const Color(0xFF8899BB),
        backgroundColor: const Color(0xFF0F2040),
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => currentIndex = index),
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: 'Add Case'),
          const BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'My Cases'),
          BottomNavigationBarItem(
            icon: NotificationBadge(child: const Icon(Icons.notifications)),
            label: 'Alerts',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  void loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    setState(() {
      userData = doc.data();
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F2040),
        elevation: 0,
        title: RichText(
          text: const TextSpan(children: [
            TextSpan(text: 'Logo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            TextSpan(text: 'Dent', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFC9A84C))),
          ]),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFC9A84C)))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F2040),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFC9A84C), width: 2.5),
                          boxShadow: [BoxShadow(color: const Color(0xFFC9A84C).withOpacity(0.2), blurRadius: 20)],
                        ),
                        child: const Icon(Icons.person, size: 56, color: Color(0xFFC9A84C)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        userData?['name'] ?? 'Student Name',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC9A84C).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFC9A84C).withOpacity(0.4)),
                        ),
                        child: Text(
                          (userData?['role'] ?? 'student').toUpperCase(),
                          style: const TextStyle(fontSize: 12, color: Color(0xFFC9A84C), fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F2040),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF2A3F60)),
                        ),
                        child: Column(
                          children: [
                            _infoTile(Icons.email_outlined, 'Email', userData?['email'] ?? '-'),
                            const Divider(color: Color(0xFF2A3F60), height: 24),
                            _infoTile(Icons.school_outlined, 'Department', userData?['department'] ?? '-'),
                            const Divider(color: Color(0xFF2A3F60), height: 24),
                            _infoTile(Icons.account_balance_outlined, 'College', userData?['college'] ?? '-'),
                            const Divider(color: Color(0xFF2A3F60), height: 24),
                            _infoTile(Icons.badge_outlined, 'Roll Number', userData?['rollNumber'] ?? '-'),
                            if (userData?['year'] != null) ...[
                              const Divider(color: Color(0xFF2A3F60), height: 24),
                              _infoTile(Icons.calendar_today_outlined, 'Year', userData?['year'] ?? '-'),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('cases')
                            .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          final docs = snapshot.data?.docs ?? [];
                          final total = docs.length;
                          final approved = docs.where((d) => (d.data() as Map)['status'] == 'approved').length;
                          final pending = docs.where((d) => (d.data() as Map)['status'] == 'pending').length;
                          return Row(
                            children: [
                              Expanded(child: _statBox('Total', '$total', const Color(0xFF4A90D9))),
                              const SizedBox(width: 12),
                              Expanded(child: _statBox('Approved', '$approved', const Color(0xFF4CAF50))),
                              const SizedBox(width: 12),
                              Expanded(child: _statBox('Pending', '$pending', const Color(0xFFFF9800))),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text('Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade800,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFC9A84C), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF8899BB), letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2040),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF8899BB))),
        ],
      ),
    );
  }
}