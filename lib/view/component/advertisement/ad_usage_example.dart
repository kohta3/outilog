import 'package:flutter/material.dart';
import 'package:outi_log/view/component/advertisement/banner_ad_widget.dart';

/// AdMobバナー広告の使用例
///
/// このファイルは、AdMobバナー広告をアプリの様々な場所で
/// どのように使用するかの例を示しています。
///
/// 実際の画面に組み込む際は、以下のようにimportして使用してください：
///
/// ```dart
/// import 'package:outi_log/view/component/advertisement/banner_ad_widget.dart';
/// ```

class AdUsageExample extends StatelessWidget {
  const AdUsageExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AdMob使用例'),
      ),
      body: Column(
        children: [
          // 1. 画面上部にバナー広告を表示
          const TopBannerAdWidget(),

          // 2. メインコンテンツ
          Expanded(
            child: ListView(
              children: [
                const Card(
                  child: ListTile(
                    title: Text('コンテンツ1'),
                    subtitle: Text('通常のコンテンツ'),
                  ),
                ),

                // 3. コンテンツの間にバナー広告を表示
                const BannerAdWidget(
                  margin: EdgeInsets.all(16),
                ),

                const Card(
                  child: ListTile(
                    title: Text('コンテンツ2'),
                    subtitle: Text('通常のコンテンツ'),
                  ),
                ),

                // 4. 大きなバナー広告
                const LargeBannerAdWidget(
                  margin: EdgeInsets.all(16),
                ),

                const Card(
                  child: ListTile(
                    title: Text('コンテンツ3'),
                    subtitle: Text('通常のコンテンツ'),
                  ),
                ),

                // 5. 中サイズの矩形広告
                const MediumRectangleAdWidget(
                  margin: EdgeInsets.all(16),
                ),

                const Card(
                  child: ListTile(
                    title: Text('コンテンツ4'),
                    subtitle: Text('通常のコンテンツ'),
                  ),
                ),
              ],
            ),
          ),

          // 6. 画面下部に固定表示するバナー広告
          const BottomBannerAdWidget(),
        ],
      ),
    );
  }
}

/// ダッシュボード画面での使用例
/// 
/// ダッシュボード画面にバナー広告を追加する場合の例：
/// 
/// ```dart
/// @override
/// Widget build(BuildContext context) {
///   return Scaffold(
///     body: Column(
///       children: [
///         // 既存のダッシュボードコンテンツ
///         Expanded(
///           child: _buildDashboardContent(context, ref, currentSpace),
///         ),
///         
///         // 画面下部にバナー広告を追加
///         const BottomBannerAdWidget(),
///       ],
///     ),
///   );
/// }
/// ```

/// リスト画面での使用例
/// 
/// リスト画面でコンテンツの間に広告を表示する場合の例：
/// 
/// ```dart
/// @override
/// Widget build(BuildContext context) {
///   return Scaffold(
///     body: ListView.builder(
///       itemCount: items.length + (items.length ~/ 5), // 5項目ごとに広告を挿入
///       itemBuilder: (context, index) {
///         // 5項目ごとに広告を表示
///         if ((index + 1) % 6 == 0) {
///           return const BannerAdWidget(
///             margin: EdgeInsets.symmetric(vertical: 8),
///           );
///         }
///         
///         // 通常のコンテンツ
///         final itemIndex = index - (index ~/ 6);
///         return ListTile(
///           title: Text(items[itemIndex].title),
///         );
///       },
///     ),
///   );
/// }
/// ```
