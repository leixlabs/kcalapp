import 'dart:io';
import 'package:image/image.dart' as img;

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
    final outputFile = File('${tempDir.path}/processed_${DateTime.now().millisecondsSinceEpoch}.jpg');
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
    final dir = Directory(targetDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${sourcePath.split('/').last}';
    final targetPath = '${dir.path}/$fileName';
    await File(sourcePath).copy(targetPath);
    return File(targetPath);
  }
}
