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
      final pathString = 'users/$userId/profile_image$extension';
      developer.log('Attempting upload to path: $pathString (UserId: $userId)');
      final ref = _storage.ref().child(pathString);

      final metadata = SettableMetadata(
        contentType: 'image/${extension.replaceAll('.', '')}',
        customMetadata: {'picked-file-path': imageFile.path},
      );

      // Retry logic for unstable connections
      for (int i = 0; i < 3; i++) {
        try {
          final uploadTask = ref.putFile(imageFile, metadata);
          final snapshot = await uploadTask;

          if (snapshot.state == TaskState.success) {
            final downloadUrl = await snapshot.ref.getDownloadURL();
            return downloadUrl;
          }
        } catch (e) {
          developer.log('Upload attempt ${i + 1} failed: $e');
          if (i == 2) {
            // Throw the error on the last attempt so UI can see it
            throw Exception('Upload failed after 3 attempts: $e');
          }
          await Future.delayed(Duration(seconds: (i + 1) * 2));
        }
      }
      throw Exception('Upload failed: Unknown error');
    } catch (e) {
      developer.log('Error preparing profile image upload: $e');
      rethrow; // Allow UI to handle/display the specific error
    }
  }
}
