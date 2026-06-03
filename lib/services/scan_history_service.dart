import 'package:cloud_firestore/cloud_firestore.dart';

class ScanHistoryService {
  final _db = FirebaseFirestore.instance;
  final String _collection = 'scan_history';

  // Save a scan result
  Future<void> saveScan({
    required String leafName,
    required String result,
    required double confidence,
    String? imagePath,
  }) async {
    await _db.collection(_collection).add({
      'leafName': leafName,
      'result': result,
      'confidence': confidence,
      'imagePath': imagePath ?? '',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Get all scan history, works offline too
  Stream<QuerySnapshot> getScanHistory() {
    return _db
        .collection(_collection)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Delete a scan
  Future<void> deleteScan(String docId) async {
    await _db.collection(_collection).doc(docId).delete();
  }
}
