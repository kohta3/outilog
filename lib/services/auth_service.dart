import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // エラーハンドリング
  String handleAuthError(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'ユーザーが見つかりません';
        case 'wrong-password':
          return 'パスワードが間違っています';
        case 'email-already-in-use':
          return 'このメールアドレスは既に使用されています';
        case 'weak-password':
          return 'パスワードが弱すぎます';
        case 'invalid-email':
          return '無効なメールアドレスです';
        case 'user-disabled':
          return 'このアカウントは無効になっています';
        case 'too-many-requests':
          return '試行回数が多すぎます。しばらく待ってから再試行してください';
        default:
          return '認証エラーが発生しました: ${e.message}';
      }
    }
    return '予期しないエラーが発生しました';
  }
}
