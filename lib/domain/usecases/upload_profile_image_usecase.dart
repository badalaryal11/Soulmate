import '../repositories/user_repository.dart';

class UploadProfileImageUseCase {
  final UserRepository repository;

  UploadProfileImageUseCase(this.repository);

  Future<String> call(String userId, dynamic imageFile, {String? userName, String? email}) async {
    return await repository.uploadProfileImage(userId, imageFile, userName: userName, email: email);
  }
}
