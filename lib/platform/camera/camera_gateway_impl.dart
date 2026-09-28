import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'camera_gateway.dart';

class CameraGatewayImpl implements CameraGateway {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<MediaResult?> takePhoto() async {
    try {
      final hasPerm = await requestPermission();
      if (!hasPerm) {
        throw CameraException(CameraError.permissionDenied, 'camera permission denied');
      }
      final xfile = await _picker.pickImage(source: ImageSource.camera, maxWidth: 1920);
      if (xfile == null) return null;
      return MediaResult(path: xfile.path);
    } on CameraException {
      rethrow;
    } catch (e) {
      throw CameraException(CameraError.unknown, 'take photo failed: $e');
    }
  }

  @override
  Future<bool> hasPermission() async {
    if (kIsWeb) return true;
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  @override
  Future<bool> requestPermission() async {
    if (kIsWeb) return true;
    if (await hasPermission()) return true;
    final status = await Permission.camera.request();
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return hasPermission();
    }
    return false;
  }
}

class MediaPickerImpl implements MediaPickerGateway {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<MediaResult?> pickFromGallery() async {
    try {
      final hasPerm = await requestPermission();
      if (!hasPerm) {
        throw CameraException(CameraError.permissionDenied, 'gallery permission denied');
      }
      final xfile = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1920);
      if (xfile == null) return null;
      return MediaResult(path: xfile.path);
    } on CameraException {
      rethrow;
    } catch (e) {
      throw CameraException(CameraError.unknown, 'pick image failed: $e');
    }
  }

  @override
  Future<bool> hasPermission() async {
    if (kIsWeb) return true;
    final photos = await Permission.photos.status;
    if (photos.isGranted || photos.isLimited) return true;
    final storage = await Permission.storage.status;
    return storage.isGranted;
  }

  @override
  Future<bool> requestPermission() async {
    if (kIsWeb) return true;
    if (await hasPermission()) return true;
    final status = await Permission.photos.request();
    if (status.isGranted || status.isLimited) return true;
    final storage = await Permission.storage.request();
    if (storage.isGranted) return true;
    if (status.isPermanentlyDenied || storage.isPermanentlyDenied) {
      await openAppSettings();
      return hasPermission();
    }
    return false;
  }
}
