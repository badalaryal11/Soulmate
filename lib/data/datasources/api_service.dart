import '../../domain/entities/user.dart' as domain;
import 'dart:developer' as developer;
import '../../core/utils/rate_limiter.dart';
import 'random_user_api_service.dart';

class ApiService {
  Future<List<domain.User>> fetchUsers({
    int results = 20,
    String? gender,
  }) async {
    // Prevent aggressive UI refreshing from hammering the API
    if (!RateLimiter.check('fetch_users_api', const Duration(seconds: 3))) {
      developer.log('Api fetch throttled by RateLimiter');
      return [];
    }

    developer.log('Delegating fetch to RandomUserApiService');
    return await RandomUserApiService.fetchRandomUsers(
      count: results,
      gender: gender,
    );
  }
}
