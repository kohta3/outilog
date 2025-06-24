import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:outi_log/infrastructure/auth_indrastructure.dart';
import 'package:outi_log/repository/login_repo.dart';
import 'package:outi_log/utils/toast.dart';
import 'package:outi_log/view/auth/create_send_email_screen.dart';
import 'package:outi_log/view/home_screen.dart';

class AuthController {
  final AuthInfrastructure _authInfrastructure;
  final LoginRepo _loginRepo;

  AuthController(this._authInfrastructure, this._loginRepo);

  /// 新規アカウント作成
  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String username,
    required BuildContext context,
    required Function() setState,
  }) async {
    try {
      final userCredential = await _authInfrastructure.signUp(
        email: email,
        password: password,
      );

      await _authInfrastructure.updateUserInfo(username: username);

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
  }) async {
    try {
      await _authInfrastructure.signIn(email: email, password: password);

      final isVerified = await _authInfrastructure.checkEmailVerification();

      if (isVerified && context.mounted) {
        Toast.show(context, 'ログインに成功しました');
        await _loginRepo.setIsFirstLogin();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen()),
          (route) => false,
        );
      } else if (context.mounted) {
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
  Future<void> confirmVerification(BuildContext context) async {
    try {
      final isVerified = await _authInfrastructure.checkEmailVerification();

      if (isVerified && context.mounted) {
        Toast.show(context, 'メール認証が完了しました');
        await _loginRepo.setIsFirstLogin();
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
  Future<void> signOut() async {
    await _authInfrastructure.signOut();
  }

  /// メール認証状態チェック
  Future<bool> checkEmailVerification() async {
    return await _authInfrastructure.checkEmailVerification();
  }

  /// 認証メール再送信
  Future<void> resendEmailVerification() async {
    await _authInfrastructure.resendEmailVerification();
  }
}
