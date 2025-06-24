import 'package:firebase_auth/firebase_auth.dart';
import 'package:outi_log/services/auth_service.dart';

class AuthInfrastructure {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 現在のユーザーを取得
  User? get currentUser => _auth.currentUser;

  // 認証状態の変更を監視
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 新規登録
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 認証メール送信
      await userCredential.user?.sendEmailVerification();

      return userCredential;
    } catch (e) {
      throw AuthService().handleAuthError(e);
    }
  }

  // ユーザー情報の更新
  Future<void> updateUserInfo({
    required String username,
  }) async {
    await _auth.currentUser?.updateDisplayName(username);
  }

  // ログイン
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw AuthService().handleAuthError(e);
    }
  }

  // ログアウト
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // パスワードリセット
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw AuthService().handleAuthError(e);
    }
  }

  // メール認証状態をチェック
  Future<bool> checkEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      // reload後にユーザーオブジェクトを再取得
      final updatedUser = _auth.currentUser;
      return updatedUser?.emailVerified == true;
    }
    return false;
  }

  // 認証メールを再送信
  Future<void> resendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      await user?.sendEmailVerification();
    } catch (e) {
      throw AuthService().handleAuthError(e);
    }
  }
}
