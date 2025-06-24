import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outi_log/constant/color.dart';
import 'package:outi_log/controllers/auth_controller.dart';
import 'package:outi_log/provider/space_prodiver.dart';
import 'package:outi_log/view/space_add_screen.dart';
import 'package:outi_log/view/settings_screen.dart';
import 'package:outi_log/provider/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final spaces = ref.watch(spacesProvider);
    final currentSpace = spaces?.currentSpace;
    final canCreateSpace = ref.watch(spacesProvider.notifier).canCreateSpace;
    final remainingSpaces = ref.watch(spacesProvider.notifier).remainingSpaces;

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
                subtitle: isCurrentSpace ? const Text('現在のスペース') : null,
                onTap: () {
                  if (!isCurrentSpace) {
                    ref.read(spacesProvider.notifier).switchSpace(space.id);
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
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('予定'),
              onTap: () {
                Navigator.pop(context);
                // 予定画面に移動
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('家計簿'),
              onTap: () {
                Navigator.pop(context);
                // 家計簿画面に移動
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('買い物リスト'),
              onTap: () {
                Navigator.pop(context);
                // 買い物リスト画面に移動
              },
            ),
            const Divider(),
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
}
