import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:outi_log/models/user_model.dart';
import 'package:outi_log/provider/flutter_secure_storage_provider.dart';

class UserFirestoreInfrastructure {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'users';

  /// ユーザーを作成する
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(user.id)
          .set(user.toFirestore());
    } catch (e) {
      throw Exception('ユーザーの作成に失敗しました: $e');
    }
  }

  /// ユーザーIDでユーザーを取得する
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc =
          await _firestore.collection(_collectionName).doc(userId).get();

      if (doc.exists && doc.data() != null) {
        return UserModel.fromFirestore(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('ユーザーの取得に失敗しました: $e');
    }
  }

  /// ユーザーを取得する（getUserByIdのエイリアス）
  Future<UserModel?> getUser(String userId) async {
    return await getUserById(userId);
  }

  /// キャッシュからユーザーを取得する
  Future<UserModel?> getCachedUser(String userId) async {
    try {
      final secureStorage = FlutterSecureStorageController();
      return await secureStorage.getCachedUserData();
    } catch (e) {
      print('Error getting cached user: $e');
      return null;
    }
  }

  /// ユーザー情報を更新する
  Future<void> updateUser(UserModel user) async {
    try {
      final updatedUser = user.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection(_collectionName)
          .doc(user.id)
          .update(updatedUser.toFirestore());
    } catch (e) {
      throw Exception('ユーザーの更新に失敗しました: $e');
    }
  }

  /// ユーザー名を更新する
  Future<void> updateUsername(String userId, String username) async {
    try {
      await _firestore.collection(_collectionName).doc(userId).update({
        'username': username,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('ユーザー名の更新に失敗しました: $e');
    }
  }

  /// メールアドレスを更新する
  Future<void> updateEmail(String userId, String email) async {
    try {
      await _firestore.collection(_collectionName).doc(userId).update({
        'email': email,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('メールアドレスの更新に失敗しました: $e');
    }
  }

  /// ユーザーを削除する
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection(_collectionName).doc(userId).delete();
    } catch (e) {
      throw Exception('ユーザーの削除に失敗しました: $e');
    }
  }

  /// ユーザーが存在するかチェックする
  Future<bool> userExists(String userId) async {
    try {
      final doc =
          await _firestore.collection(_collectionName).doc(userId).get();
      return doc.exists;
    } catch (e) {
      throw Exception('ユーザー存在チェックに失敗しました: $e');
    }
  }

  /// メールアドレスでユーザーを検索する
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return UserModel.fromFirestore(querySnapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      throw Exception('メールアドレスでのユーザー検索に失敗しました: $e');
    }
  }

  /// ユーザー名でユーザーを検索する
  Future<UserModel?> getUserByUsername(String username) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return UserModel.fromFirestore(querySnapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      throw Exception('ユーザー名でのユーザー検索に失敗しました: $e');
    }
  }

  /// プロフィール画像URLを更新する
  Future<void> updateProfileImageUrl(String userId, String imageUrl) async {
    try {
      await _firestore.collection(_collectionName).doc(userId).update({
        'profile_image_url': imageUrl,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('プロフィール画像URLの更新に失敗しました: $e');
    }
  }

  /// プロフィール画像を削除する（URLをnullに設定）
  Future<void> removeProfileImage(String userId) async {
    try {
      await _firestore.collection(_collectionName).doc(userId).update({
        'profile_image_url': FieldValue.delete(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('プロフィール画像の削除に失敗しました: $e');
    }
  }
}
