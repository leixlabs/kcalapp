import 'dart:io';

import 'package:calory/data/image/image_processor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late File sourceFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('calory-image-test-');
    sourceFile = File('${tempDir.path}/picked_photo.jpg');
    await sourceFile.writeAsBytes([1, 2, 3, 4]);
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  test(
    'copies picked image into persistent directory with unique names',
    () async {
      final processor = ImageProcessor();
      final targetDir = '${tempDir.path}/meal_photos';

      final first = await processor.copyToDir(
        sourcePath: sourceFile.path,
        targetDir: targetDir,
      );
      final second = await processor.copyToDir(
        sourcePath: sourceFile.path,
        targetDir: targetDir,
      );

      expect(await first.exists(), isTrue);
      expect(await second.exists(), isTrue);
      expect(first.path, isNot(second.path));
      expect(first.path, endsWith('.jpg'));
      expect(await first.readAsBytes(), [1, 2, 3, 4]);
      expect(await sourceFile.exists(), isTrue);
    },
  );

  test('reports when the selected source image no longer exists', () async {
    final processor = ImageProcessor();

    await expectLater(
      processor.copyToDir(
        sourcePath: '${tempDir.path}/missing.jpg',
        targetDir: '${tempDir.path}/meal_photos',
      ),
      throwsA(isA<FileSystemException>()),
    );
  });
}
