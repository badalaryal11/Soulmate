import '../repositories/user_repository.dart';

class SaveFeedbackUseCase {
  final UserRepository repository;

  SaveFeedbackUseCase(this.repository);

  Future<void> call(String userId, String message) async {
    return await repository.saveFeedback(userId, message);
  }
}
