import '../models/user_model.dart';
import '../services/api_service.dart';

class UserRepository {
  final ApiService _apiService;

  UserRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  Future<List<User>> getUsers({String? gender}) async {
    return await _apiService.fetchUsers(gender: gender);
  }
}
