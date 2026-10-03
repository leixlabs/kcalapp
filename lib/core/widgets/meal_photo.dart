import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

/// 食物照片的统一展示组件。
///
/// 优先展示系统相册资源 [assetId]（可跨 App 重装保留），
/// 旧记录回退到沙盒内的 [path]；两者都不可用时展示 [placeholder]。
class MealPhoto extends StatelessWidget {
  final String? assetId;
  final String? path;

  /// 请求的缩略图最长边像素；分享卡片导出时会放大，需给足分辨率。
  final int thumbSize;
  final BoxFit fit;
  final Widget placeholder;

  const MealPhoto({
    super.key,
    this.assetId,
    this.path,
    this.thumbSize = 400,
    this.fit = BoxFit.cover,
    this.placeholder = const SizedBox.shrink(),
  });

  @override
  Widget build(BuildContext context) {
    final provider = MealPhotoProvider.maybe(
      assetId: assetId,
      path: path,
      thumbSize: thumbSize,
    );
    if (provider == null) return placeholder;
    return Image(
      image: provider,
      fit: fit,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}

/// 从「相册资源 id」或「沙盒文件路径」加载图片的 [ImageProvider]。
///
/// 走 Flutter 图片缓存，因此可以在导出分享卡片前用 `precacheImage` 预热，
/// 避免 `RepaintBoundary.toImage` 捕获到尚未加载完成的白图。
class MealPhotoProvider extends ImageProvider<MealPhotoProvider> {
  final String? assetId;
  final String? path;
  final int thumbSize;

  const MealPhotoProvider({this.assetId, this.path, this.thumbSize = 400});

  /// 两个来源都为空时返回 `null`，便于调用方决定展示占位图。
  static MealPhotoProvider? maybe({
    String? assetId,
    String? path,
    int thumbSize = 400,
  }) {
    final hasAsset = assetId != null && assetId.isNotEmpty;
    final hasPath = path != null && path.isNotEmpty;
    if (!hasAsset && !hasPath) return null;
    return MealPhotoProvider(
      assetId: hasAsset ? assetId : null,
      path: hasPath ? path : null,
      thumbSize: thumbSize,
    );
  }

  @override
  Future<MealPhotoProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<MealPhotoProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    MealPhotoProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _decode(key, decode),
      scale: 1.0,
      debugLabel: 'MealPhotoProvider(${key.assetId ?? key.path})',
    );
  }

  /// 检查资源是否可读取且能解码成图片，供周回顾筛选拼图候选照片。
  Future<bool> isReadable() async {
    try {
      final bytes = await _loadBytes(this);
      if (bytes == null || bytes.isEmpty) return false;
      final codec = await ui.instantiateImageCodec(bytes);
      codec.dispose();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<ui.Codec> _decode(
    MealPhotoProvider key,
    ImageDecoderCallback decode,
  ) async {
    final bytes = await _loadBytes(key);
    if (bytes == null || bytes.isEmpty) {
      throw StateError('无法加载食物照片');
    }
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    return decode(buffer);
  }

  static Future<Uint8List?> _loadBytes(MealPhotoProvider key) async {
    final assetId = key.assetId;
    if (assetId != null && assetId.isNotEmpty) {
      try {
        final entity = await AssetEntity.fromId(assetId);
        final bytes = await entity?.thumbnailDataWithSize(
          ThumbnailSize.square(key.thumbSize),
        );
        if (bytes != null && bytes.isNotEmpty) return bytes;
      } catch (_) {
        // 资源被删除或无法导出时，回退到沙盒路径。
      }
    }
    final path = key.path;
    if (path != null && path.isNotEmpty) {
      try {
        final file = File(path);
        if (await file.exists()) return await file.readAsBytes();
      } catch (_) {
        // 忽略，交由上层展示占位图。
      }
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is MealPhotoProvider &&
      other.assetId == assetId &&
      other.path == path &&
      other.thumbSize == thumbSize;

  @override
  int get hashCode => Object.hash(assetId, path, thumbSize);
}
