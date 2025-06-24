import 'package:outi_log/constant/message.dart';

class Validate {
  static String? validateEmail(String email) {
    if (email.isEmpty) {
      return emailError;
    }
    bool isVaild = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
    if (!isVaild) {
      return emailFormatError;
    }
    return null;
  }

  static String? validatePassword(String password) {
    if (password.isEmpty) {
      return passwordError;
    }
    bool isVaild = RegExp(
            r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$')
        .hasMatch(password);
    if (!isVaild) {
      return passwordFormatError;
    }
    return null;
  }

  static String? validateUsername(String username) {
    if (username.isEmpty) {
      return 'ユーザー名を入力してください';
    }
    if (username.length < 2) {
      return 'ユーザー名は2文字以上で入力してください';
    }
    if (username.length > 20) {
      return 'ユーザー名は20文字以下で入力してください';
    }
    return null;
  }

  static String? validateConfirmPassword(
      String password, String confirmPassword) {
    if (confirmPassword.isEmpty) {
      return '確認用パスワードを入力してください';
    }
    if (password != confirmPassword) {
      return 'パスワードが一致しません';
    }
    return null;
  }
}
