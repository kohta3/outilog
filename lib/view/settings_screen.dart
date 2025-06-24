import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outi_log/constant/color.dart';
import 'package:outi_log/provider/space_prodiver.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaces = ref.watch(spacesProvider);
    final canCreateSpace = ref.watch(spacesProvider.notifier).canCreateSpace;
    final remainingSpaces = ref.watch(spacesProvider.notifier).remainingSpaces;
    final maxSpaces = spaces?.maxSpaces ?? 2;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('設定'),
        backgroundColor: themeColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          // スペース管理セクション
          const _SettingsSection(title: 'スペース管理'),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('スペース一覧'),
            subtitle: Text('${spaces?.spaces.length ?? 0}個 / $maxSpaces個'),
            onTap: () {
              // TODO: スペース一覧画面に移動
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
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('プッシュ通知'),
            trailing: Switch(
              value: true, // TODO: 実際の設定値を使用
              onChanged: (value) {
                // TODO: 通知設定を変更
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('メール通知'),
            trailing: Switch(
              value: false, // TODO: 実際の設定値を使用
              onChanged: (value) {
                // TODO: メール通知設定を変更
              },
            ),
          ),
          const Divider(),

          // プライバシーセクション
          const _SettingsSection(title: 'プライバシー'),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('プライバシーポリシー'),
            onTap: () {
              // TODO: プライバシーポリシー画面に移動
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('利用規約'),
            onTap: () {
              // TODO: 利用規約画面に移動
            },
          ),
          const Divider(),

          // データ管理セクション
          const _SettingsSection(title: 'データ管理'),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('データエクスポート'),
            onTap: () {
              // TODO: データエクスポート機能
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('アカウント削除'),
            onTap: () {
              _showDeleteAccountDialog(context);
            },
          ),
          const Divider(),

          // ヘルプセクション
          const _SettingsSection(title: 'ヘルプ'),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('ヘルプ・サポート'),
            onTap: () {
              // TODO: ヘルプ画面に移動
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('アプリについて'),
            subtitle: const Text('バージョン 1.0.0'),
            onTap: () {
              // TODO: アプリ情報画面に移動
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

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('アカウント削除'),
        content: const Text(
          'アカウントを削除すると、すべてのデータが完全に削除され、復元できません。本当に削除しますか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: アカウント削除処理を実装
              Navigator.pop(context);
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
