import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MyCasesScreen extends StatelessWidget {
  const MyCasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F2040),
        elevation: 0,
        title: RichText(
          text: const TextSpan(children: [
            TextSpan(text: 'My ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            TextSpan(text: 'Cases', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFC9A84C))),
          ]),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('cases').where('userId', isEqualTo: uid).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFFC9A84C)));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open, size: 80, color: const Color(0xFF2A3F60)),
                      const SizedBox(height: 20),
                      const Text('No cases added yet!', style: TextStyle(fontSize: 18, color: Color(0xFF8899BB))),
                      const SizedBox(height: 10),
                      const Text('Go to Add Case tab to add your first case', style: TextStyle(fontSize: 14, color: Color(0xFF8899BB))),
                    ],
                  ),
                );
              }

              final cases = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: cases.length,
                itemBuilder: (context, index) {
                  final c = cases[index].data() as Map<String, dynamic>;
                  final caseId = cases[index].id;
                  final status = c['status'] ?? 'draft';

                  Color statusColor = const Color(0xFF8899BB);
                  if (status == 'pending') statusColor = Colors.orange;
                  if (status == 'approved') statusColor = Colors.green;
                  if (status == 'rejected') statusColor = Colors.red;

                  return GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => StudentCaseDetailScreen(caseId: caseId, caseData: c))),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F2040),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF2A3F60)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
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
                                    Text(c['patientName'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
                          if (status == 'draft') ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity, height: 42,
                              child: ElevatedButton.icon(
                                onPressed: () => _showSubmitDialog(context, caseId),
                                icon: const Icon(Icons.send, size: 16),
                                label: const Text('Submit to Faculty', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFC9A84C),
                                  foregroundColor: const Color(0xFF0A1628),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          ],
                          if (status == 'rejected') ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity, height: 42,
                              child: ElevatedButton.icon(
                                onPressed: () => _showSubmitDialog(context, caseId),
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Resubmit to Faculty', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          ],
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

  void _showSubmitDialog(BuildContext context, String caseId) {
    final facultyIdController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F2040),
        title: const Text('Submit to Faculty', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your Faculty ID to submit this case for review.', style: TextStyle(fontSize: 14, color: Color(0xFF8899BB))),
            const SizedBox(height: 16),
            TextField(
              controller: facultyIdController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Faculty ID',
                labelStyle: const TextStyle(color: Color(0xFF8899BB)),
                prefixIcon: const Icon(Icons.badge, color: Color(0xFFC9A84C)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2A3F60))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFC9A84C))),
                filled: true,
                fillColor: const Color(0xFF0A1628),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Color(0xFF8899BB)))),
          ElevatedButton(
            onPressed: () async {
              final enteredId = facultyIdController.text.trim();
              if (enteredId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter Faculty ID!')));
                return;
              }
              final facultyQuery = await FirebaseFirestore.instance.collection('users')
                  .where('facultyId', isEqualTo: enteredId).where('role', isEqualTo: 'faculty').get();
              if (facultyQuery.docs.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Faculty ID!'), backgroundColor: Colors.red));
                return;
              }
              final facultyUid = facultyQuery.docs.first.id;
              await FirebaseFirestore.instance.collection('cases').doc(caseId).update({
                'status': 'pending', 'facultyId': enteredId, 'facultyUid': facultyUid,
                'submittedToFaculty': true, 'submittedAt': FieldValue.serverTimestamp(),
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Case submitted! ✅'), backgroundColor: Colors.green));
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC9A84C), foregroundColor: const Color(0xFF0A1628)),
            child: const Text('Submit', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class StudentCaseDetailScreen extends StatelessWidget {
  final String caseId;
  final Map<String, dynamic> caseData;

  const StudentCaseDetailScreen({super.key, required this.caseId, required this.caseData});

  bool _hasImage(dynamic url) => url != null && url.toString().isNotEmpty;

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
        pw.SizedBox(height: 15),
        if (xrayPre != null || xrayIntra != null || xrayPost != null) ...[
          pw.Divider(), pw.SizedBox(height: 10),
          pw.Text('X-RAY IMAGES', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
          pw.SizedBox(height: 10),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly, children: [
            if (xrayPre != null) pw.Column(children: [pw.Image(xrayPre, width: 150, height: 120), pw.SizedBox(height: 4), pw.Text('Pre Operative', style: const pw.TextStyle(fontSize: 10))]),
            if (xrayIntra != null) pw.Column(children: [pw.Image(xrayIntra, width: 150, height: 120), pw.SizedBox(height: 4), pw.Text('Intraoperative', style: const pw.TextStyle(fontSize: 10))]),
            if (xrayPost != null) pw.Column(children: [pw.Image(xrayPost, width: 150, height: 120), pw.SizedBox(height: 4), pw.Text('Post Operative', style: const pw.TextStyle(fontSize: 10))]),
          ]),
          pw.SizedBox(height: 15),
        ],
        if (photoPre != null || photoIntra != null || photoPost != null) ...[
          pw.Divider(), pw.SizedBox(height: 10),
          pw.Text('CLINICAL PHOTOS', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
          pw.SizedBox(height: 10),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly, children: [
            if (photoPre != null) pw.Column(children: [pw.Image(photoPre, width: 150, height: 120), pw.SizedBox(height: 4), pw.Text('Pre Operative', style: const pw.TextStyle(fontSize: 10))]),
            if (photoIntra != null) pw.Column(children: [pw.Image(photoIntra, width: 150, height: 120), pw.SizedBox(height: 4), pw.Text('Intraoperative', style: const pw.TextStyle(fontSize: 10))]),
            if (photoPost != null) pw.Column(children: [pw.Image(photoPost, width: 150, height: 120), pw.SizedBox(height: 4), pw.Text('Post Operative', style: const pw.TextStyle(fontSize: 10))]),
          ]),
          pw.SizedBox(height: 15),
        ],
        pw.Divider(), pw.SizedBox(height: 10),
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

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F2040),
        title: const Text('Delete Case', style: TextStyle(color: Colors.white)),
        content: const Text('Delete pannina recover pannave mudiyadu! Sure-aa?', style: TextStyle(color: Color(0xFF8899BB))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Color(0xFF8899BB)))),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('cases').doc(caseId).delete();
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Case deleted! 🗑️'), backgroundColor: Colors.red));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

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
        actions: [
          if (status == 'draft')
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteDialog(context),
            ),
        ],
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
                  width: double.infinity, height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _generatePdf,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Export as PDF', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
          SizedBox(width: 130, child: Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF8899BB), fontWeight: FontWeight.w500))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white))),
        ],
      ),
    );
  }
}