import 'dart:io';
import 'dart:typed_data';

import 'package:photo_manager/photo_manager.dart';

import 'photo_library_gateway.dart';

/// 基于 `photo_manager` 的实现：照片保存进系统相册的「食刻」相册。
class PhotoLibraryGatewayImpl implements PhotoLibraryGateway {
  /// 专属相册名；用户在系统相册里能直接找到。
  static const albumName = '食刻';

  bool get _isDarwin => Platform.isIOS || Platform.isMacOS;

  @override
  Future<bool> ensurePermission() async {
    try {
      final state = await PhotoManager.requestPermissionExtend();
      // limited（仅授权部分照片）也允许写入并访问本应用创建的资源。
      return state.hasAccess;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String?> saveToAlbum(String sourcePath) async {
    try {
      if (!await ensurePermission()) return null;
      final entity = await PhotoManager.editor.saveImageWithPath(
        sourcePath,
        // Android：直接写进相册目录（MediaStore RELATIVE_PATH）。
        // iOS/macOS：忽略该参数，随后通过 copyAssetToPath 加入相册。
        relativePath: _isDarwin ? null : 'Pictures/$albumName',
      );
      if (_isDarwin) {
        // 加入专属相册是「锦上添花」，失败也不能丢掉已保存的资源 id。
        try {
          final album = await _album();
          if (album != null) {
            await PhotoManager.editor.copyAssetToPath(
              asset: entity,
              pathEntity: album,
            );
          }
        } catch (_) {
          // 照片已在系统相册中，只是未归入专属相册。
        }
      }
      return entity.id;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<File?> fileForAsset(String assetId) async {
    try {
      final entity = await AssetEntity.fromId(assetId);
      if (entity == null) return null;
      return await entity.file;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Uint8List?> thumbnailForAsset(String assetId, {int size = 400}) async {
    try {
      final entity = await AssetEntity.fromId(assetId);
      if (entity == null) return null;
      return await entity.thumbnailDataWithSize(ThumbnailSize.square(size));
    } catch (_) {
      return null;
    }
  }

  Future<AssetPathEntity?> _album() async {
    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      hasAll: false,
    );
    for (final path in paths) {
      if (path.name == albumName) return path;
    }
    return PhotoManager.editor.darwin.createAlbum(albumName);
  }
}
