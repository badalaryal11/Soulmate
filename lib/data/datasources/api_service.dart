import '../../domain/entities/user.dart' as domain;
import 'dart:developer' as developer;
import '../../core/utils/rate_limiter.dart';
import 'reqres_api_service.dart';
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

    developer.log('Delegating fetch to Reqres, DummyJson, and RandomUser');
    
    // Split the fetch count roughly into thirds between the three APIs
    final reqresCount = (results / 3).ceil();
    final dummyJsonCount = (results / 3).ceil();
    final randomUserCount = results - reqresCount - dummyJsonCount;

    final fetchResults = await Future.wait([
      if (reqresCount > 0)
        ReqresApiService.fetchUsers(count: reqresCount, gender: gender)
      else
        Future.value(<domain.User>[]),
      
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
    combinedUsers.addAll(fetchResults[1]);
    if (fetchResults.length > 2) combinedUsers.addAll(fetchResults[2]);
    
    combinedUsers.shuffle();
    
    return combinedUsers;
  }
}
