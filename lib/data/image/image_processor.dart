import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageProcessor {
  Future<File> processImage({
    required String sourcePath,
    int maxWidth = 1024,
    int maxHeight = 1024,
    int quality = 85,
  }) async {
    final sourceFile = File(sourcePath);
    final bytes = await sourceFile.readAsBytes();
    final decoded = img.decodeImage(bytes);

    if (decoded == null) {
      throw Exception('无法解码图片');
    }

    var processed = img.bakeOrientation(decoded);

    if (processed.width > maxWidth || processed.height > maxHeight) {
      processed = img.copyResize(
        processed,
        width: maxWidth,
        height: maxHeight,
        maintainAspect: true,
      );
    }

    final result = img.encodeJpg(processed, quality: quality);
    final tempDir = Directory.systemTemp;
    final outputFile = File(
      '${tempDir.path}/processed_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await outputFile.writeAsBytes(result);
    return outputFile;
  }

  Future<void> deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<bool> fileExists(String path) async {
    return File(path).exists();
  }

  Future<File> copyToDir({
    required String sourcePath,
    required String targetDir,
  }) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw FileSystemException('源图片不存在', sourcePath);
    }

    final dir = Directory(targetDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final randomSuffix = Random.secure().nextInt(1 << 32).toRadixString(16);
    final fileName =
        '${DateTime.now().microsecondsSinceEpoch}_$randomSuffix${p.extension(sourcePath)}';
    return sourceFile.copy(p.join(dir.path, fileName));
  }

  Future<File> saveMealPhoto(String sourcePath) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    return copyToDir(
      sourcePath: sourcePath,
      targetDir: p.join(documentsDir.path, 'meal_photos'),
    );
  }
}
