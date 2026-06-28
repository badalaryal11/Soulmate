import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:soulmate/data/models/user_model.dart';
import '../../domain/entities/user.dart' as domain;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Handles all user-related Firestore and Storage operations.
class UserDatabaseService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final String _usersCollection = 'users';

  UserDatabaseService({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _storage = storage ?? FirebaseStorage.instance;

  /// Upload a profile image and return the download URL.
  Future<String> uploadProfileImage(String userId, File imageFile, {String? userName, String? email}) async {
    try {
      if (kDebugMode) debugPrint("Starting image upload for user: $userId");

      // 1. Compress Image
      if (kDebugMode) debugPrint("Compressing image...");
      final tempDir = await getTemporaryDirectory();
      final targetPath = p.join(
        tempDir.path,
        '${userId}_compressed_profile.webp',
      );

      if (kDebugMode) debugPrint("Calling FlutterImageCompress.compressAndGetFile...");
      final compressedXFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: 40, // Reduced quality from 60 to 40 for much faster uploads
        minWidth: 400,
        minHeight: 400,
        format: CompressFormat.webp,
      ).timeout(const Duration(seconds: 15), onTimeout: () {
        if (kDebugMode) debugPrint("FlutterImageCompress timed out!");
        throw Exception("Image compression timed out");
      });
      if (kDebugMode) debugPrint("FlutterImageCompress completed. Result: $compressedXFile");

      final fileToUpload = compressedXFile != null
          ? File(compressedXFile.path)
          : imageFile;

      // Clean up legacy .jpg file if it exists so we don't have duplicates
      try {
        if (kDebugMode) debugPrint("Attempting to delete legacy .jpg profile image...");
        await _storage.ref().child('user_images').child('$userId.jpg').delete()
          .timeout(const Duration(seconds: 5));
        if (kDebugMode) debugPrint("Deleted legacy .jpg profile image.");
      } catch (e) {
        if (kDebugMode) debugPrint("Legacy .jpg delete failed or not found: $e");
        // Ignore if it doesn't exist
      }

      final ref = _storage.ref().child('user_images').child('$userId.webp');

      final customMetadata = {'picked-file-path': imageFile.path};
      if (userName != null) customMetadata['userName'] = userName;
      if (email != null) customMetadata['email'] = email;

      final metadata = SettableMetadata(
        contentType: 'image/webp',
        customMetadata: customMetadata,
      );

      if (kDebugMode) debugPrint("Starting putFile...");
      final uploadTask = ref.putFile(fileToUpload, metadata);
      
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (kDebugMode) debugPrint('Upload progress: ${snapshot.bytesTransferred}/${snapshot.totalBytes}');
      }, onError: (e) {
        if (kDebugMode) debugPrint('Upload task error event: $e');
      });

      if (kDebugMode) debugPrint("Awaiting uploadTask...");
      final snapshot = await uploadTask.timeout(const Duration(seconds: 30), onTimeout: () {
        if (kDebugMode) debugPrint("UploadTask timed out!");
        throw Exception("Upload to Firebase Storage timed out");
      });

      if (kDebugMode) debugPrint("Upload finished. State: ${snapshot.state}");
      if (kDebugMode) {
        debugPrint(
        "Bytes transferred: ${snapshot.bytesTransferred} / ${snapshot.totalBytes}",
      );
      }

      if (snapshot.state == TaskState.success) {
        if (kDebugMode) debugPrint("Getting download URL...");
        final url = await ref.getDownloadURL().timeout(const Duration(seconds: 10), onTimeout: () {
           if (kDebugMode) debugPrint("getDownloadURL timed out!");
           throw Exception("Getting download URL timed out");
        });
        if (kDebugMode) debugPrint("Download URL retrieved: $url");
        return url;
      } else {
        throw FirebaseException(
          plugin: 'firebase_storage',
          code: 'upload-failed',
          message: 'Upload task finished with state: ${snapshot.state}',
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint("Error uploading image: $e");
      rethrow;
    }
  }

  /// Save or update a user document in Firestore.
  Future<void> saveUser(domain.User user) async {
    try {
      final userModel = UserModel(
        id: user.id,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        age: user.age,
        city: user.city,
        country: user.country,
        imageUrl: user.imageUrl,
        gender: user.gender,
        interests: user.interests,
        genderPreference: user.genderPreference,
        bio: user.bio,
        streak: user.streak,
        coins: user.coins,
        lastLoginDate: user.lastLoginDate,
        prompts: user.prompts,
        badges: user.badges,
        favoriteUserIds: user.favoriteUserIds,
        pinnedUserIds: user.pinnedUserIds,
      );
      await _firestore
          .collection(_usersCollection)
          .doc(user.id)
          .set(userModel.toMap(), SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) debugPrint("Error saving user: $e");
      rethrow;
    }
  }

  /// Update specific fields on a user document.
  Future<void> updateUserField(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update(data);
    } catch (e) {
      if (kDebugMode) debugPrint("Error updating user field: $e");
      rethrow;
    }
  }

  /// Get a single user by ID. Tries cache first for speed, falls back to server.
  Future<domain.User?> getUser(String uid) async {
    try {
      // Try cache first for faster reads
      DocumentSnapshot doc = await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .get(const GetOptions(source: Source.cache));
      if (doc.exists && doc.data() != null) {
        final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
        data['id'] = doc.id;
        return UserModel.fromMap(data);
      }
    } catch (_) {
      // Cache miss — fall through to server
    }

    try {
      DocumentSnapshot doc = await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 8));
      if (doc.exists && doc.data() != null) {
        final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
        data['id'] = doc.id;
        return UserModel.fromMap(data);
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint("Error getting user (possibly timeout): $e");
      return null;
    }
  }

  /// Get multiple users with optional gender filtering.
  Future<List<domain.User>> getUsers({
    String? gender,
    String? currentUserId,
    int limit = 10,
    String? lastUserId,
  }) async {
    return _fetchUsers(
      gender: gender,
      currentUserId: currentUserId,
      limit: limit,
      lastUserId: lastUserId,
    );
  }

  Future<List<domain.User>> _fetchUsers({
    required String? gender,
    required String? currentUserId,
    required int limit,
    required String? lastUserId,
  }) async {
    try {
      Query query = _firestore.collection(_usersCollection);

      if (gender != null && gender.toLowerCase() != 'everyone') {
        final capitalizedGender = gender[0].toUpperCase() + gender.substring(1).toLowerCase();
        query = query.where('gender', isEqualTo: capitalizedGender);
      }

      if (lastUserId != null) {
        DocumentSnapshot doc = await _firestore.collection(_usersCollection).doc(lastUserId).get();
        if (doc.exists) {
          query = query.startAfterDocument(doc);
        }
      }

      QuerySnapshot snapshot = await query.limit(limit).get();

      return snapshot.docs
          .map((doc) {
            final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
            data['id'] = doc.id;
            return UserModel.fromMap(data);
          })
          .where((user) => user.id != currentUserId)
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint("Error getting users: $e");
      return [];
    }
  }

  /// Delete user Firestore document and their profile image from Storage.
  Future<void> deleteUser(String uid) async {
    try {
      if (kDebugMode) debugPrint("Deleting user data in Firestore for: $uid");
      await _firestore.collection(_usersCollection).doc(uid).delete();
      
      if (kDebugMode) debugPrint("Deleting user profile image in Storage for: $uid");
      try {
        await _storage.ref().child('user_images').child('$uid.webp').delete();
        if (kDebugMode) debugPrint("Successfully deleted profile image for user: $uid");
      } catch (e) {
        // Ignore file-not-found or other storage errors during account deletion
        if (kDebugMode) debugPrint("Storage image deletion failed (likely didn't exist): $e");
      }
    } catch (e) {
      if (kDebugMode) debugPrint("Error deleting user document and media: $e");
      rethrow;
    }
  }

  /// Batch-delete all user documents (admin/debug only).
  Future<void> deleteAllUsers() async {
    final users = await _firestore.collection(_usersCollection).get();
    WriteBatch batch = _firestore.batch();
    int count = 0;
    for (var doc in users.docs) {
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
