import 'dart:io';
import 'dart:typed_data';

/// 食物照片与系统相册之间的存取能力。
///
/// 采用「以相册为主」的策略：拍照 / 选图后自动把照片保存进系统相册的专属相册，
/// 数据库只保存相册资源 id，不再在应用沙盒内保留副本。
/// 这样即使应用被卸载重装，照片本身仍保留在系统相册中。
abstract interface class PhotoLibraryGateway {
  /// 请求相册「读写」权限；已授权时返回 `true`。
  Future<bool> ensurePermission();

  /// 把 [sourcePath] 自动保存进专属相册，返回相册资源 id；失败返回 `null`。
  Future<String?> saveToAlbum(String sourcePath);

  /// 解析相册资源对应的本地文件；资源不存在或不可导出时返回 `null`。
  Future<File?> fileForAsset(String assetId);

  /// 解析相册资源的缩略图字节；失败时返回 `null`。
  Future<Uint8List?> thumbnailForAsset(String assetId, {int size = 400});
}
