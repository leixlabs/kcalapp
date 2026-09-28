abstract interface class CameraGateway {
  Future<MediaResult?> takePhoto();
  Future<bool> hasPermission();
  Future<bool> requestPermission();
}

abstract interface class MediaPickerGateway {
  Future<MediaResult?> pickFromGallery();
  Future<bool> hasPermission();
  Future<bool> requestPermission();
}

class MediaResult {
  final String path;
  final int? width;
  final int? height;

  MediaResult({required this.path, this.width, this.height});
}

enum CameraError { permissionDenied, notAvailable, userCancelled, unknown }

class CameraException implements Exception {
  final CameraError error;
  final String message;
  CameraException(this.error, this.message);
  @override
  String toString() => message;
}
