import 'dart:developer' as developer;
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  Future<String?> uploadProfileImage(File imageFile, String userId) async {
    try {
      // final fileName = path.basename(imageFile.path); // Unused
      final extension = path.extension(imageFile.path); // e.g. '.jpg'

      // Use a consistent path structure: users/{userId}/profile_image{extension}
      // This overwrites previous images, saving space.
      final ref = _storage.ref().child('users/$userId/profile_image$extension');

      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;

      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      // Log or handle error appropriately in a real app
      developer.log('Error uploading profile image: $e');
      return null;
    }
  }
}
