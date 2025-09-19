import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';

class ImageOptimizer {
  /// 画像を圧縮してメモリ使用量を削減
  static Future<Uint8List?> compressImage(
    String imagePath, {
    int quality = 80,
    int maxWidth = 1024,
    int maxHeight = 1024,
  }) async {
    try {
      final result = await FlutterImageCompress.compressWithFile(
        imagePath,
        quality: quality,
        minWidth: 100,
        minHeight: 100,
        format: CompressFormat.jpeg,
      );
      return result;
    } catch (e) {
      debugPrint('画像圧縮エラー: $e');
      return null;
    }
  }

  /// ネットワーク画像の最適化されたウィジェットを作成
  static Widget buildOptimizedNetworkImage(
    String imageUrl, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    bool enableMemoryCache = true,
    int? maxBytes,
  }) {
    return ExtendedImage.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      enableMemoryCache: enableMemoryCache,
      maxBytes: maxBytes ?? 1024 * 1024, // 1MB制限
      loadStateChanged: (ExtendedImageState state) {
        switch (state.extendedImageLoadState) {
          case LoadState.loading:
            return placeholder ??
                Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
          case LoadState.failed:
            return errorWidget ??
                Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey),
                  ),
                );
          case LoadState.completed:
            return null;
        }
      },
      // 古いiOSデバイスでのメモリ制限に対応
      clearMemoryCacheWhenDispose: true,
    );
  }

  /// ファイル画像の最適化されたウィジェットを作成
  static Widget buildOptimizedFileImage(
    File imageFile, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return ExtendedImage.file(
      imageFile,
      width: width,
      height: height,
      fit: fit,
      loadStateChanged: (ExtendedImageState state) {
        switch (state.extendedImageLoadState) {
          case LoadState.loading:
            return placeholder ??
                Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
          case LoadState.failed:
            return errorWidget ??
                Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey),
                  ),
                );
          case LoadState.completed:
            return null;
        }
      },
      enableMemoryCache: false, // ファイル画像はキャッシュ不要
      clearMemoryCacheWhenDispose: true,
    );
  }

  /// 画像ピッカー用の最適化設定
  static const ImagePickerOptions optimizedPickerOptions = ImagePickerOptions(
    maxWidth: 1024,
    maxHeight: 1024,
    imageQuality: 80,
  );

  /// プロフィール画像用の最適化設定
  static const ImagePickerOptions profileImageOptions = ImagePickerOptions(
    maxWidth: 512.0,
    maxHeight: 512.0,
    imageQuality: 85,
  );

  /// ヘッダー画像用の最適化設定
  static const ImagePickerOptions headerImageOptions = ImagePickerOptions(
    maxWidth: 1920.0,
    maxHeight: 1080.0,
    imageQuality: 75,
  );

  /// スクリーンショット用の最適化設定
  static const ImagePickerOptions screenshotOptions = ImagePickerOptions(
    maxWidth: 1920.0,
    maxHeight: 1080.0,
    imageQuality: 85,
  );
}

/// 画像ピッカー用の設定クラス
class ImagePickerOptions {
  final double maxWidth;
  final double maxHeight;
  final int imageQuality;

  const ImagePickerOptions({
    required this.maxWidth,
    required this.maxHeight,
    required this.imageQuality,
  });
}
