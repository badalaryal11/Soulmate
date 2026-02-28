import '../repositories/user_repository.dart';

class UploadProfileImageUseCase {
  final UserRepository repository;

  UploadProfileImageUseCase(this.repository);

  Future<String> call(String userId, dynamic imageFile) async {
    return await repository.uploadProfileImage(userId, imageFile);
  }
}
