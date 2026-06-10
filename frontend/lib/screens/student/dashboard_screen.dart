import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'add_case_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

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
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
              icon: const Icon(Icons.logout, color: Color(0xFFC9A84C), size: 18),
              label: const Text('Logout', style: TextStyle(color: Color(0xFFC9A84C))),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
                    builder: (context, snapshot) {
                      final name = snapshot.data?['name'] ?? 'Student';
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome Back, $name 👋',
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 6),
                          const Text('Track your dental cases easily',
                              style: TextStyle(fontSize: 15, color: Color(0xFF8899BB))),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('cases')
                        .where('userId', isEqualTo: uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final docs = snapshot.data?.docs ?? [];
                      final total = docs.length;
                      final approved = docs.where((d) => (d.data() as Map)['status'] == 'approved').length;
                      final pending = docs.where((d) => (d.data() as Map)['status'] == 'pending').length;
                      final rejected = docs.where((d) => (d.data() as Map)['status'] == 'rejected').length;

                      final Map<String, int> procedureCount = {};
                      for (var doc in docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        final procedure = data['procedureType'] ?? 'Others';
                        procedureCount[procedure] = (procedureCount[procedure] ?? 0) + 1;
                      }

                      final Map<String, int> monthlyApproved = {};
                      final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
                      for (var doc in docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        if (data['status'] == 'approved' && data['createdAt'] != null) {
                          final date = (data['createdAt'] as dynamic).toDate();
                          final key = months[date.month - 1];
                          monthlyApproved[key] = (monthlyApproved[key] ?? 0) + 1;
                        }
                      }

                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _statCard('Total Cases', '$total', Icons.folder_copy, const Color(0xFF4A90D9), docs, 'all', context)),
                              const SizedBox(width: 8),
                              Expanded(child: _statCard('Approved', '$approved', Icons.check_circle, const Color(0xFF4CAF50), docs, 'approved', context)),
                              const SizedBox(width: 8),
                              Expanded(child: _statCard('Pending', '$pending', Icons.pending, const Color(0xFFFF9800), docs, 'pending', context)),
                              const SizedBox(width: 8),
                              Expanded(child: _statCard('Rejected', '$rejected', Icons.cancel, const Color(0xFFE53935), docs, 'rejected', context)),
                            ],
                          ),
                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: () async => await _generateLogbookPdf(context, docs),
                              icon: const Icon(Icons.menu_book),
                              label: const Text('Export Logbook PDF', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFC9A84C),
                                foregroundColor: const Color(0xFF0A1628),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isMobile = constraints.maxWidth < 600;
                              if (isMobile) {
                                return Column(
                                  children: [
                                    if (procedureCount.isNotEmpty) ...[
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
                                            const Text('Procedure Summary 🦷',
                                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFC9A84C))),
                                            const SizedBox(height: 16),
                                            ...procedureCount.entries.map((entry) {
                                              final percent = total == 0 ? 0.0 : entry.value / total;
                                              return Padding(
                                                padding: const EdgeInsets.only(bottom: 12),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Flexible(child: Text(entry.key, style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                                                        Text('${entry.value} cases', style: const TextStyle(fontSize: 13, color: Color(0xFFC9A84C), fontWeight: FontWeight.bold)),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 6),
                                                    LinearProgressIndicator(
                                                      value: percent,
                                                      backgroundColor: const Color(0xFF2A3F60),
                                                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC9A84C)),
                                                      minHeight: 8,
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                    ],
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
                                          const Text('Monthly Progress 📊',
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFC9A84C))),
                                          const SizedBox(height: 16),
                                          monthlyApproved.isEmpty
                                              ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No approved cases yet!', style: TextStyle(color: Color(0xFF8899BB)))))
                                              : SizedBox(
                                                  height: 180,
                                                  child: Row(
                                                    crossAxisAlignment: CrossAxisAlignment.end,
                                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                    children: monthlyApproved.entries.map((entry) {
                                                      final maxVal = monthlyApproved.values.reduce((a, b) => a > b ? a : b);
                                                      final barHeight = maxVal == 0 ? 0.0 : (entry.value / maxVal) * 120;
                                                      return Column(
                                                        mainAxisAlignment: MainAxisAlignment.end,
                                                        children: [
                                                          Text('${entry.value}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFC9A84C))),
                                                          const SizedBox(height: 4),
                                                          Container(width: 28, height: barHeight, decoration: BoxDecoration(color: const Color(0xFFC9A84C), borderRadius: BorderRadius.circular(6))),
                                                          const SizedBox(height: 6),
                                                          Text(entry.key, style: const TextStyle(fontSize: 11, color: Color(0xFF8899BB))),
                                                        ],
                                                      );
                                                    }).toList(),
                                                  ),
                                                ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (procedureCount.isNotEmpty) ...[
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0F2040),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: const Color(0xFF2A3F60)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Procedure Summary 🦷',
                                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFC9A84C))),
                                            const SizedBox(height: 16),
                                            ...procedureCount.entries.map((entry) {
                                              final percent = total == 0 ? 0.0 : entry.value / total;
                                              return Padding(
                                                padding: const EdgeInsets.only(bottom: 12),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Text(entry.key, style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w600)),
                                                        Text('${entry.value} cases', style: const TextStyle(fontSize: 13, color: Color(0xFFC9A84C), fontWeight: FontWeight.bold)),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 6),
                                                    LinearProgressIndicator(
                                                      value: percent,
                                                      backgroundColor: const Color(0xFF2A3F60),
                                                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC9A84C)),
                                                      minHeight: 8,
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                  ],
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F2040),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: const Color(0xFF2A3F60)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Monthly Progress 📊',
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFC9A84C))),
                                          const SizedBox(height: 16),
                                          monthlyApproved.isEmpty
                                              ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No approved cases yet!', style: TextStyle(color: Color(0xFF8899BB)))))
                                              : SizedBox(
                                                  height: 180,
                                                  child: Row(
                                                    crossAxisAlignment: CrossAxisAlignment.end,
                                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                    children: monthlyApproved.entries.map((entry) {
                                                      final maxVal = monthlyApproved.values.reduce((a, b) => a > b ? a : b);
                                                      final barHeight = maxVal == 0 ? 0.0 : (entry.value / maxVal) * 120;
                                                      return Column(
                                                        mainAxisAlignment: MainAxisAlignment.end,
                                                        children: [
                                                          Text('${entry.value}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFC9A84C))),
                                                          const SizedBox(height: 4),
                                                          Container(width: 28, height: barHeight, decoration: BoxDecoration(color: const Color(0xFFC9A84C), borderRadius: BorderRadius.circular(6))),
                                                          const SizedBox(height: 6),
                                                          Text(entry.key, style: const TextStyle(fontSize: 11, color: Color(0xFF8899BB))),
                                                        ],
                                                      );
                                                    }).toList(),
                                                  ),
                                                ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                  ),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AddCaseScreen()));
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add New Case', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F2040),
                        foregroundColor: const Color(0xFFC9A84C),
                        side: const BorderSide(color: Color(0xFFC9A84C)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color, List<QueryDocumentSnapshot> docs, String filter, BuildContext context) {
    return GestureDetector(
      onTap: () {
        final filtered = filter == 'all' ? docs : docs.where((d) => (d.data() as Map)['status'] == filter).toList();
        Navigator.push(context, MaterialPageRoute(builder: (context) => FilteredCasesScreen(title: title, cases: filtered, color: color)));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F2040),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF8899BB)), softWrap: true),
          ],
        ),
      ),
    );
  }

  Future<void> _generateLogbookPdf(BuildContext context, List<QueryDocumentSnapshot> docs) async {
    if (docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No cases to export!')));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating Logbook PDF... Please wait ⏳'), duration: Duration(seconds: 2)),
    );
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text('LogoDent', style: pw.TextStyle(fontSize: 40, fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
              pw.SizedBox(height: 10),
              pw.Text('Dental Case Logbook', style: pw.TextStyle(fontSize: 24, color: PdfColors.grey700)),
              pw.SizedBox(height: 6),
              pw.Text('Track. Learn. Progress.', style: pw.TextStyle(fontSize: 16, fontStyle: pw.FontStyle.italic, color: PdfColors.grey)),
              pw.SizedBox(height: 40),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text('Total Cases: ${docs.length}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text('Approved: ${docs.where((d) => (d.data() as Map)['status'] == 'approved').length}', style: pw.TextStyle(fontSize: 16, color: PdfColors.green)),
              pw.SizedBox(height: 6),
              pw.Text('Pending: ${docs.where((d) => (d.data() as Map)['status'] == 'pending').length}', style: pw.TextStyle(fontSize: 16, color: PdfColors.orange)),
              pw.SizedBox(height: 6),
              pw.Text('Rejected: ${docs.where((d) => (d.data() as Map)['status'] == 'rejected').length}', style: pw.TextStyle(fontSize: 16, color: PdfColors.red)),
              pw.SizedBox(height: 40),
              pw.Text('Generated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}', style: pw.TextStyle(fontSize: 13, color: PdfColors.grey)),
            ],
          ),
        ),
      ),
    );
    for (int i = 0; i < docs.length; i++) {
      final c = docs[i].data() as Map<String, dynamic>;
      final status = c['status'] ?? 'draft';
      pw.MemoryImage? signatureImage;
      if (c['facultySignature'] != null) {
        try { final bytes = base64Decode(c['facultySignature']); signatureImage = pw.MemoryImage(bytes); } catch (_) {}
      }
      final xrayPre = await _loadNetworkImage(c['xrayPreOp']);
      final xrayPost = await _loadNetworkImage(c['xrayPostOp']);
      final photoPre = await _loadNetworkImage(c['photoPreOp']);
      final photoPost = await _loadNetworkImage(c['photoPostOp']);
      PdfColor statusColor = PdfColors.grey;
      if (status == 'approved') statusColor = PdfColors.green;
      if (status == 'pending') statusColor = PdfColors.orange;
      if (status == 'rejected') statusColor = PdfColors.red;
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('Case #${i + 1}', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: pw.BoxDecoration(color: statusColor, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12))),
              child: pw.Text(status.toUpperCase(), style: pw.TextStyle(fontSize: 12, color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
            ),
          ]),
          pw.SizedBox(height: 10), pw.Divider(), pw.SizedBox(height: 10),
          _pdfRow('Patient Name', c['patientName'] ?? '-'),
          _pdfRow('Patient ID', c['patientId'] ?? '-'),
          _pdfRow('Age', c['age'] ?? '-'),
          _pdfRow('Gender', c['gender'] ?? '-'),
          _pdfRow('Tooth Number', c['toothNumber'] ?? '-'),
          _pdfRow('Procedure', c['procedureType'] ?? '-'),
          _pdfRow('Diagnosis', c['diagnosis'] ?? '-'),
          _pdfRow('Notes', c['notes'] ?? '-'),
          pw.SizedBox(height: 10),
          if (xrayPre != null || xrayPost != null) ...[
            pw.Divider(), pw.SizedBox(height: 8),
            pw.Text('X-Ray Images', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
            pw.SizedBox(height: 8),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly, children: [
              if (xrayPre != null) pw.Column(children: [pw.Image(xrayPre, width: 120, height: 100), pw.Text('Pre Op', style: const pw.TextStyle(fontSize: 9))]),
              if (xrayPost != null) pw.Column(children: [pw.Image(xrayPost, width: 120, height: 100), pw.Text('Post Op', style: const pw.TextStyle(fontSize: 9))]),
            ]),
            pw.SizedBox(height: 10),
          ],
          if (photoPre != null || photoPost != null) ...[
            pw.Divider(), pw.SizedBox(height: 8),
            pw.Text('Clinical Photos', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
            pw.SizedBox(height: 8),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly, children: [
              if (photoPre != null) pw.Column(children: [pw.Image(photoPre, width: 120, height: 100), pw.Text('Pre Op', style: const pw.TextStyle(fontSize: 9))]),
              if (photoPost != null) pw.Column(children: [pw.Image(photoPost, width: 120, height: 100), pw.Text('Post Op', style: const pw.TextStyle(fontSize: 9))]),
            ]),
            pw.SizedBox(height: 10),
          ],
          if (signatureImage != null) ...[
            pw.Divider(), pw.SizedBox(height: 8),
            pw.Text('Faculty Signature', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
            pw.SizedBox(height: 6),
            pw.Container(width: 160, height: 60, decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey)), child: pw.Image(signatureImage)),
          ],
          pw.SizedBox(height: 10), pw.Divider(),
        ],
      ));
    }
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  Future<pw.MemoryImage?> _loadNetworkImage(String? url) async {
    if (url == null || url.isEmpty) return null;
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) return pw.MemoryImage(response.bodyBytes);
    } catch (e) { return null; }
    return null;
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.SizedBox(width: 130, child: pw.Text(label, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700))),
        pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 12))),
      ]),
    );
  }
}

class FilteredCasesScreen extends StatelessWidget {
  final String title;
  final List<QueryDocumentSnapshot> cases;
  final Color color;

  const FilteredCasesScreen({super.key, required this.title, required this.cases, required this.color});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F2040),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Color(0xFFC9A84C)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: cases.isEmpty
              ? const Center(child: Text('No cases found!', style: TextStyle(color: Colors.white54, fontSize: 18)))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: cases.length,
                  itemBuilder: (context, index) {
                    final c = cases[index].data() as Map<String, dynamic>;
                    final caseId = cases[index].id;
                    final status = c['status'] ?? 'pending';
                    Color statusColor = Colors.orange;
                    if (status == 'draft') statusColor = Colors.grey;
                    if (status == 'approved') statusColor = Colors.green;
                    if (status == 'rejected') statusColor = Colors.red;
                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DashboardCaseDetailScreen(caseId: caseId, caseData: c))),
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
                                  Text('ID: ${c['patientId'] ?? ''} | ${c['procedureType'] ?? c['diagnosis'] ?? ''}',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF8899BB))),
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
                ),
        ),
      ),
    );
  }
}

class DashboardCaseDetailScreen extends StatelessWidget {
  final String caseId;
  final Map<String, dynamic> caseData;

  const DashboardCaseDetailScreen({super.key, required this.caseId, required this.caseData});

  Future<pw.MemoryImage?> _loadNetworkImage(String? url) async {
    if (url == null || url.isEmpty) return null;
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) return pw.MemoryImage(response.bodyBytes);
    } catch (e) { return null; }
    return null;
  }

  Future<void> _generatePdf() async {
    final pdf = pw.Document();
    pw.MemoryImage? signatureImage;
    if (caseData['facultySignature'] != null) {
      final bytes = base64Decode(caseData['facultySignature']);
      signatureImage = pw.MemoryImage(bytes);
    }
    final xrayPre = await _loadNetworkImage(caseData['xrayPreOp']);
    final xrayIntra = await _loadNetworkImage(caseData['xrayIntraOp']);
    final xrayPost = await _loadNetworkImage(caseData['xrayPostOp']);
    final photoPre = await _loadNetworkImage(caseData['photoPreOp']);
    final photoIntra = await _loadNetworkImage(caseData['photoIntraOp']);
    final photoPost = await _loadNetworkImage(caseData['photoPostOp']);
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) => [
        pw.Text('LogoDent — Dental Case Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.Text('Track. Learn. Progress.', style: pw.TextStyle(fontSize: 14, fontStyle: pw.FontStyle.italic, color: PdfColors.grey)),
        pw.SizedBox(height: 20), pw.Divider(), pw.SizedBox(height: 10),
        pw.Text('PATIENT INFORMATION', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
        pw.SizedBox(height: 10),
        _pdfRow('Patient Name', caseData['patientName'] ?? '-'),
        _pdfRow('Patient ID', caseData['patientId'] ?? '-'),
        _pdfRow('Age', caseData['age'] ?? '-'),
        _pdfRow('Gender', caseData['gender'] ?? '-'),
        _pdfRow('Tooth Number', caseData['toothNumber'] ?? '-'),
        pw.SizedBox(height: 15), pw.Divider(), pw.SizedBox(height: 10),
        pw.Text('CASE INFORMATION', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
        pw.SizedBox(height: 10),
        _pdfRow('Procedure Type', caseData['procedureType'] ?? '-'),
        _pdfRow('Diagnosis', caseData['diagnosis'] ?? '-'),
        _pdfRow('Treatment Notes', caseData['notes'] ?? '-'),
        pw.SizedBox(height: 15), pw.Divider(), pw.SizedBox(height: 10),
        if (xrayPre != null || xrayIntra != null || xrayPost != null) ...[
          pw.Text('X-RAY IMAGES', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
          pw.SizedBox(height: 10),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly, children: [
            if (xrayPre != null) pw.Column(children: [pw.Image(xrayPre, width: 150, height: 120), pw.SizedBox(height: 4), pw.Text('Pre Operative', style: const pw.TextStyle(fontSize: 10))]),
            if (xrayIntra != null) pw.Column(children: [pw.Image(xrayIntra, width: 150, height: 120), pw.SizedBox(height: 4), pw.Text('Intraoperative', style: const pw.TextStyle(fontSize: 10))]),
            if (xrayPost != null) pw.Column(children: [pw.Image(xrayPost, width: 150, height: 120), pw.SizedBox(height: 4), pw.Text('Post Operative', style: const pw.TextStyle(fontSize: 10))]),
          ]),
          pw.SizedBox(height: 15), pw.Divider(), pw.SizedBox(height: 10),
        ],
        if (photoPre != null || photoIntra != null || photoPost != null) ...[
          pw.Text('CLINICAL PHOTOS', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
          pw.SizedBox(height: 10),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly, children: [
            if (photoPre != null) pw.Column(children: [pw.Image(photoPre, width: 150, height: 120), pw.SizedBox(height: 4), pw.Text('Pre Operative', style: const pw.TextStyle(fontSize: 10))]),
            if (photoIntra != null) pw.Column(children: [pw.Image(photoIntra, width: 150, height: 120), pw.SizedBox(height: 4), pw.Text('Intraoperative', style: const pw.TextStyle(fontSize: 10))]),
            if (photoPost != null) pw.Column(children: [pw.Image(photoPost, width: 150, height: 120), pw.SizedBox(height: 4), pw.Text('Post Operative', style: const pw.TextStyle(fontSize: 10))]),
          ]),
          pw.SizedBox(height: 15), pw.Divider(), pw.SizedBox(height: 10),
        ],
        pw.Text('APPROVAL STATUS', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
        pw.SizedBox(height: 10),
        _pdfRow('Status', (caseData['status'] ?? 'draft').toUpperCase()),
        if (caseData['rejectReason'] != null && caseData['rejectReason'].toString().isNotEmpty)
          _pdfRow('Rejection Reason', caseData['rejectReason']),
        pw.SizedBox(height: 15),
        if (signatureImage != null) ...[
          pw.Divider(), pw.SizedBox(height: 10),
          pw.Text('FACULTY SIGNATURE', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
          pw.SizedBox(height: 10),
          pw.Container(width: 200, height: 80, decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey)), child: pw.Image(signatureImage)),
          pw.SizedBox(height: 6),
          pw.Text('Digitally signed by Faculty', style: pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic, color: PdfColors.grey)),
        ],
        pw.SizedBox(height: 20), pw.Divider(), pw.SizedBox(height: 8),
        pw.Text('Generated by LogoDent App', style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic, color: PdfColors.grey)),
      ],
    ));
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.SizedBox(width: 150, child: pw.Text(label, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700))),
        pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 13))),
      ]),
    );
  }

  bool _hasImage(dynamic url) => url != null && url.toString().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final status = caseData['status'] ?? 'draft';
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
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: statusColor.withOpacity(0.4))),
                    child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 24),
                _sectionTitle('Patient Information'),
                _infoRow('Patient Name', caseData['patientName'] ?? '-'),
                _infoRow('Patient ID', caseData['patientId'] ?? '-'),
                _infoRow('Age', caseData['age'] ?? '-'),
                _infoRow('Gender', caseData['gender'] ?? '-'),
                _infoRow('Tooth Number', caseData['toothNumber'] ?? '-'),
                const SizedBox(height: 20),
                _sectionTitle('Case Information'),
                _infoRow('Procedure Type', caseData['procedureType'] ?? '-'),
                _infoRow('Diagnosis', caseData['diagnosis'] ?? '-'),
                _infoRow('Treatment Notes', caseData['notes'] ?? '-'),
                const SizedBox(height: 20),
                if (_hasImage(caseData['xrayPreOp']) || _hasImage(caseData['xrayIntraOp']) || _hasImage(caseData['xrayPostOp'])) ...[
                  _sectionTitle('X-Ray Images'),
                  _imageRow('Pre Operative', caseData['xrayPreOp']),
                  _imageRow('Intraoperative', caseData['xrayIntraOp']),
                  _imageRow('Post Operative', caseData['xrayPostOp']),
                  const SizedBox(height: 20),
                ],
                if (_hasImage(caseData['photoPreOp']) || _hasImage(caseData['photoIntraOp']) || _hasImage(caseData['photoPostOp'])) ...[
                  _sectionTitle('Clinical Photos'),
                  _imageRow('Pre Operative', caseData['photoPreOp']),
                  _imageRow('Intraoperative', caseData['photoIntraOp']),
                  _imageRow('Post Operative', caseData['photoPostOp']),
                  const SizedBox(height: 20),
                ],
                if (status == 'rejected' && caseData['rejectReason'] != null && caseData['rejectReason'].toString().isNotEmpty) ...[
                  _sectionTitle('Rejection Reason'),
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.red.shade900.withOpacity(0.3), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade700)),
                    child: Text(caseData['rejectReason'], style: const TextStyle(fontSize: 14, color: Colors.redAccent)),
                  ),
                  const SizedBox(height: 20),
                ],
                if (caseData['facultySignature'] != null) ...[
                  _sectionTitle('Faculty Signature'),
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFF0F2040), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF2A3F60))),
                    child: Image.memory(base64Decode(caseData['facultySignature']), height: 80, fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 20),
                ],
                SizedBox(
                  width: double.infinity, height: 55,
                  child: ElevatedButton.icon(
                    onPressed: _generatePdf,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Export as PDF', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC9A84C),
                      foregroundColor: const Color(0xFF0A1628),
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
            child: Image.network(url!, height: 150, width: double.infinity, fit: BoxFit.cover,
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
          SizedBox(width: 140, child: Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF8899BB), fontWeight: FontWeight.w500))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white))),
        ],
      ),
    );
  }
}