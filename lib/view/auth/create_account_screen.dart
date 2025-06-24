import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outi_log/constant/color.dart';
import 'package:outi_log/controllers/auth_controller.dart';
import 'package:outi_log/infrastructure/auth_indrastructure.dart';
import 'package:outi_log/provider/flutter_secure_storage_provider.dart';
import 'package:outi_log/repository/login_repo.dart';
import 'package:outi_log/utils/toast.dart';
import 'package:outi_log/utils/validate.dart';
import 'package:outi_log/view/auth/create_send_email_screen.dart';
import 'package:outi_log/view/component/common.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  ConsumerState<CreateAccountScreen> createState() =>
      _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  late final AuthController _authController;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();

  String? emailError;
  String? passwordError;
  String? confirmPasswordError;
  String? usernameError;

  String selectedGender = '秘密';
  int selectedIconIndex = 0;
  bool isLoading = false;

  final List<String> genderOptions = ['男', '女', '秘密'];
  final List<IconData> iconOptions = [
    Icons.person,
    Icons.face,
    Icons.child_care,
    Icons.emoji_emotions,
    Icons.sentiment_satisfied,
    Icons.sentiment_very_satisfied,
  ];

  @override
  void initState() {
    super.initState();
    _authController = AuthController(
      AuthInfrastructure(),
      LoginRepo(ref.read(flutterSecureStorageControllerProvider.notifier)),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _validateFields() {
    setState(() {
      emailError = Validate.validateEmail(_emailController.text);
      passwordError = Validate.validatePassword(_passwordController.text);
      usernameError = Validate.validateUsername(_usernameController.text);
      confirmPasswordError = Validate.validateConfirmPassword(
          _passwordController.text, _confirmPasswordController.text);
    });
  }

  Future<void> _createAccount() async {
    UserCredential? userCredential;
    _validateFields();

    if (emailError == null &&
        passwordError == null &&
        confirmPasswordError == null &&
        usernameError == null) {
      setState(() {
        isLoading = true;
      });
      userCredential = await _authController.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        username: _usernameController.text,
        context: context,
        setState: () {
          setState(() {
            isLoading = false;
          });
        },
      );

      if (userCredential != null) {
        Toast.show(context, '認証メールを送信しました。');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const CreateSendEmailScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: true,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: backgroundColor,
          title: const Text('アカウント作成'),
        ),
        backgroundColor: backgroundColor,
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // アカウントアイコン選択
              Column(
                children: [
                  const Text(
                    'アカウントアイコン',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: iconOptions.asMap().entries.map((entry) {
                        final index = entry.key;
                        final icon = entry.value;
                        final isSelected = index == selectedIconIndex;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedIconIndex = index;
                            });
                          },
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? themeColor
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: isSelected
                                    ? themeColor
                                    : Colors.grey.shade300,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              icon,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade600,
                              size: 30,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ユーザー名
              Row(
                children: [
                  expandedTextField(
                    'ユーザー名',
                    _usernameController,
                    onChanged: (value) {
                      setState(() {
                        usernameError = Validate.validateUsername(value);
                      });
                    },
                    errorText: usernameError,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 性別選択
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '性別',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedGender,
                        isExpanded: true,
                        items: genderOptions.map((String gender) {
                          return DropdownMenuItem<String>(
                            value: gender,
                            child: Text(gender),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedGender = newValue!;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // メールアドレス
              Row(
                children: [
                  expandedTextField(
                    'メールアドレス',
                    _emailController,
                    onChanged: (value) {
                      setState(() {
                        emailError = Validate.validateEmail(value);
                      });
                    },
                    errorText: emailError,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // パスワード
              Row(
                children: [
                  expandedTextField(
                    'パスワード',
                    _passwordController,
                    onChanged: (value) {
                      setState(() {
                        passwordError = Validate.validatePassword(value);
                        confirmPasswordError = Validate.validateConfirmPassword(
                            value, _confirmPasswordController.text);
                      });
                    },
                    errorText: passwordError,
                    isPassword: true,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 確認用パスワード
              Row(
                children: [
                  expandedTextField(
                    '確認用パスワード',
                    _confirmPasswordController,
                    onChanged: (value) {
                      setState(() {
                        confirmPasswordError = Validate.validateConfirmPassword(
                            _passwordController.text, value);
                      });
                    },
                    errorText: confirmPasswordError,
                    isPassword: true,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // 登録ボタン
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () {
                        // TODO: アカウント作成処理
                        if (emailError == null &&
                            passwordError == null &&
                            confirmPasswordError == null &&
                            usernameError == null) {
                          _createAccount();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'アカウント作成',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),

              const SizedBox(height: 16),

              // ログイン画面へのリンク
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'すでにアカウントをお持ちですか？',
                    style: TextStyle(color: secondaryTextColor),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'ログイン',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
