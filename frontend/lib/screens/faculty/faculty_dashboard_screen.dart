import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:signature/signature.dart';
import 'dart:convert';
import '../auth/login_screen.dart';

// ─── Faculty Bottom Nav ───────────────────────────────────────────────────────

class FacultyDashboardScreen extends StatefulWidget {
  const FacultyDashboardScreen({super.key});

  @override
  State<FacultyDashboardScreen> createState() => _FacultyDashboardScreenState();
}

class _FacultyDashboardScreenState extends State<FacultyDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final screens = [
      FacultyHomeScreen(uid: uid),
      FacultyCasesListScreen(filter: 'pending', uid: uid, title: 'Pending Cases'),
      FacultyProfileScreen(uid: uid),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFFC9A84C),
        unselectedItemColor: const Color(0xFF8899BB),
        backgroundColor: const Color(0xFF0F2040),
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.pending_actions), label: 'Review'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// ─── Faculty Home / Dashboard ─────────────────────────────────────────────────

class FacultyHomeScreen extends StatelessWidget {
  final String uid;
  const FacultyHomeScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F2040),
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFC9A84C), width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 10),
            RichText(
              text: const TextSpan(children: [
                TextSpan(text: 'Logo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                TextSpan(text: 'Dent', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFC9A84C))),
              ]),
            ),
            const SizedBox(width: 8),
            const Text('| Faculty', style: TextStyle(fontSize: 14, color: Color(0xFF8899BB))),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('cases').where('facultyUid', isEqualTo: uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFC9A84C)));
          }

          final allCases = snapshot.data?.docs ?? [];
          final total = allCases.length;
          final pending = allCases.where((c) => (c.data() as Map)['status'] == 'pending').length;
          final approved = allCases.where((c) => (c.data() as Map)['status'] == 'approved').length;
          final rejected = allCases.where((c) => (c.data() as Map)['status'] == 'rejected').length;

          final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
          final Map<String, int> monthlyApproved = {};
          final Map<String, int> monthlyRejected = {};
          for (var doc in allCases) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['createdAt'] != null) {
              final date = (data['createdAt'] as dynamic).toDate();
              final key = months[date.month - 1];
              if (data['status'] == 'approved') monthlyApproved[key] = (monthlyApproved[key] ?? 0) + 1;
              if (data['status'] == 'rejected') monthlyRejected[key] = (monthlyRejected[key] ?? 0) + 1;
            }
          }

          final allMonthKeys = {...monthlyApproved.keys, ...monthlyRejected.keys}.toList();

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
                      builder: (context, snap) {
                        final name = snap.data?['name'] ?? 'Faculty';
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Welcome, $name 👋', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 4),
                            const Text('Faculty Dashboard — Review & Approve Cases', style: TextStyle(fontSize: 14, color: Color(0xFF8899BB))),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(child: _statCard(context, 'Total Cases', '$total', Icons.folder_copy, const Color(0xFF4A90D9), 'all', uid)),
                        const SizedBox(width: 16),
                        Expanded(child: _statCard(context, 'Pending', '$pending', Icons.hourglass_empty, const Color(0xFFFF9800), 'pending', uid)),
                        const SizedBox(width: 16),
                        Expanded(child: _statCard(context, 'Approved', '$approved', Icons.check_circle, const Color(0xFF4CAF50), 'approved', uid)),
                        const SizedBox(width: 16),
                        Expanded(child: _statCard(context, 'Rejected', '$rejected', Icons.cancel, const Color(0xFFE53935), 'rejected', uid)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F2040),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF2A3F60)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Monthly Progress 📊', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFC9A84C))),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(3))),
                              const SizedBox(width: 4),
                              const Text('Approved', style: TextStyle(fontSize: 12, color: Colors.white70)),
                              const SizedBox(width: 16),
                              Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(3))),
                              const SizedBox(width: 4),
                              const Text('Rejected', style: TextStyle(fontSize: 12, color: Colors.white70)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          allMonthKeys.isEmpty
                              ? const Center(child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Text('No reviewed cases yet!', style: TextStyle(color: Color(0xFF8899BB))),
                                ))
                              : SizedBox(
                                  height: 180,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: allMonthKeys.map((month) {
                                      final approvedVal = monthlyApproved[month] ?? 0;
                                      final rejectedVal = monthlyRejected[month] ?? 0;
                                      final maxVal = [...monthlyApproved.values, ...monthlyRejected.values, 1].reduce((a, b) => a > b ? a : b);
                                      final approvedHeight = (approvedVal / maxVal) * 130;
                                      final rejectedHeight = (rejectedVal / maxVal) * 130;
                                      return Column(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                                                Text('$approvedVal', style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                                                const SizedBox(height: 2),
                                                Container(width: 14, height: approvedHeight, decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4))),
                                              ]),
                                              const SizedBox(width: 3),
                                              Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                                                Text('$rejectedVal', style: const TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                                                const SizedBox(height: 2),
                                                Container(width: 14, height: rejectedHeight, decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4))),
                                              ]),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(month, style: const TextStyle(fontSize: 11, color: Color(0xFF8899BB))),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _statCard(BuildContext context, String title, String count, IconData icon, Color color, String filter, String uid) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => FacultyCasesListScreen(filter: filter, uid: uid, title: title))),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F2040),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(count, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF8899BB))),
          ],
        ),
      ),
    );
  }
}

// ─── Faculty Profile Screen ───────────────────────────────────────────────────

class FacultyProfileScreen extends StatefulWidget {
  final String uid;
  const FacultyProfileScreen({super.key, required this.uid});

  @override
  State<FacultyProfileScreen> createState() => _FacultyProfileScreenState();
}

class _FacultyProfileScreenState extends State<FacultyProfileScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
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
            TextSpan(text: 'My ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            TextSpan(text: 'Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFC9A84C))),
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
                      Text(userData?['name'] ?? 'Faculty Name', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC9A84C).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFC9A84C).withOpacity(0.4)),
                        ),
                        child: const Text('FACULTY', style: TextStyle(fontSize: 12, color: Color(0xFFC9A84C), fontWeight: FontWeight.bold, letterSpacing: 1)),
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
                            _infoTile(Icons.badge_outlined, 'Faculty ID', userData?['facultyId'] ?? '-'),
                            const Divider(color: Color(0xFF2A3F60), height: 24),
                            _infoTile(Icons.school_outlined, 'Department', userData?['department'] ?? '-'),
                            const Divider(color: Color(0xFF2A3F60), height: 24),
                            _infoTile(Icons.account_balance_outlined, 'College', userData?['college'] ?? '-'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('cases').where('facultyUid', isEqualTo: widget.uid).snapshots(),
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
                        width: double.infinity, height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
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

// ─── Faculty Cases List ───────────────────────────────────────────────────────

class FacultyCasesListScreen extends StatelessWidget {
  final String filter;
  final String uid;
  final String title;

  const FacultyCasesListScreen({super.key, required this.filter, required this.uid, required this.title});

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance.collection('cases').where('facultyUid', isEqualTo: uid);
    if (filter != 'all') query = query.where('status', isEqualTo: filter);

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F2040),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Color(0xFFC9A84C)),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: StreamBuilder<QuerySnapshot>(
            stream: query.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFFC9A84C)));
              }
              final cases = snapshot.data?.docs ?? [];
              if (cases.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 80, color: const Color(0xFF2A3F60)),
                      const SizedBox(height: 20),
                      const Text('No cases found!', style: TextStyle(fontSize: 18, color: Color(0xFF8899BB))),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: cases.length,
                itemBuilder: (context, index) {
                  final c = cases[index].data() as Map<String, dynamic>;
                  final caseId = cases[index].id;
                  final status = c['status'] ?? 'draft';
                  Color statusColor = Colors.grey;
                  if (status == 'pending') statusColor = Colors.orange;
                  if (status == 'approved') statusColor = Colors.green;
                  if (status == 'rejected') statusColor = Colors.red;
                  return GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FacultyCaseDetailScreen(caseId: caseId, caseData: c))),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F2040),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2A3F60)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(color: const Color(0xFF0A1628), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.medical_services, color: Color(0xFFC9A84C)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c['patientName'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                                const SizedBox(height: 4),
                                Text('ID: ${c['patientId'] ?? ''} | ${c['procedureType'] ?? ''}', style: const TextStyle(fontSize: 12, color: Color(0xFF8899BB))),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                            child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── Faculty Case Detail ──────────────────────────────────────────────────────

class FacultyCaseDetailScreen extends StatefulWidget {
  final String caseId;
  final Map<String, dynamic> caseData;

  const FacultyCaseDetailScreen({super.key, required this.caseId, required this.caseData});

  @override
  State<FacultyCaseDetailScreen> createState() => _FacultyCaseDetailScreenState();
}

class _FacultyCaseDetailScreenState extends State<FacultyCaseDetailScreen> {
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3, penColor: Colors.black, exportBackgroundColor: Colors.white,
  );

  bool _hasImage(dynamic url) => url != null && url.toString().isNotEmpty;

  @override
  void dispose() { _signatureController.dispose(); super.dispose(); }

  Future<void> _sendNotificationToStudent(String action, {String? rejectReason}) async {
    try {
      final studentUid = widget.caseData['userId'];
      if (studentUid == null) return;

      final patientName = widget.caseData['patientName'] ?? 'your case';
      final title = action == 'approved' ? '✅ Case Approved!' : '❌ Case Rejected';
      final body = action == 'approved'
          ? 'Your case for $patientName has been approved by faculty.'
          : 'Your case for $patientName has been rejected. Please check and resubmit.';

      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': studentUid,
        'title': title,
        'body': body,
        'caseId': widget.caseId,
        'patientName': patientName,
        'action': action,
        'rejectReason': rejectReason,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Notification error: $e');
    }
  }

  // ✅ FIX: screenContext pass pannurom — dialog pop aana appuram snackbar miss aagaathu
  void _showSignatureDialog(BuildContext screenContext, String action, {String? rejectReason}) {
    _signatureController.clear();
    showDialog(
      context: screenContext,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0F2040),
        title: Text(
          action == 'approved' ? 'Sign to Approve ✅' : 'Sign to Reject ❌',
          style: TextStyle(color: action == 'approved' ? Colors.green : Colors.red),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please sign below to confirm:', style: TextStyle(fontSize: 13, color: Color(0xFF8899BB))),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFC9A84C)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Signature(controller: _signatureController, height: 150, backgroundColor: Colors.white),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _signatureController.clear(),
              icon: const Icon(Icons.refresh, size: 16, color: Color(0xFFC9A84C)),
              label: const Text('Clear', style: TextStyle(color: Color(0xFFC9A84C))),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF8899BB))),
          ),
          ElevatedButton(
            onPressed: () async {
              // ✅ SIGN-03 FIX: Signature இல்லாம save block — dialog context use pannurom
              if (_signatureController.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('⚠️ Please sign before confirming!'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              final signatureBytes = await _signatureController.toPngBytes();
              final signatureBase64 = base64Encode(signatureBytes!);
              final updateData = <String, dynamic>{
                'status': action,
                'facultySignature': signatureBase64,
                'reviewedAt': FieldValue.serverTimestamp(),
              };
              if (rejectReason != null) updateData['rejectReason'] = rejectReason;

              await FirebaseFirestore.instance.collection('cases').doc(widget.caseId).update(updateData);
              await _sendNotificationToStudent(action, rejectReason: rejectReason);

              // ✅ SIGN-01 FIX: dialog pop → screen pop → then snackbar using screenContext
              Navigator.pop(dialogContext); // dialog close
              Navigator.pop(screenContext); // detail screen close

              // ✅ mounted check + screenContext use — snackbar always shows!
              if (screenContext.mounted) {
                ScaffoldMessenger.of(screenContext).showSnackBar(
                  SnackBar(
                    content: Text(action == 'approved' ? '✅ Case Approved Successfully!' : '❌ Case Rejected!'),
                    backgroundColor: action == 'approved' ? Colors.green : Colors.red,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'approved' ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(action == 'approved' ? 'Confirm Approve' : 'Confirm Reject'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext screenContext) {
    final reasonController = TextEditingController();
    showDialog(
      context: screenContext,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0F2040),
        title: const Text('Reject Case', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter reason for rejection:', style: TextStyle(fontSize: 14, color: Color(0xFF8899BB))),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Rejection Reason',
                labelStyle: const TextStyle(color: Color(0xFF8899BB)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF2A3F60)), borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFFC9A84C)), borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: const Color(0xFF0A1628),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF8899BB))),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Please enter rejection reason!')),
                );
                return;
              }
              Navigator.pop(dialogContext);
              // ✅ screenContext pass pannurom — signature dialog la snackbar correctly shows
              _showSignatureDialog(screenContext, 'rejected', rejectReason: reasonController.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Next → Sign'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.caseData['status'] ?? 'draft';
    Color statusColor = Colors.grey;
    if (status == 'pending') statusColor = Colors.orange;
    if (status == 'approved') statusColor = Colors.green;
    if (status == 'rejected') statusColor = Colors.red;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F2040),
        title: const Text('Case Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Color(0xFFC9A84C)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.4)),
                    ),
                    child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 24),
                _sectionTitle('Patient Information'),
                _infoRow('Patient Name', widget.caseData['patientName'] ?? '-'),
                _infoRow('Patient ID', widget.caseData['patientId'] ?? '-'),
                _infoRow('Age', widget.caseData['age'] ?? '-'),
                _infoRow('Gender', widget.caseData['gender'] ?? '-'),
                _infoRow('Tooth Number', widget.caseData['toothNumber'] ?? '-'),
                const SizedBox(height: 20),
                _sectionTitle('Case Information'),
                _infoRow('Student', widget.caseData['studentName'] ?? '-'),
                _infoRow('Procedure', widget.caseData['procedureType'] ?? '-'),
                _infoRow('Diagnosis', widget.caseData['diagnosis'] ?? '-'),
                _infoRow('Notes', widget.caseData['notes'] ?? '-'),
                const SizedBox(height: 20),
                if (_hasImage(widget.caseData['xrayPreOp']) || _hasImage(widget.caseData['xrayIntraOp']) || _hasImage(widget.caseData['xrayPostOp'])) ...[
                  _sectionTitle('X-Ray Images'),
                  _imageRow('Pre Operative', widget.caseData['xrayPreOp']),
                  _imageRow('Intraoperative', widget.caseData['xrayIntraOp']),
                  _imageRow('Post Operative', widget.caseData['xrayPostOp']),
                  const SizedBox(height: 20),
                ],
                if (_hasImage(widget.caseData['photoPreOp']) || _hasImage(widget.caseData['photoIntraOp']) || _hasImage(widget.caseData['photoPostOp'])) ...[
                  _sectionTitle('Clinical Photos'),
                  _imageRow('Pre Operative', widget.caseData['photoPreOp']),
                  _imageRow('Intraoperative', widget.caseData['photoIntraOp']),
                  _imageRow('Post Operative', widget.caseData['photoPostOp']),
                  const SizedBox(height: 20),
                ],
                if (status == 'pending') ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          // ✅ context (screen context) pass pannurom
                          onPressed: () => _showSignatureDialog(context, 'approved'),
                          icon: const Icon(Icons.check),
                          label: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showRejectDialog(context),
                          icon: const Icon(Icons.close),
                          label: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (status == 'rejected' && widget.caseData['rejectReason'] != null) ...[
                  const SizedBox(height: 20),
                  _sectionTitle('Rejection Reason'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade900.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade700),
                    ),
                    child: Text(widget.caseData['rejectReason'], style: const TextStyle(fontSize: 14, color: Colors.redAccent)),
                  ),
                ],
                if (widget.caseData['facultySignature'] != null) ...[
                  const SizedBox(height: 20),
                  _sectionTitle('Faculty Signature'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F2040),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2A3F60)),
                    ),
                    child: Image.memory(base64Decode(widget.caseData['facultySignature']), height: 80, fit: BoxFit.contain),
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _imageRow(String label, String? url) {
    if (!_hasImage(url)) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF8899BB), fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              url!,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator()),
              errorBuilder: (context, error, stack) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFC9A84C))),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF8899BB), fontWeight: FontWeight.w500))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white))),
        ],
      ),
    );
  }
}