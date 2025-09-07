import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:outi_log/constant/color.dart';
import 'package:outi_log/view/bug_report_screen.dart';
import 'package:outi_log/services/system_info_service.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  String _version = '1.0.0';
  String _releaseDate = '2024年1月1日';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSystemInfo();
  }

  Future<void> _loadSystemInfo() async {
    try {
      final version = await SystemInfoService.getVersion();
      final releaseDate = await SystemInfoService.getReleaseDateFormatted();

      setState(() {
        _version = version;
        _releaseDate = releaseDate;
        _isLoading = false;
      });
    } catch (e) {
      print('システム情報の読み込みに失敗: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'ヘルプ・サポート',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: themeColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          // よくある質問セクション
          const _HelpSection(title: 'よくある質問'),

          _buildFAQItem(
            'アプリの基本的な使い方を教えてください',
            'OutiLogは家族やルームメイトと共有できる生活管理アプリです。\n\n'
                '主な機能：\n'
                '• スケジュール管理\n'
                '• 家計簿\n'
                '• 買い物リスト\n'
                '• スペース共有\n\n'
                'まずはスペースを作成し、家族やルームメイトを招待してご利用ください。',
          ),

          _buildFAQItem(
            'スペースに招待されましたが、参加できません',
            '以下の点をご確認ください：\n\n'
                '• 招待コードが正しく入力されているか\n'
                '• インターネット接続が安定しているか\n'
                '• アプリが最新バージョンか\n'
                '• スペースの参加者数が上限に達していないか\n\n'
                'それでも解決しない場合は、サポートまでお問い合わせください。',
          ),

          _buildFAQItem(
              'データが消えてしまいました',
              'データが消えてしまった場合、以下の可能性があります：\n\n'
                  '• アカウントを削除した\n'
                  '• スペースから削除された\n'
                  '• アプリをアンインストール・再インストールした\n'
                  '• ネットワークエラーで同期できていない\n\n'
                  '一度削除したデータは復元できません'),

          _buildFAQItem(
            '通知が届きません',
            '通知が届かない場合の対処法：\n\n'
                '• アプリの通知設定が有効になっているか確認\n'
                '• 端末の通知設定でアプリが許可されているか確認\n'
                '• アプリがバックグラウンドで動作しているか確認\n'
                '• 端末の省電力モードが無効になっているか確認\n\n'
                '設定画面から通知設定を確認・変更できます。',
          ),

          _buildFAQItem(
            'アカウントを削除したい',
            'アカウントを削除する手順：\n\n'
                '1. 設定画面を開く\n'
                '2. 「アカウント管理」セクションの「アカウントを削除」をタップ\n'
                '3. 削除内容を確認\n'
                '4. 「アカウントを削除」と入力\n'
                '5. 削除を実行\n\n'
                '⚠️ アカウント削除は取り消せません。'
                'すべてのデータが完全に削除されます。',
          ),

          const Divider(),

          // お問い合わせセクション
          const _HelpSection(title: 'お問い合わせ'),

          _buildContactItem(
            icon: Icons.bug_report,
            title: 'バグ報告',
            subtitle: '不具合や改善提案をお送りください',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BugReportScreen(),
                ),
              );
            },
          ),

          const Divider(),

          // アプリ情報セクション
          const _HelpSection(title: 'アプリ情報'),

          _buildInfoItem(
            'バージョン',
            _isLoading ? '読み込み中...' : _version,
            () => _copyToClipboard(context, _version),
          ),

          _buildInfoItem(
            '最終更新',
            _isLoading ? '読み込み中...' : _releaseDate,
            () => _copyToClipboard(context, _releaseDate),
          ),

          _buildInfoItem(
            '開発者',
            'OutiLog開発チーム',
            () => _copyToClipboard(context, 'OutiLog開発チーム'),
          ),

          const Divider(),

          // その他セクション
          const _HelpSection(title: 'その他'),

          ListTile(
            leading: const Icon(Icons.star, color: Colors.amber),
            title: const Text('アプリを評価する'),
            subtitle: const Text('App Store / Google Play'),
            onTap: () => _showComingSoonDialog(context),
          ),

          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('アプリをシェア'),
            subtitle: const Text('友達にOutiLogを紹介'),
            onTap: () => _shareApp(context),
          ),

          ListTile(
            leading: const Icon(Icons.feedback),
            title: const Text('フィードバック'),
            subtitle: const Text('ご意見・ご要望をお聞かせください'),
            onTap: () => _launchEmail(subject: 'フィードバック'),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: themeColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildInfoItem(String title, String value, VoidCallback onTap) {
    return ListTile(
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.copy, size: 16, color: Colors.grey),
        ],
      ),
      onTap: onTap,
    );
  }

  void _launchEmail({String? subject}) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@outilog.com',
      query: subject != null ? 'subject=${Uri.encodeComponent(subject)}' : null,
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        // メールアプリが利用できない場合のフォールバック
        throw Exception('メールアプリを開けませんでした');
      }
    } catch (e) {
      // エラーハンドリング
      print('メール起動エラー: $e');
    }
  }

  void _showComingSoonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('準備中'),
        content: const Text('この機能は現在準備中です。\n近日中にリリース予定です。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$text をコピーしました'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareApp(BuildContext context) {
    // アプリシェア機能（実装例）
    final String shareText = 'OutiLog - 家族・ルームメイトと共有する生活管理アプリ\n'
        'スケジュール、家計簿、買い物リストを一緒に管理できます！\n\n'
        'ダウンロード: https://outilog.com';

    Clipboard.setData(ClipboardData(text: shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('シェア用テキストをコピーしました'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  final String title;

  const _HelpSection({required this.title});

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
