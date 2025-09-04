import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outi_log/constant/color.dart';
import 'package:outi_log/models/space_model.dart';
import 'package:outi_log/provider/space_prodiver.dart';
import 'package:outi_log/provider/firestore_space_provider.dart';
import 'package:outi_log/view/space_add_screen.dart';
import 'package:outi_log/view/settings_screen.dart';
import 'package:outi_log/provider/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isCurrentSpace) const Text('現在のスペース'),
                    if (isOwner)
                      const Text('オーナー', style: TextStyle(fontSize: 12)),
                  ],
                ),
                trailing: canDelete
                    ? IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            _showDeleteSpaceDialog(context, ref, space),
                      )
                    : null,
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
                },
              );
            }).toList(),
            const Divider(),
            // スペース参加ボタン
            ListTile(
              leading: const Icon(Icons.group_add),
              title: const Text('スペースに参加'),
              onTap: () {
                _showJoinSpaceDialog(context, ref);
              },
            ),
            const Divider(),
            // メニュー項目
          ],
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
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showJoinSpaceDialog(BuildContext context, WidgetRef ref) {
    final inviteCodeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('スペースに参加'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('招待コードを入力してください'),
            const SizedBox(height: 16),
            TextField(
              controller: inviteCodeController,
              decoration: const InputDecoration(
                labelText: '招待コード',
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
              // TODO: スペース参加処理を実装
              Navigator.pop(context);
            },
            child: const Text('参加'),
          ),
        ],
      ),
    );
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
              '• スペース内の全ての予定、家計簿、買い物リストが削除されます\n'
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
}
