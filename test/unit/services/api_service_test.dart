import 'package:flutter_test/flutter_test.dart';
import 'package:soulmate/data/datasources/api_service.dart';

void main() {
  late ApiService apiService;

  setUp(() {
    apiService = ApiService();
  });

  test('fetchUsers handles gender filtering with fallback', () async {
    final femaleUsers = await apiService.fetchUsers(gender: 'female');
    expect(femaleUsers.isNotEmpty, true);
    expect(femaleUsers.every((u) => u.gender == 'female'), true);
  });
}
