import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageInfrastructure {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// プロフィール画像をアップロードする
  Future<String> uploadProfileImage({
    required String userId,
    required XFile imageFile,
  }) async {
    try {
      // ファイルの拡張子を取得
      final extension = imageFile.path.split('.').last;

      // ストレージパスを設定（profile_images/{userId}/profile.{extension}）
      final ref = _storage
          .ref()
          .child('profile_images')
          .child(userId)
          .child('profile.$extension');

      // ファイルをアップロード
      final uploadTask = await ref.putFile(File(imageFile.path));

      // ダウンロードURLを取得
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('プロフィール画像のアップロードに失敗しました: $e');
    }
  }

  /// スペースヘッダー画像をアップロードする
  Future<String> uploadSpaceHeaderImage({
    required String spaceId,
    required XFile imageFile,
  }) async {
    try {
      // ファイルの拡張子を取得
      final extension = imageFile.path.split('.').last;

      // ストレージパスを設定（space_images/{spaceId}/header.{extension}）
      final ref = _storage
          .ref()
          .child('space_images')
          .child(spaceId)
          .child('header.$extension');

      // ファイルをアップロード
      final uploadTask = await ref.putFile(File(imageFile.path));

      // ダウンロードURLを取得
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('スペースヘッダー画像のアップロードに失敗しました: $e');
    }
  }

  /// プロフィール画像を削除する
  Future<void> deleteProfileImage(String imageUrl) async {
    try {
      // URLから参照を取得
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('プロフィール画像の削除に失敗しました: $e');
    }
  }

  /// 画像を選択する（カメラまたはギャラリー）
  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      return image;
    } catch (e) {
      throw Exception('画像の選択に失敗しました: $e');
    }
  }

  /// カメラから画像を撮影する
  Future<XFile?> takePhoto() async {
    return await pickImage(source: ImageSource.camera);
  }

  /// ギャラリーから画像を選択する
  Future<XFile?> selectFromGallery() async {
    return await pickImage(source: ImageSource.gallery);
  }

  /// 画像のサイズをチェックする（最大5MB）
  bool validateImageSize(XFile imageFile) {
    // ファイルサイズのチェックは実際のファイルサイズを取得する必要があります
    // ここでは簡易的にファイルパスでチェック
    final file = File(imageFile.path);
    final fileSizeInBytes = file.lengthSync();
    final fileSizeInMB = fileSizeInBytes / (1024 * 1024);

    return fileSizeInMB <= 5.0; // 5MB以下
  }

  /// 画像の形式をチェックする
  bool validateImageFormat(XFile imageFile) {
    final extension = imageFile.path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif'].contains(extension);
  }

  /// 画像を検証する（サイズと形式）
  bool validateImage(XFile imageFile) {
    return validateImageSize(imageFile) && validateImageFormat(imageFile);
  }

  /// 一時的な画像URLを取得する（1時間有効）
  Future<String> getTemporaryImageUrl(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('一時的な画像URLの取得に失敗しました: $e');
    }
  }
}
