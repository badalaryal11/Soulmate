// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:soulmate/data/datasources/api_service.dart';

void main() {
  test('Manual API Check', () async {
    final apiService = ApiService();
    print('Fetching users...');

    try {
      final users = await apiService.fetchUsers(results: 100);
      print('Total users fetched: ${users.length}');

      int randomUsers = 0;
      int dummyJsonUsers = 0;

      final Set<String> ids = {};
      final Set<String> imageUrls = {};
      int duplicateIds = 0;
      int duplicateImageUrls = 0;

      final Set<String> generatedUrls = {};
      int duplicateGeneratedUrls = 0;

      for (var user in users) {
        if (!ids.add(user.id)) duplicateIds++;
        if (!imageUrls.add(user.imageUrl)) duplicateImageUrls++;

        // Simulate ImageGenerationService logic
        final List<String> keywords = [];
        keywords.add(user.gender.toLowerCase());
        keywords.add('portrait');
        if (user.interests.isNotEmpty) {
          keywords.add(user.interests.first.toLowerCase());
        }
        final String keywordString = keywords.join(',');
        final int lock = user.id.hashCode.abs() % 10000;
        final String genUrl =
            'https://loremflickr.com/350/525/$keywordString?lock=$lock';

        if (!generatedUrls.add(genUrl)) {
          duplicateGeneratedUrls++;
          // print('Duplicate Gen URL: $genUrl (ID: ${user.id}, Lock: $lock)');
        }

        if (int.tryParse(user.id) != null) {
          dummyJsonUsers++;
        } else {
          randomUsers++;
        }
      }

      print('Estimated DummyJSON users: $dummyJsonUsers');
      print('Estimated RandomUser users: $randomUsers');
      print('Duplicate IDs: $duplicateIds');
      print('Duplicate Image URLs from API source: $duplicateImageUrls');
      print(
        'Duplicate Generated URLs (if using Service): $duplicateGeneratedUrls',
      );
    } catch (e) {
      print('Error: $e');
    }
  });
}
