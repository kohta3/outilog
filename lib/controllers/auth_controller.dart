import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:outi_log/infrastructure/auth_indrastructure.dart';
import 'package:outi_log/infrastructure/user_firestore_infrastructure.dart';
import 'package:outi_log/infrastructure/storage_infrastructure.dart';
import 'package:outi_log/models/user_model.dart';
import 'package:outi_log/repository/login_repo.dart';
import 'package:outi_log/utils/toast.dart';
import 'package:outi_log/view/auth/login_screen.dart';
import 'package:outi_log/view/auth/create_send_email_screen.dart';
import 'package:outi_log/view/home_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outi_log/services/remote_notification_service.dart';

class AuthController {
  final AuthInfrastructure _authInfrastructure;
  final LoginRepo _loginRepo;
  final UserFirestoreInfrastructure _userFirestoreInfrastructure;
  final StorageInfrastructure _storageInfrastructure;
  final RemoteNotificationService _remoteNotificationService;

  AuthController(
    this._authInfrastructure,
    this._loginRepo,
    this._userFirestoreInfrastructure,
    this._storageInfrastructure,
    this._remoteNotificationService,
  );

  /// 新規アカウント作成
  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String username,
    required BuildContext context,
    required Function() setState,
    XFile? profileImage,
  }) async {
    try {
      final userCredential = await _authInfrastructure.signUp(
        email: email,
        password: password,
      );

      // Firebase Authenticationのユーザー情報を更新
      await _authInfrastructure.updateUserInfo(username: username);

      // Firestoreにユーザーテーブルを作成
      if (userCredential.user != null) {
        String? profileImageUrl;

        // プロフィール画像をアップロード
        if (profileImage != null) {
          try {
            profileImageUrl = await _storageInfrastructure.uploadProfileImage(
              userId: userCredential.user!.uid,
              imageFile: profileImage,
            );
          } catch (e) {
            // 画像アップロードに失敗してもアカウント作成は続行
            print('画像アップロードに失敗しました: $e');
          }
        }

        final user = UserModel(
          id: userCredential.user!.uid,
          username: username,
          email: email,
          profileImageUrl: profileImageUrl,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _userFirestoreInfrastructure.createUser(user);

        // FCMトークンをFirestoreに保存
        await _remoteNotificationService
            .saveUserFCMToken(userCredential.user!.uid);
      }

      if (context.mounted) {
        Toast.show(context, 'アカウントを作成しました。認証メールを確認してください。');
      }

      return userCredential;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    } finally {
      if (context.mounted) {
        setState();
      }
    }
  }

  /// ログイン処理
  Future<void> signIn({
    required String email,
    required String password,
    required BuildContext context,
    WidgetRef? ref,
  }) async {
    try {
      await _authInfrastructure.signIn(email: email, password: password);

      final isVerified = await _authInfrastructure.checkEmailVerification();

      if (isVerified && context.mounted) {
        Toast.show(context, 'ログインに成功しました');
        await _loginRepo.setIsFirstLogin();

        // ユーザー情報をキャッシュに保存
        final currentUser = await getCurrentUser();
        if (currentUser != null) {
          await _loginRepo.cacheUserData(currentUser);

          // FCMトークンをFirestoreに保存
          await _remoteNotificationService.saveUserFCMToken(currentUser.id);
        }

        // ホームタブにリダイレクトするためにインデックスをリセット
        if (ref != null) {
          ref.read(homeScreenIndexProvider.notifier).state = 0;
        }

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen()),
          (route) => false,
        );
      } else if (context.mounted) {
        // メール認証が未完了の場合
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('メール認証が完了していません。認証メールを確認してください。'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateSendEmailScreen()),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// メール認証確認
  Future<void> confirmVerification(BuildContext context,
      {WidgetRef? ref}) async {
    try {
      final isVerified = await _authInfrastructure.checkEmailVerification();

      if (isVerified && context.mounted) {
        Toast.show(context, 'メール認証が完了しました');
        await _loginRepo.setIsFirstLogin();

        // ユーザー情報をキャッシュに保存（ログイン時と同じ処理）
        final currentUser = await getCurrentUser();
        if (currentUser != null) {
          await _loginRepo.cacheUserData(currentUser);

          // FCMトークンをFirestoreに保存
          await _remoteNotificationService.saveUserFCMToken(currentUser.id);
        }

        // ホームタブにリダイレクトするためにインデックスをリセット
        if (ref != null) {
          ref.read(homeScreenIndexProvider.notifier).state = 0;
        }

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('認証確認中にエラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// ログアウト
  Future<void> signOut({BuildContext? context}) async {
    try {
      // Firebase認証からログアウト
      await _authInfrastructure.signOut();

      // セキュアストレージの全データを削除
      await _loginRepo.logout();

      if (context != null && context.mounted) {
        // ログイン画面に遷移
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ログアウトに失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
  }

  /// メール認証状態チェック
  Future<bool> checkEmailVerification() async {
    return await _authInfrastructure.checkEmailVerification();
  }

  /// 認証メール再送信
  Future<void> resendEmailVerification() async {
    await _authInfrastructure.resendEmailVerification();
  }

  /// 選択された画像を直接アップロードする
  Future<String?> uploadSelectedProfileImage({
    required String userId,
    required XFile imageFile,
    required BuildContext context,
  }) async {
    try {
      // 画像を検証
      if (!_storageInfrastructure.validateImage(imageFile)) {
        if (context.mounted) {
          Toast.show(context, '画像の形式またはサイズが無効です。');
        }
        return null;
      }

      // 画像をアップロード
      final imageUrl = await _storageInfrastructure.uploadProfileImage(
        userId: userId,
        imageFile: imageFile,
      );

      // Firestoreのユーザー情報を更新
      await _userFirestoreInfrastructure.updateProfileImageUrl(
          userId, imageUrl);

      if (context.mounted) {
        Toast.show(context, 'プロフィール画像を更新しました。');
      }

      return imageUrl;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('画像のアップロードに失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  /// プロフィール画像をアップロードする（画像選択ダイアログ付き）
  Future<String?> uploadProfileImage({
    required String userId,
    required BuildContext context,
  }) async {
    try {
      // 画像選択ダイアログを表示
      final XFile? imageFile = await _showImageSourceDialog(context);

      if (imageFile == null) {
        return null;
      }

      // 画像を検証
      if (!_storageInfrastructure.validateImage(imageFile)) {
        if (context.mounted) {
          Toast.show(context, '画像の形式またはサイズが無効です。');
        }
        return null;
      }

      // 画像をアップロード
      final imageUrl = await _storageInfrastructure.uploadProfileImage(
        userId: userId,
        imageFile: imageFile,
      );

      // Firestoreのユーザー情報を更新
      await _userFirestoreInfrastructure.updateProfileImageUrl(
          userId, imageUrl);

      if (context.mounted) {
        Toast.show(context, 'プロフィール画像を更新しました。');
      }

      return imageUrl;
    } catch (e) {
      if (context.mounted) {
        Toast.show(context, '画像のアップロードに失敗しました: $e');
      }
      return null;
    }
  }

  /// プロフィール画像を削除する
  Future<void> removeProfileImage({
    required String userId,
    required String? currentImageUrl,
    required BuildContext context,
  }) async {
    try {
      // 現在の画像をStorageから削除
      if (currentImageUrl != null && currentImageUrl.isNotEmpty) {
        await _storageInfrastructure.deleteProfileImage(currentImageUrl);
      }

      // Firestoreのユーザー情報から画像URLを削除
      await _userFirestoreInfrastructure.removeProfileImage(userId);

      if (context.mounted) {
        Toast.show(context, 'プロフィール画像を削除しました。');
      }
    } catch (e) {
      if (context.mounted) {
        Toast.show(context, '画像の削除に失敗しました: $e');
      }
    }
  }

  /// 画像選択ソースダイアログを表示
  Future<XFile?> _showImageSourceDialog(BuildContext context) async {
    return showDialog<XFile?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('画像を選択'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('カメラで撮影'),
              onTap: () async {
                final image = await _storageInfrastructure.takePhoto();
                if (context.mounted) {
                  Navigator.pop(context, image);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('ギャラリーから選択'),
              onTap: () async {
                final image = await _storageInfrastructure.selectFromGallery();
                if (context.mounted) {
                  Navigator.pop(context, image);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  /// 現在のユーザー情報を取得する（キャッシュ優先）
  Future<UserModel?> getCurrentUser({bool useCache = true}) async {
    try {
      final user = _authInfrastructure.currentUser;
      if (user != null) {
        // キャッシュから取得を試行
        if (useCache) {
          final cachedUser = await _loginRepo.getCachedUserData();
          if (cachedUser != null) {
            return cachedUser;
          }
        }

        // キャッシュがない場合はFirestoreから取得
        final userData =
            await _userFirestoreInfrastructure.getUserById(user.uid);
        if (userData != null) {
          // 取得したデータをキャッシュに保存
          await _loginRepo.cacheUserData(userData);
        }
        return userData;
      }
      return null;
    } catch (e) {
      throw Exception('ユーザー情報の取得に失敗しました: $e');
    }
  }

  /// キャッシュされたユーザー情報を取得する
  Future<UserModel?> getCachedUser() async {
    return await _loginRepo.getCachedUserData();
  }

  /// メールアドレスを変更する
  Future<bool> changeEmail({
    required String newEmail,
    required String password,
    required BuildContext context,
  }) async {
    try {
      final user = _authInfrastructure.currentUser;
      if (user == null) {
        if (context.mounted) {
          Toast.show(context, 'ユーザーが認証されていません');
        }
        return false;
      }

      // 現在のパスワードで再認証
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // メールアドレスを更新
      await user.verifyBeforeUpdateEmail(newEmail);

      // Firestoreのユーザー情報も更新
      await _userFirestoreInfrastructure.updateEmail(user.uid, newEmail);

      // キャッシュを更新
      final currentUser = await getCurrentUser();
      if (currentUser != null) {
        final updatedUser = currentUser.copyWith(email: newEmail);
        await _loginRepo.cacheUserData(updatedUser);
      }

      if (context.mounted) {
        Toast.show(context, '確認メールを送信しました。新しいメールアドレスを確認してください。');
      }

      return true;
    } catch (e) {
      if (context.mounted) {
        String errorMessage = 'メールアドレスの変更に失敗しました';
        if (e.toString().contains('wrong-password')) {
          errorMessage = 'パスワードが正しくありません';
        } else if (e.toString().contains('email-already-in-use')) {
          errorMessage = 'このメールアドレスは既に使用されています';
        } else if (e.toString().contains('invalid-email')) {
          errorMessage = '無効なメールアドレスです';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  /// パスワードを変更する
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required BuildContext context,
  }) async {
    try {
      final user = _authInfrastructure.currentUser;
      if (user == null) {
        if (context.mounted) {
          Toast.show(context, 'ユーザーが認証されていません');
        }
        return false;
      }

      // 現在のパスワードで再認証
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // パスワードを更新
      await user.updatePassword(newPassword);

      if (context.mounted) {
        Toast.show(context, 'パスワードを変更しました');
      }

      return true;
    } catch (e) {
      if (context.mounted) {
        String errorMessage = 'パスワードの変更に失敗しました';
        if (e.toString().contains('wrong-password')) {
          errorMessage = '現在のパスワードが正しくありません';
        } else if (e.toString().contains('weak-password')) {
          errorMessage = 'パスワードが弱すぎます';
        } else if (e.toString().contains('requires-recent-login')) {
          errorMessage = 'セキュリティのため、再度ログインしてください';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  /// アカウントを削除する
  Future<bool> deleteAccount({
    required BuildContext context,
  }) async {
    try {
      final user = _authInfrastructure.currentUser;
      if (user == null) {
        if (context.mounted) {
          Toast.show(context, 'ユーザーが認証されていません');
        }
        return false;
      }

      final userId = user.uid;

      // Firestoreのユーザーデータを削除
      await _userFirestoreInfrastructure.deleteUser(userId);

      // プロフィール画像を削除
      final currentUser = await getCurrentUser();
      if (currentUser?.profileImageUrl != null) {
        await _storageInfrastructure
            .deleteProfileImage(currentUser!.profileImageUrl!);
      }

      // Firebase Authenticationのアカウントを削除
      await user.delete();

      // セキュアストレージの全データを削除
      await _loginRepo.logout();

      if (context.mounted) {
        Toast.show(context, 'アカウントを削除しました');

        // ログイン画面に遷移
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }

      return true;
    } catch (e) {
      if (context.mounted) {
        String errorMessage = 'アカウント削除に失敗しました';
        if (e.toString().contains('requires-recent-login')) {
          errorMessage = 'セキュリティのため、再度ログインしてください';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$errorMessage: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }
}
