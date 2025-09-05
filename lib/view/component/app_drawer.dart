import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outi_log/constant/color.dart';
import 'package:outi_log/models/space_model.dart';
import 'package:outi_log/provider/space_prodiver.dart';
import 'package:outi_log/provider/firestore_space_provider.dart';
import 'package:outi_log/view/space_add_screen.dart';
import 'package:outi_log/view/settings_screen.dart';
import 'package:outi_log/provider/auth_provider.dart';
import 'package:outi_log/controllers/auth_controller.dart';
import 'package:outi_log/infrastructure/auth_indrastructure.dart';
import 'package:outi_log/infrastructure/user_firestore_infrastructure.dart';
import 'package:outi_log/infrastructure/storage_infrastructure.dart';
import 'package:outi_log/provider/flutter_secure_storage_provider.dart';
import 'package:outi_log/repository/login_repo.dart';
import 'package:outi_log/infrastructure/invite_infrastructure.dart';
import 'package:outi_log/view/space_settings_screen.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    // Firestoreスペースを優先的に使用
    final firestoreSpaces = ref.watch(firestoreSpacesProvider);
    final localSpaces = ref.watch(spacesProvider);

    final spaces = firestoreSpaces ?? localSpaces;
    final currentSpace = spaces?.currentSpace;

    // プロバイダーもFirestoreを優先（未使用のため削除）

    final canCreateSpace = firestoreSpaces?.canCreateSpace ??
        ref.watch(spacesProvider.notifier).canCreateSpace;
    final remainingSpaces = firestoreSpaces?.remainingSpaces ??
        ref.watch(spacesProvider.notifier).remainingSpaces;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: themeColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 100,
                        height: 100,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'おうちログ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  currentUser?.email ?? 'ゲスト',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                if (currentSpace != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '現在のスペース: ${currentSpace.spaceName}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // スペース作成ボタン（常に表示）
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('スペースを作成'),
            subtitle: currentSpace != null
                ? Text('残り: $remainingSpaces個')
                : const Text('最初のスペースを作成'),
            enabled: canCreateSpace,
            onTap: canCreateSpace
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SpaceAddScreen(),
                      ),
                    );
                  }
                : null,
          ),
          const Divider(),

          // スペースがある場合のメニュー
          if (currentSpace != null) ...[
            // スペース一覧セクション
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'スペース一覧',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...spaces!.spaces.values.map((space) {
              final isCurrentSpace = space.id == spaces.currentSpaceId;
              final isOwner = space.ownerId == currentUser?.uid;
              final canDelete = isOwner && spaces.spaces.length > 1;

              return ListTile(
                leading: Icon(
                  isCurrentSpace ? Icons.home : Icons.home_outlined,
                  color: isCurrentSpace ? themeColor : Colors.grey,
                ),
                title: Text(
                  space.spaceName,
                  style: TextStyle(
                    fontWeight:
                        isCurrentSpace ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isCurrentSpace) const Text('現在のスペース'),
                    if (isOwner)
                      const Text('オーナー', style: TextStyle(fontSize: 12)),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 設定ボタン（オーナーの場合のみ）
                    if (isOwner)
                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.grey),
                        onPressed: () =>
                            _navigateToSpaceSettings(context, space),
                      ),
                    // 削除ボタン（オーナーかつ複数スペースがある場合のみ）
                    if (canDelete)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            _showDeleteSpaceDialog(context, ref, space),
                      ),
                  ],
                ),
                onTap: () {
                  if (!isCurrentSpace) {
                    // Firestoreスペースがある場合はFirestoreプロバイダーを使用
                    if (firestoreSpaces != null) {
                      ref
                          .read(firestoreSpacesProvider.notifier)
                          .switchSpace(space.id);
                    } else {
                      ref.read(spacesProvider.notifier).switchSpace(space.id);
                    }
                    Navigator.pop(context);
                  }
                  // 現在のスペースをタップした場合は何もしない
                },
              );
            }).toList(),
            const Divider(),
          ],

          // スペース参加ボタン（常に表示、制限チェックは内部で行う）
          ListTile(
            leading: const Icon(Icons.group_add),
            title: const Text('スペースに参加'),
            subtitle: Text('残り: $remainingSpaces個'),
            onTap: () {
              _showJoinSpaceDialog(context, ref);
            },
          ),
          const Divider(),

          // メニュー項目
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('設定'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('ログアウト'),
            onTap: () async {
              await _performLogout(context, ref);
            },
          ),
        ],
      ),
    );
  }

  void _showJoinSpaceDialog(BuildContext context, WidgetRef ref) {
    final inviteCodeController = TextEditingController();

    // 最新の状態を取得
    final firestoreSpaces = ref.read(firestoreSpacesProvider);
    final localSpaces = ref.read(spacesProvider);
    final spaces = firestoreSpaces ?? localSpaces;

    // 残りスペース数を計算
    int remainingSpaces;
    if (spaces == null) {
      remainingSpaces = 2; // スペースが0個の場合は2つまで参加可能
    } else {
      remainingSpaces = spaces.remainingSpaces;
    }

    // デバッグログ
    print('DEBUG: spaces = $spaces');
    print('DEBUG: remainingSpaces = $remainingSpaces');
    print('DEBUG: spaces?.spaces.length = ${spaces?.spaces.length}');

    // スペース制限チェック
    if (remainingSpaces <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('スペースの参加・作成上限（2個）に達しています'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _JoinSpaceDialog(
        inviteCodeController: inviteCodeController,
        onJoin: (inviteCode) => _joinSpace(context, ref, inviteCode),
      ),
    );
  }

  Future<void> _joinSpace(
      BuildContext context, WidgetRef ref, String inviteCode) async {
    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception('ユーザー情報が取得できません');
      }

      // 招待コードでスペースに参加
      final inviteInfrastructure = InviteInfrastructure();
      final success = await inviteInfrastructure.joinSpaceWithInviteCode(
        inviteCode: inviteCode,
        userId: currentUser.uid,
        userName: currentUser.displayName ?? 'ユーザー',
        userEmail: currentUser.email ?? '',
      );

      if (success) {
        // スペース一覧を更新
        final firestoreSpaces = ref.read(firestoreSpacesProvider);
        if (firestoreSpaces != null) {
          await ref.read(firestoreSpacesProvider.notifier).initializeSpaces();
        } else {
          final currentUser = ref.read(currentUserProvider);
          if (currentUser != null) {
            await ref
                .read(spacesProvider.notifier)
                .initializeSpaces(currentUser.uid);
          }
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('スペースに参加しました'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('参加に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteSpaceDialog(
      BuildContext context, WidgetRef ref, SpaceModel space) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('スペースを削除'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('「${space.spaceName}」を削除しますか？'),
            const SizedBox(height: 16),
            const Text(
              '注意：',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const Text(
              '• この操作は取り消せません\n'
              '• スペース内の全ての予定、家計簿、買い物リスト、カテゴリが完全に削除されます\n'
              '• データは復元できません\n'
              '• オーナーのみがスペースを削除できます',
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              final currentUser = ref.read(currentUserProvider);
              if (currentUser != null) {
                // Firestoreスペースがある場合はFirestoreプロバイダーを使用
                final firestoreSpaces = ref.read(firestoreSpacesProvider);
                final success = firestoreSpaces != null
                    ? await ref
                        .read(firestoreSpacesProvider.notifier)
                        .deleteSpace(space.id)
                    : await ref
                        .read(spacesProvider.notifier)
                        .deleteSpace(space.id, currentUser.uid);

                Navigator.pop(context);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('「${space.spaceName}」を削除しました'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('スペースの削除に失敗しました'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout(BuildContext context, WidgetRef ref) async {
    try {
      final authController = AuthController(
        AuthInfrastructure(),
        LoginRepo(ref.read(flutterSecureStorageControllerProvider.notifier)),
        UserFirestoreInfrastructure(),
        StorageInfrastructure(),
      );

      if (context.mounted) {
        Navigator.pop(context); // ドロワーを閉じる
      }

      await authController.signOut(context: context);
    } catch (e) {
      // エラーハンドリングはAuthController内で行われる
    }
  }

  /// スペース設定画面に遷移
  void _navigateToSpaceSettings(BuildContext context, SpaceModel space) {
    Navigator.pop(context); // ドロワーを閉じる
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SpaceSettingsScreen(space: space),
      ),
    );
  }
}

class _JoinSpaceDialog extends StatefulWidget {
  final TextEditingController inviteCodeController;
  final Function(String) onJoin;

  const _JoinSpaceDialog({
    required this.inviteCodeController,
    required this.onJoin,
  });

  @override
  State<_JoinSpaceDialog> createState() => _JoinSpaceDialogState();
}

class _JoinSpaceDialogState extends State<_JoinSpaceDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('スペースに参加'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('招待コードを入力してください'),
          const SizedBox(height: 16),
          TextField(
            controller: widget.inviteCodeController,
            decoration: const InputDecoration(
              labelText: '招待コード',
              border: OutlineInputBorder(),
              hintText: '例: ABC123',
            ),
            enabled: !_isLoading,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.info, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '招待コードはスペースのオーナーから取得してください',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleJoin,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('参加'),
        ),
      ],
    );
  }

  Future<void> _handleJoin() async {
    final inviteCode = widget.inviteCodeController.text.trim();

    if (inviteCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('招待コードを入力してください'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onJoin(inviteCode);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('参加に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
