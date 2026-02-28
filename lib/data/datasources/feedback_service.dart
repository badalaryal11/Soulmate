import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Handles saving and retrieving user feedback from Firestore.
class FeedbackService {
  final FirebaseFirestore _firestore;

  FeedbackService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Save user feedback to Firestore.
  Future<void> saveFeedback(String userId, String message) async {
    try {
      await _firestore.collection('feedback').add({
        'userId': userId,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error saving feedback: $e");
      rethrow;
    }
  }

  /// Batch-delete all feedback documents (admin/debug only).
  Future<void> deleteAllFeedback() async {
    final feedback = await _firestore.collection('feedback').get();
    WriteBatch batch = _firestore.batch();
    int count = 0;
    for (var doc in feedback.docs) {
      batch.delete(doc.reference);
      count++;
      if (count >= 500) {
        await batch.commit();
        batch = _firestore.batch();
        count = 0;
      }
    }
    await batch.commit();
  }
}
