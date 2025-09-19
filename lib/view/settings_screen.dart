import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outi_log/constant/color.dart';
import 'package:outi_log/controllers/auth_controller.dart';
import 'package:outi_log/infrastructure/auth_indrastructure.dart';
import 'package:outi_log/infrastructure/user_firestore_infrastructure.dart';
import 'package:outi_log/infrastructure/storage_infrastructure.dart';
import 'package:outi_log/models/user_model.dart';
import 'package:outi_log/provider/flutter_secure_storage_provider.dart';
import 'package:outi_log/provider/space_prodiver.dart';
import 'package:outi_log/provider/notification_service_provider.dart';
import 'package:outi_log/repository/login_repo.dart';
import 'package:outi_log/services/remote_notification_service.dart';
import 'package:outi_log/view/privacy_policy_screen.dart';
import 'package:outi_log/view/terms_of_service_screen.dart';
import 'package:outi_log/view/help_support_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:outi_log/utils/image_optimizer.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isEmailVerified = true;
  bool _isCheckingEmail = false;

  @override
  void initState() {
    super.initState();
    _checkEmailVerification();
  }

  Future<void> _checkEmailVerification() async {
    setState(() {
      _isCheckingEmail = true;
    });

    try {
      final authController = AuthController(
        AuthInfrastructure(),
        LoginRepo(ref.read(flutterSecureStorageControllerProvider.notifier)),
        UserFirestoreInfrastructure(),
        StorageInfrastructure(),
        RemoteNotificationService(),
      );

      _isEmailVerified = await authController.checkEmailVerification();
    } catch (e) {
      // エラーが発生した場合は認証済みとして扱う
      _isEmailVerified = true;
    }

    setState(() {
      _isCheckingEmail = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final canCreateSpace = ref.watch(spacesProvider.notifier).canCreateSpace;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          '設定',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: themeColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          // アカウント設定セクション（最優先）
          const _SettingsSection(title: 'アカウント設定'),

          // メール認証状態
          if (!_isEmailVerified) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.shade600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'メール認証が未完了です',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'セキュリティのため、メール認証を完了することをお勧めします',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed:
                        _isCheckingEmail ? null : _resendEmailVerification,
                    child: _isCheckingEmail
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('認証メール再送'),
                  ),
                ],
              ),
            ),
          ],

          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('プロフィール編集'),
            subtitle: const Text('名前やプロフィール画像を変更'),
            onTap: () {
              _showProfileEditDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('メールアドレス変更'),
            subtitle: const Text('登録メールアドレスを変更'),
            onTap: () {
              _showEmailChangeDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('パスワード変更'),
            subtitle: const Text('ログインパスワードを変更'),
            onTap: () {
              _showPasswordChangeDialog(context);
            },
          ),
          if (!canCreateSpace) ...[
            ListTile(
              leading: const Icon(Icons.lock, color: Colors.orange),
              title: const Text('スペース作成上限'),
              subtitle: const Text('無料版は2つまで'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                _showUpgradeDialog(context);
              },
            ),
          ],
          const Divider(),

          // 通知設定セクション
          const _SettingsSection(title: '通知設定'),
          Consumer(
            builder: (context, ref, child) {
              final notificationSettings =
                  ref.watch(notificationSettingsProvider);

              return Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.schedule),
                    title: const Text('スケジュール通知'),
                    subtitle: const Text('予定の通知を受け取る'),
                    trailing: Switch(
                      value:
                          notificationSettings['scheduleNotifications'] ?? true,
                      onChanged: (value) async {
                        await ref
                            .read(notificationSettingsProvider.notifier)
                            .toggleScheduleNotifications(value);
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.account_balance_wallet),
                    title: const Text('家計簿通知'),
                    subtitle: const Text('家計簿の更新通知を受け取る'),
                    trailing: Switch(
                      value: notificationSettings[
                              'householdBudgetNotifications'] ??
                          true,
                      onChanged: (value) async {
                        await ref
                            .read(notificationSettingsProvider.notifier)
                            .toggleHouseholdBudgetNotifications(value);
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.shopping_cart),
                    title: const Text('買い物リスト通知'),
                    subtitle: const Text('買い物リストの更新通知を受け取る'),
                    trailing: Switch(
                      value:
                          notificationSettings['shoppingListNotifications'] ??
                              true,
                      onChanged: (value) async {
                        await ref
                            .read(notificationSettingsProvider.notifier)
                            .toggleShoppingListNotifications(value);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          const Divider(),

          // プライバシー・セキュリティセクション
          const _SettingsSection(title: 'プライバシー・セキュリティ'),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('プライバシーポリシー'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('利用規約'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TermsOfServiceScreen(),
                ),
              );
            },
          ),
          const Divider(),

          // ヘルプ・サポートセクション
          const _SettingsSection(title: 'ヘルプ・サポート'),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('ヘルプ・サポート'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpSupportScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('アプリについて'),
            subtitle: const Text('バージョン 1.0.0'),
            onTap: () {
              _showAppInfoDialog(context);
            },
          ),
          const Divider(),

          // 危険な操作セクション
          const _SettingsSection(title: 'アカウント管理'),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('アカウントを削除'),
            subtitle: const Text('アカウントとすべてのデータを削除'),
            onTap: () {
              _showDeleteAccountDialog(context, ref);
            },
          ),
          const Divider(),

          // ログアウト（最後に配置、危険な操作のため）
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('ログアウト'),
            onTap: () {
              _showLogoutDialog(context, ref);
            },
          ),
        ],
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('プレミアムにアップグレード'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('プレミアムプランにアップグレードすると:'),
            SizedBox(height: 8),
            Text('• 無制限のスペース作成'),
            Text('• 高度な分析機能'),
            Text('• 優先サポート'),
            Text('• 広告なし'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: 課金処理を実装
              Navigator.pop(context);
            },
            child: const Text('アップグレード'),
          ),
        ],
      ),
    );
  }

  void _showAppInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('アプリについて'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'OutiLog',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: themeColor,
              ),
            ),
            SizedBox(height: 8),
            Text('バージョン: 1.0.0'),
            Text('リリース日: 2024年1月1日'),
            SizedBox(height: 16),
            Text(
              '家族やルームメイトと共有する生活管理アプリです。\n'
              'スケジュール、家計簿、買い物リストを一緒に管理できます。',
              style: TextStyle(height: 1.5),
            ),
            SizedBox(height: 16),
            Text(
              '© 2024 OutiLog開発チーム\n'
              'All rights reserved.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _showProfileEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ProfileEditDialog(),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ログアウト'),
        content: const Text('ログアウトしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performLogout(context, ref);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('ログアウト'),
          ),
        ],
      ),
    );
  }

  Future<void> _resendEmailVerification() async {
    setState(() {
      _isCheckingEmail = true;
    });

    try {
      final authController = AuthController(
        AuthInfrastructure(),
        LoginRepo(ref.read(flutterSecureStorageControllerProvider.notifier)),
        UserFirestoreInfrastructure(),
        StorageInfrastructure(),
        RemoteNotificationService(),
      );

      await authController.resendEmailVerification();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('認証メールを再送信しました。メールボックスを確認してください。'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('認証メールの再送信に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isCheckingEmail = false;
    });
  }

  Future<void> _performLogout(BuildContext context, WidgetRef ref) async {
    try {
      final authController = AuthController(
        AuthInfrastructure(),
        LoginRepo(ref.read(flutterSecureStorageControllerProvider.notifier)),
        UserFirestoreInfrastructure(),
        StorageInfrastructure(),
        RemoteNotificationService(),
      );

      await authController.signOut(context: context);
    } catch (e) {
      // エラーハンドリングはAuthController内で行われる
    }
  }

  /// メールアドレス変更ダイアログを表示
  void _showEmailChangeDialog(BuildContext context) {
    final newEmailController = TextEditingController();
    final passwordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('メールアドレス変更'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: newEmailController,
                decoration: const InputDecoration(
                  labelText: '新しいメールアドレス',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: '現在のパスワード',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final newEmail = newEmailController.text.trim();
                      final password = passwordController.text.trim();

                      if (newEmail.isEmpty || password.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('すべての項目を入力してください'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setState(() {
                        isLoading = true;
                      });

                      final authController = AuthController(
                        AuthInfrastructure(),
                        LoginRepo(ref.read(
                            flutterSecureStorageControllerProvider.notifier)),
                        UserFirestoreInfrastructure(),
                        StorageInfrastructure(),
                        RemoteNotificationService(),
                      );

                      final success = await authController.changeEmail(
                        newEmail: newEmail,
                        password: password,
                        context: context,
                      );

                      setState(() {
                        isLoading = false;
                      });

                      if (success && context.mounted) {
                        Navigator.pop(context);
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('変更'),
            ),
          ],
        ),
      ),
    );
  }

  /// パスワード変更ダイアログを表示
  void _showPasswordChangeDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('パスワード変更'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                decoration: const InputDecoration(
                  labelText: '現在のパスワード',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                decoration: const InputDecoration(
                  labelText: '新しいパスワード',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: '新しいパスワード（確認）',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final currentPassword =
                          currentPasswordController.text.trim();
                      final newPassword = newPasswordController.text.trim();
                      final confirmPassword =
                          confirmPasswordController.text.trim();

                      if (currentPassword.isEmpty ||
                          newPassword.isEmpty ||
                          confirmPassword.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('すべての項目を入力してください'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      if (newPassword != confirmPassword) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('新しいパスワードが一致しません'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setState(() {
                        isLoading = true;
                      });

                      final authController = AuthController(
                        AuthInfrastructure(),
                        LoginRepo(ref.read(
                            flutterSecureStorageControllerProvider.notifier)),
                        UserFirestoreInfrastructure(),
                        StorageInfrastructure(),
                        RemoteNotificationService(),
                      );

                      final success = await authController.changePassword(
                        currentPassword: currentPassword,
                        newPassword: newPassword,
                        context: context,
                      );

                      setState(() {
                        isLoading = false;
                      });

                      if (success && context.mounted) {
                        Navigator.pop(context);
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('変更'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('アカウントを削除'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('⚠️ この操作は取り消せません！'),
            SizedBox(height: 16),
            Text('削除されるデータ:'),
            Text('• アカウント情報'),
            Text('• スケジュールデータ'),
            Text('• 買い物リスト'),
            Text('• 家計簿データ'),
            Text('• 共有スペースの情報'),
            Text('• プロフィール画像'),
            SizedBox(height: 16),
            Text('本当にアカウントを削除しますか？'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showDeleteAccountConfirmationDialog(context, ref);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('削除する'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountConfirmationDialog(
      BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('最終確認'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('「アカウントを削除」と入力してください'),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'アカウントを削除',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount(context, ref);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('削除実行'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    try {
      final authController = AuthController(
        AuthInfrastructure(),
        LoginRepo(ref.read(flutterSecureStorageControllerProvider.notifier)),
        UserFirestoreInfrastructure(),
        StorageInfrastructure(),
        RemoteNotificationService(),
      );

      await authController.deleteAccount(context: context);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('アカウントを削除しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('アカウント削除に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class ProfileEditDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends ConsumerState<ProfileEditDialog> {
  late final AuthController _authController;
  UserModel? _currentUser;
  bool _isLoading = false;
  final TextEditingController _usernameController = TextEditingController();
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  // 初期値を保存するための変数
  String _initialUsername = '';

  @override
  void initState() {
    super.initState();
    _authController = AuthController(
      AuthInfrastructure(),
      LoginRepo(ref.read(flutterSecureStorageControllerProvider.notifier)),
      UserFirestoreInfrastructure(),
      StorageInfrastructure(),
      RemoteNotificationService(),
    );
    _loadUserData();

    // ユーザー名の変更を監視
    _usernameController.addListener(() {
      setState(() {}); // 保存ボタンの状態を更新
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  // 変更があるかどうかをチェック
  bool _hasChanges() {
    if (_currentUser == null) return false;

    // ユーザー名の変更チェック
    final currentUsername = _usernameController.text.trim();
    if (currentUsername != _initialUsername) return true;

    // 画像の変更チェック
    if (_selectedImage != null) return true;

    return false;
  }

  Future<void> _selectImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('カメラで撮影'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('ギャラリーから選択'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImage(ImageSource.gallery);
                },
              ),
              if (_selectedImage != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title:
                      const Text('画像を削除', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedImage = null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: ImageOptimizer.profileImageOptions.maxWidth,
        maxHeight: ImageOptimizer.profileImageOptions.maxHeight,
        imageQuality: ImageOptimizer.profileImageOptions.imageQuality,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('画像の選択に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // まずキャッシュから取得を試行
      _currentUser = await _authController.getCachedUser();

      // キャッシュがない場合のみFirestoreから取得
      if (_currentUser == null) {
        _currentUser = await _authController.getCurrentUser(useCache: false);
      }

      if (_currentUser != null) {
        _usernameController.text = _currentUser!.username;
        // 初期値を保存
        _initialUsername = _currentUser!.username;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ユーザー情報の取得に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _updateProfileImage() async {
    if (_currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newImageUrl = await _authController.uploadProfileImage(
        userId: _currentUser!.id,
        context: context,
      );

      if (newImageUrl != null) {
        setState(() {
          _currentUser = _currentUser!.copyWith(profileImageUrl: newImageUrl);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('画像の更新に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _removeProfileImage() async {
    if (_currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _authController.removeProfileImage(
        userId: _currentUser!.id,
        currentImageUrl: _currentUser!.profileImageUrl,
        context: context,
      );

      setState(() {
        _currentUser = _currentUser!.copyWith(profileImageUrl: null);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('画像の削除に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _updateUsername() async {
    if (_currentUser == null) return;

    final newUsername = _usernameController.text.trim();
    if (newUsername.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ユーザー名を入力してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // ユーザー名を更新
      final userFirestoreInfrastructure = UserFirestoreInfrastructure();
      await userFirestoreInfrastructure.updateUsername(
        _currentUser!.id,
        newUsername,
      );

      // 選択された画像がある場合はアップロード
      String? newImageUrl;
      if (_selectedImage != null) {
        newImageUrl = await _authController.uploadSelectedProfileImage(
          userId: _currentUser!.id,
          imageFile: XFile(_selectedImage!.path),
          context: context,
        );
      }

      final updatedUser = _currentUser!.copyWith(
        username: newUsername,
        profileImageUrl: newImageUrl ?? _currentUser!.profileImageUrl,
      );
      setState(() {
        _currentUser = updatedUser;
        _selectedImage = null; // アップロード後は選択状態をリセット
      });

      // キャッシュも更新
      final loginRepo =
          LoginRepo(ref.read(flutterSecureStorageControllerProvider.notifier));
      await loginRepo.cacheUserData(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('プロフィールを更新しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ユーザー名の更新に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('プロフィール編集'),
      content: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentUser == null
              ? const Text('ユーザー情報を読み込み中...')
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // プロフィール画像
                      Stack(
                        children: [
                          GestureDetector(
                            onTap: _selectImage,
                            child: CircleAvatar(
                              radius: 50,
                              backgroundImage: _selectedImage != null
                                  ? FileImage(_selectedImage!)
                                  : _currentUser!.profileImageUrl != null
                                      ? NetworkImage(
                                          _currentUser!.profileImageUrl!)
                                      : null,
                              child: _selectedImage == null &&
                                      _currentUser!.profileImageUrl == null
                                  ? const Icon(Icons.person, size: 50)
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: themeColor,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt,
                                    color: Colors.white),
                                onPressed: _updateProfileImage,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 画像削除ボタン
                      if (_currentUser!.profileImageUrl != null)
                        TextButton(
                          onPressed: _removeProfileImage,
                          child: const Text('画像を削除'),
                        ),

                      const SizedBox(height: 16),

                      // ユーザー名編集
                      TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'ユーザー名',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: (_isLoading || !_hasChanges()) ? null : _updateUsername,
          child: const Text('保存'),
        ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;

  const _SettingsSection({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }
}
