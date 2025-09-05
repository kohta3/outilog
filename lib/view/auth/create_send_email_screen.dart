import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outi_log/constant/color.dart';
import 'package:outi_log/controllers/auth_controller.dart';
import 'package:outi_log/infrastructure/auth_indrastructure.dart';
import 'package:outi_log/infrastructure/user_firestore_infrastructure.dart';
import 'package:outi_log/infrastructure/storage_infrastructure.dart';
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
      UserFirestoreInfrastructure(),
      StorageInfrastructure(),
    );
  }

  Future<void> _checkVerified() async {
    setState(() {
      isLoading = true;
      infoMessage = null;
    });

    try {
      await _authController.confirmVerification(context, ref: ref);
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
        title: const Text('メール認証が必要です'),
        backgroundColor: themeColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),

            // メインアイコンとメッセージ
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.email_outlined,
                    size: 80,
                    color: Colors.orange.shade600,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'メール認証が完了していません',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'セキュリティのため、メール認証が必要です。\n登録したメールアドレスに送信された認証メール内のリンクをクリックしてください。',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ステップガイド
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '認証手順',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStepItem(1, 'メールボックスを確認'),
                  _buildStepItem(2, '「おうちログ」からのメールを探す'),
                  _buildStepItem(3, 'メール内のリンクをクリック'),
                  _buildStepItem(4, '認証完了後、この画面で「認証確認」をタップ'),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // メッセージ表示
            if (infoMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: infoMessage!.contains('エラー')
                      ? Colors.red.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: infoMessage!.contains('エラー')
                        ? Colors.red.shade200
                        : Colors.green.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      infoMessage!.contains('エラー')
                          ? Icons.error_outline
                          : Icons.check_circle_outline,
                      color: infoMessage!.contains('エラー')
                          ? Colors.red.shade600
                          : Colors.green.shade600,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        infoMessage!,
                        style: TextStyle(
                          color: infoMessage!.contains('エラー')
                              ? Colors.red.shade700
                              : Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (infoMessage != null) const SizedBox(height: 24),

            // アクションボタン
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _checkVerified,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                '認証確認',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: isLoading ? null : _resendEmail,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: themeColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.refresh, color: themeColor),
                        SizedBox(width: 8),
                        Text(
                          '認証メールを再送信',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: themeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem(int stepNumber, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: themeColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                stepNumber.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
