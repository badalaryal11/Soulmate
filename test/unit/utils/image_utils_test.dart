import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soulmate/core/utils/image_utils.dart';

void main() {
  group('ImageUtils.getImageProvider', () {
    test('returns FileImage for plain local file path', () async {
      final tempFile = File(
        '${Directory.systemTemp.path}/image_utils_local_path_test.txt',
      );
      await tempFile.writeAsString('test');
      addTearDown(() async {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      });

      final provider = ImageUtils.getImageProvider(tempFile.path);

      expect(provider, isA<FileImage>());
    });

    test('returns FileImage for file:// url path', () async {
      final tempFile = File(
        '${Directory.systemTemp.path}/image_utils_file_scheme_test.txt',
      );
      await tempFile.writeAsString('test');
      addTearDown(() async {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      });

      final provider = ImageUtils.getImageProvider(tempFile.uri.toString());

      expect(provider, isA<FileImage>());
    });

    test('returns fallback AssetImage for unsupported path shape', () {
      final provider = ImageUtils.getImageProvider('not-a-valid-image-ref');

      expect(provider, isA<AssetImage>());
    });
  });
}
