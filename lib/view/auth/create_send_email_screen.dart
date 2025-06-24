import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outi_log/constant/color.dart';
import 'package:outi_log/controllers/auth_controller.dart';
import 'package:outi_log/infrastructure/auth_indrastructure.dart';
import 'package:outi_log/provider/flutter_secure_storage_provider.dart';
import 'package:outi_log/repository/login_repo.dart';

class CreateSendEmailScreen extends ConsumerStatefulWidget {
  const CreateSendEmailScreen({super.key});

  @override
  ConsumerState<CreateSendEmailScreen> createState() =>
      _CreateSendEmailScreenState();
}

class _CreateSendEmailScreenState extends ConsumerState<CreateSendEmailScreen> {
  bool isLoading = false;
  String? infoMessage;
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _authController = AuthController(
      AuthInfrastructure(),
      LoginRepo(ref.read(flutterSecureStorageControllerProvider.notifier)),
    );
  }

  Future<void> _checkVerified() async {
    setState(() {
      isLoading = true;
      infoMessage = null;
    });

    try {
      await _authController.confirmVerification(context);
    } catch (e) {
      setState(() {
        infoMessage = "エラーが発生しました: $e";
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _resendEmail() async {
    setState(() {
      isLoading = true;
      infoMessage = null;
    });

    try {
      await _authController.resendEmailVerification();
      setState(() {
        infoMessage = "認証メールを再送信しました。";
      });
    } catch (e) {
      setState(() {
        infoMessage = "エラーが発生しました: $e";
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('メール認証確認'),
        backgroundColor: themeColor,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.email, size: 64, color: themeColor),
              const SizedBox(height: 24),
              const Text(
                '認証メールを送信しました。\nメール内のリンクをクリックしてください。',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 24),
              if (infoMessage != null)
                Text(
                  infoMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading ? null : _checkVerified,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('認証済みか再チェック'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: isLoading ? null : _resendEmail,
                child: const Text('認証メールを再送信'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
