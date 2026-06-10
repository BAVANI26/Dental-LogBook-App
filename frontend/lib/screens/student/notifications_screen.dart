import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'my_cases_screen.dart';

// ─── Notification Helper ──────────────────────────────────────────────────────
class NotificationHelper {
  static Future<void> sendNotification({
    required String studentUid,
    required String caseId,
    required String patientName,
    required String action,
    String? rejectReason,
  }) async {
    final title = action == 'approved' ? '✅ Case Approved!' : '❌ Case Rejected';
    final body = action == 'approved'
        ? 'Your case for $patientName has been approved by faculty.'
        : 'Your case for $patientName has been rejected. Please check and resubmit.';

    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': studentUid,
      'title': title,
      'body': body,
      'caseId': caseId,
      'patientName': patientName,
      'action': action,
      'rejectReason': rejectReason,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

// ─── Notification Badge Widget ────────────────────────────────────────────────
class NotificationBadge extends StatelessWidget {
  final Widget child;
  const NotificationBadge({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return child;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: uid)
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            if (count > 0)
              Positioned(
                right: -6,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ─── Notifications Screen ─────────────────────────────────────────────────────
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

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
            TextSpan(text: 'Notifications', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFC9A84C))),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final batch = FirebaseFirestore.instance.batch();
              final snap = await FirebaseFirestore.instance
                  .collection('notifications')
                  .where('userId', isEqualTo: uid)
                  .where('isRead', isEqualTo: false)
                  .get();
              for (var doc in snap.docs) {
                batch.update(doc.reference, {'isRead': true});
              }
              await batch.commit();
            },
            child: const Text('Mark all read', style: TextStyle(color: Color(0xFFC9A84C), fontSize: 12)),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFC9A84C)));
          }

          final notifs = snapshot.data?.docs ?? [];

          if (notifs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 80, color: const Color(0xFF2A3F60)),
                  const SizedBox(height: 20),
                  const Text('No notifications yet!', style: TextStyle(fontSize: 18, color: Color(0xFF8899BB))),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifs.length,
            itemBuilder: (context, index) {
              final n = notifs[index].data() as Map<String, dynamic>;
              final isRead = n['isRead'] ?? false;
              final action = n['action'] ?? '';
              final isApproved = action == 'approved';

              return GestureDetector(
                onTap: () async {
                  // Mark as read
                  await notifs[index].reference.update({'isRead': true});

                  // Navigate to StudentCaseDetailScreen
                  final caseId = n['caseId'] as String?;
                  if (caseId != null && caseId.isNotEmpty) {
                    try {
                      final caseDoc = await FirebaseFirestore.instance
                          .collection('cases')
                          .doc(caseId)
                          .get();

                      if (caseDoc.exists && context.mounted) {
                        final caseData = caseDoc.data() as Map<String, dynamic>;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StudentCaseDetailScreen(
                              caseId: caseId,
                              caseData: caseData,
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F2040),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isRead
                          ? const Color(0xFF2A3F60)
                          : (isApproved ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5)),
                      width: isRead ? 1 : 1.5,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: isApproved ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isApproved ? Icons.check_circle : Icons.cancel,
                          color: isApproved ? Colors.green : Colors.red,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    n['title'] ?? '',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                if (!isRead)
                                  Container(
                                    width: 8, height: 8,
                                    decoration: const BoxDecoration(color: Color(0xFFC9A84C), shape: BoxShape.circle),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(n['body'] ?? '', style: const TextStyle(fontSize: 13, color: Color(0xFF8899BB))),
                            if (n['rejectReason'] != null && n['rejectReason'].toString().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                                ),
                                child: Text('Reason: ${n['rejectReason']}',
                                    style: const TextStyle(fontSize: 12, color: Colors.redAccent)),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Text('View Case →',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isApproved ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.w600,
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}