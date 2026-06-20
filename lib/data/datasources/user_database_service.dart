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
      debugPrint("Starting image upload for user: $userId");

      // 1. Compress Image
      debugPrint("Compressing image...");
      final tempDir = await getTemporaryDirectory();
      final targetPath = p.join(
        tempDir.path,
        '${userId}_compressed_profile.webp',
      );

      final compressedXFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: 40, // Reduced quality from 60 to 40 for much faster uploads
        minWidth: 400,
        minHeight: 400,
        format: CompressFormat.webp,
      );

      final fileToUpload = compressedXFile != null
          ? File(compressedXFile.path)
          : imageFile;

      // Clean up legacy .jpg file if it exists so we don't have duplicates
      try {
        await _storage.ref().child('user_images').child('$userId.jpg').delete();
        debugPrint("Deleted legacy .jpg profile image.");
      } catch (e) {
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

      final uploadTask = ref.putFile(fileToUpload, metadata);
      final snapshot = await uploadTask;

      debugPrint("Upload finished. State: ${snapshot.state}");
      debugPrint(
        "Bytes transferred: ${snapshot.bytesTransferred} / ${snapshot.totalBytes}",
      );

      if (snapshot.state == TaskState.success) {
        final url = await ref.getDownloadURL();
        debugPrint("Download URL retrieved: $url");
        return url;
      } else {
        throw FirebaseException(
          plugin: 'firebase_storage',
          code: 'upload-failed',
          message: 'Upload task finished with state: ${snapshot.state}',
        );
      }
    } catch (e) {
      debugPrint("Error uploading image: $e");
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
      debugPrint("Error saving user: $e");
      rethrow;
    }
  }

  /// Update specific fields on a user document.
  Future<void> updateUserField(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update(data);
    } catch (e) {
      debugPrint("Error updating user field: $e");
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
      debugPrint("Error getting user (possibly timeout): $e");
      return null;
    }
  }

  DocumentSnapshot? _lastUserDoc;
  String? _lastGenderFilter;
  Future<List<domain.User>>? _inFlightUsersRequest;
  String? _inFlightUsersRequestKey;

  /// Get multiple users with optional gender filtering.
  Future<List<domain.User>> getUsers({
    String? gender,
    String? currentUserId,
    int limit = 10,
    bool refresh = false,
  }) async {
    final requestKey = '$gender|$currentUserId|$limit|$refresh';

    // Reuse identical in-flight requests; otherwise wait for the current
    // request to finish before issuing a new one to keep pagination state safe.
    while (_inFlightUsersRequest != null) {
      if (_inFlightUsersRequestKey == requestKey) {
        return _inFlightUsersRequest!;
      }
      try {
        await _inFlightUsersRequest;
      } catch (_) {
        // Ignore previous failure and proceed with this request.
      }
    }

    final requestFuture = _fetchUsers(
      gender: gender,
      currentUserId: currentUserId,
      limit: limit,
      refresh: refresh,
    );
    _inFlightUsersRequest = requestFuture;
    _inFlightUsersRequestKey = requestKey;

    try {
      return await requestFuture;
    } finally {
      if (identical(_inFlightUsersRequest, requestFuture)) {
        _inFlightUsersRequest = null;
        _inFlightUsersRequestKey = null;
      }
    }
  }

  Future<List<domain.User>> _fetchUsers({
    required String? gender,
    required String? currentUserId,
    required int limit,
    required bool refresh,
  }) async {
    try {
      if (refresh || gender != _lastGenderFilter) {
        _lastUserDoc = null;
        _lastGenderFilter = gender;
      }

      Query query = _firestore.collection(_usersCollection);

      if (gender != null && gender != 'everyone') {
        query = query.where('gender', isEqualTo: gender);
      }

      if (_lastUserDoc != null) {
        query = query.startAfterDocument(_lastUserDoc!);
      }

      QuerySnapshot snapshot = await query.limit(limit).get();

      if (snapshot.docs.isNotEmpty) {
        _lastUserDoc = snapshot.docs.last;
      }

      return snapshot.docs
          .map((doc) {
            final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
            data['id'] = doc.id;
            return UserModel.fromMap(data);
          })
          .where((user) => user.id != currentUserId)
          .toList();
    } catch (e) {
      debugPrint("Error getting users: $e");
      return [];
    }
  }

  /// Delete user Firestore document and their profile image from Storage.
  Future<void> deleteUser(String uid) async {
    try {
      debugPrint("Deleting user data in Firestore for: $uid");
      await _firestore.collection(_usersCollection).doc(uid).delete();
      
      debugPrint("Deleting user profile image in Storage for: $uid");
      try {
        await _storage.ref().child('user_images').child('$uid.webp').delete();
        debugPrint("Successfully deleted profile image for user: $uid");
      } catch (e) {
        // Ignore file-not-found or other storage errors during account deletion
        debugPrint("Storage image deletion failed (likely didn't exist): $e");
      }
    } catch (e) {
      debugPrint("Error deleting user document and media: $e");
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
