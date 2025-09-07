import 'package:flutter/material.dart';
import 'package:outi_log/constant/color.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'プライバシーポリシー',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: themeColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              '1. 個人情報の収集について',
              '本アプリでは、以下の個人情報を収集する場合があります：\n\n'
                  '• ユーザー名\n'
                  '• メールアドレス\n'
                  '• プロフィール画像\n'
                  '• アプリの使用状況データ\n'
                  '• デバイス情報（OS、バージョン等）',
            ),
            _buildSection(
              '2. 個人情報の利用目的',
              '収集した個人情報は以下の目的で利用します：\n\n'
                  '• アカウントの作成・管理\n'
                  '• サービス提供・改善\n'
                  '• お客様サポート\n'
                  '• セキュリティの確保\n'
                  '• 法的義務の履行',
            ),
            _buildSection(
              '3. 個人情報の第三者提供',
              '以下の場合を除き、個人情報を第三者に提供することはありません：\n\n'
                  '• お客様の同意がある場合\n'
                  '• 法令に基づく場合\n'
                  '• 人の生命、身体または財産の保護のために必要な場合\n'
                  '• 公衆衛生の向上または児童の健全な育成の推進のために特に必要な場合',
            ),
            _buildSection(
              '4. 個人情報の管理',
              '個人情報の漏洩、滅失、毀損の防止その他の安全管理のために、'
                  '必要かつ適切な技術的・組織的安全管理措置を講じます。',
            ),
            _buildSection(
              '5. 個人情報の開示・訂正・削除',
              'お客様は、当社が保有する自己の個人情報について、'
                  '開示・訂正・削除を求めることができます。\n\n'
                  'アプリ内の「設定」→「アカウントを削除」から'
                  'アカウントと関連データを削除できます。',
            ),
            _buildSection(
              '6. Cookie等の利用',
              '本アプリでは、サービス向上のためCookie等の技術を使用する場合があります。\n\n'
                  'Cookieの使用を希望されない場合は、'
                  'ブラウザの設定で無効にすることができます。',
            ),
            _buildSection(
              '7. プライバシーポリシーの変更',
              '本プライバシーポリシーは、法令の変更やサービス内容の変更に伴い、'
                  '予告なく変更する場合があります。\n\n'
                  '変更後のプライバシーポリシーは、'
                  '本アプリ内で公表した時点で効力を生じるものとします。',
            ),
            _buildSection(
              '8. お問い合わせ',
              '個人情報の取扱いに関するお問い合わせは、'
                  'アプリ内の「ヘルプ・サポート」からご連絡ください。',
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '最終更新日: 2024年1月1日',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
