import '../../domain/entities/user.dart' as domain;
import 'dart:developer' as developer;
import '../../core/utils/rate_limiter.dart';
import 'dummy_json_api_service.dart';
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

    developer.log('Delegating fetch to DummyJson and RandomUser');
    
    // Split the fetch count into half between DummyJson and RandomUser
    final dummyJsonCount = (results / 2).ceil();
    final randomUserCount = results - dummyJsonCount;

    final fetchResults = await Future.wait([
      if (dummyJsonCount > 0)
        DummyJsonApiService.fetchDummyUsers(count: dummyJsonCount, gender: gender)
      else
        Future.value(<domain.User>[]),

      if (randomUserCount > 0)
        RandomUserApiService.fetchRandomUsers(count: randomUserCount, gender: gender)
      else
        Future.value(<domain.User>[]),
    ]);

    final List<domain.User> combinedUsers = [];
    combinedUsers.addAll(fetchResults[0]);
    if (fetchResults.length > 1) combinedUsers.addAll(fetchResults[1]);
    
    combinedUsers.shuffle();
    
    return combinedUsers;
  }
}
