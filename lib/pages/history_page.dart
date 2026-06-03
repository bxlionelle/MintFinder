import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  Color _confidenceColor(double confidence) {
    if (confidence >= 0.85) return Colors.greenAccent;
    if (confidence >= 0.65) return Colors.yellowAccent;
    return Colors.orangeAccent;
  }

  Future<void> _deleteScan(String docId) async {
    await FirebaseFirestore.instance
        .collection('scan_history')
        .doc(docId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E4F10),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E4F10),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Scan History",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('scan_history')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.greenAccent),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, color: Colors.white30, size: 64),
                  SizedBox(height: 16),
                  Text(
                    "No scans yet",
                    style: TextStyle(color: Colors.white54, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Your scan results will appear here",
                    style: TextStyle(color: Colors.white30, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;
              final label = data['label'] ?? 'Unknown';
              final confidence = (data['confidence'] ?? 0.0).toDouble();
              final confPercent = confidence * 100;
              final confColor = _confidenceColor(confidence);
              final timestamp = data['timestamp'] as Timestamp?;
              final date = timestamp != null
                  ? "${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}  ${timestamp.toDate().hour}:${timestamp.toDate().minute.toString().padLeft(2, '0')}"
                  : "Offline save";

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.eco,
                        color: Colors.greenAccent,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Label + date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            date,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Confidence badge
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "${confPercent.toStringAsFixed(1)}%",
                          style: TextStyle(
                            color: confColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Delete button
                        GestureDetector(
                          onTap: () => _deleteScan(docId),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white30,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
