import 'package:image_picker/image_picker.dart';
import 'camera_gateway.dart';

class CameraGatewayImpl implements CameraGateway {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<MediaResult?> takePhoto() async {
    try {
      final xfile = await _picker.pickImage(source: ImageSource.camera, maxWidth: 1920);
      if (xfile == null) return null;
      return MediaResult(path: xfile.path);
    } catch (e) {
      throw CameraException(CameraError.unknown, '拍照失败: $e');
    }
  }

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<bool> requestPermission() async => true;
}

class MediaPickerImpl implements MediaPickerGateway {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<MediaResult?> pickFromGallery() async {
    try {
      final xfile = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1920);
      if (xfile == null) return null;
      return MediaResult(path: xfile.path);
    } catch (e) {
      throw CameraException(CameraError.unknown, '选择图片失败: $e');
    }
  }

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<bool> requestPermission() async => true;
}
