import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outi_log/constant/color.dart';
import 'package:outi_log/controllers/auth_controller.dart';
import 'package:outi_log/infrastructure/auth_indrastructure.dart';
import 'package:outi_log/provider/flutter_secure_storage_provider.dart';
import 'package:outi_log/repository/login_repo.dart';
import 'package:outi_log/utils/validate.dart';
import 'package:outi_log/view/auth/create_account_screen.dart';
import 'package:outi_log/view/auth/create_send_email_screen.dart';
import 'package:outi_log/view/auth/forgot_password_screen.dart';
import 'package:outi_log/view/component/common.dart';
import 'package:outi_log/view/home_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late final AuthController _authController;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? emailError;
  String? passwordError;
  bool isLoading = false;

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
    super.dispose();
  }

  void _validateFields() {
    setState(() {
      emailError = Validate.validateEmail(_emailController.text);
      passwordError = Validate.validatePassword(_passwordController.text);
    });
  }

  Future<void> _performLogin() async {
    _validateFields();

    if (emailError == null && passwordError == null) {
      setState(() {
        isLoading = true;
      });

      await _authController.signIn(
        email: _emailController.text,
        password: _passwordController.text,
        context: context,
      );

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Image.asset(
                'assets/images/logo.png',
                height: 150,
              ),
              const SizedBox(height: 48.0),
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
              const SizedBox(height: 16.0),
              Row(
                children: [
                  expandedTextField(
                    'パスワード',
                    _passwordController,
                    onChanged: (value) {
                      setState(() {
                        passwordError = Validate.validatePassword(value);
                      });
                    },
                    errorText: passwordError,
                    isPassword: true,
                  ),
                ],
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: isLoading ? null : _performLogin,
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
                        'ログイン',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
              const SizedBox(height: 16.0),
              TextButton(
                onPressed: () {
                  // TODO: パスワードリセット画面へ遷移
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ForgotPasswordScreen()),
                  );
                },
                child: const Text(
                  'パスワードをお忘れですか？',
                  style: TextStyle(color: secondaryTextColor),
                ),
              ),
              const SizedBox(height: 8.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'アカウントをお持ちでないですか？',
                    style: TextStyle(color: secondaryTextColor),
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: 新規登録画面へ遷移
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const CreateAccountScreen()),
                      );
                    },
                    child: const Text(
                      '新規登録',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
