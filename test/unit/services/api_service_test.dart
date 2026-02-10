import 'package:flutter_test/flutter_test.dart';
import 'package:soulmate/data/services/api_service.dart';

void main() {
  late ApiService apiService;

  setUp(() {
    apiService = ApiService();
  });

  test('fetchUsers returns mock users when API returns empty results', () async {
    // We expect the real API to return empty list currently, triggering fallback
    final users = await apiService.fetchUsers(results: 5);

    expect(users.isNotEmpty, true);
    // Verify fallback data (ID starts with 'mock_')
    expect(users.first.id.startsWith('mock_'), true);
  });

  test('fetchUsers handles gender filtering with fallback', () async {
    final femaleUsers = await apiService.fetchUsers(gender: 'female');
    expect(femaleUsers.isNotEmpty, true);
    expect(femaleUsers.every((u) => u.gender == 'female'), true);
  });

  test(
    'fetchUsers returns unique IDs on subsequent calls (fallback)',
    () async {
      final batch1 = await apiService.fetchUsers(results: 5);
      // Add small delay to ensure timestamp changes if relying on it
      await Future.delayed(const Duration(milliseconds: 10));
      final batch2 = await apiService.fetchUsers(results: 5);

      final ids1 = batch1.map((u) => u.id).toSet();
      final ids2 = batch2.map((u) => u.id).toSet();

      // Check for intersection
      final common = ids1.intersection(ids2);
      expect(
        common.isEmpty,
        true,
        reason: 'IDs should be unique across batches',
      );
    },
  );
}
