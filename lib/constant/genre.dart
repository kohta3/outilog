import 'package:flutter/material.dart';

const Map<String, List<String>> genreList = {
  '食費': [
    '食料品',
    '外食',
    '飲み物',
    'お菓子',
  ],
  '日用品': [
    '洗剤',
    'トイレットペーパー',
    '消耗品',
  ],
  '交通費': [
    '電車・バス',
    'ガソリン',
    '駐車場',
    '自転車関連',
  ],
  '住居費': [
    '家賃',
    '住宅ローン',
    '管理費',
    '修繕費',
  ],
  '水道・光熱費': [
    '電気',
    'ガス',
    '水道',
    '灯油',
  ],
  '通信費': [
    'スマホ',
    'インターネット',
    '固定電話',
  ],
  '保険': [
    '生命保険',
    '医療保険',
    '自動車保険',
  ],
  '医療・健康': [
    '病院',
    '薬',
    '健康診断',
    'マッサージ',
  ],
  '教育・学習': [
    '授業料',
    '教材',
    '習い事',
    '本',
  ],
  '交際費': [
    'プレゼント',
    '飲み会',
    '交際関連',
  ],
  '趣味・娯楽': [
    '映画',
    'ゲーム',
    '旅行',
    '音楽',
    'スポーツ',
    '漫画',
  ],
  '美容・衣服': [
    '美容室',
    '化粧品',
    '洋服',
    '靴',
  ],
  '子ども関連': [
    '保育料',
    'おもちゃ',
    'ベビー用品',
  ],
  '税金': [
    '住民税',
    '所得税',
    '自動車税',
  ],
  'その他': [
    '雑費',
    '不明な支出',
    '一時的な支出',
  ],
};

// カテゴリー名に基づいて一貫した色を生成する関数
Color getGenreColor(String genre) {
  // 収入は常に緑色
  if (genre == '収入') {
    return Color(0xFF4CAF50);
  }

  // カテゴリー名のハッシュ値を計算して色を生成
  int hash = genre.hashCode;

  // 鮮明で区別しやすい色のパレット
  List<Color> colorPalette = [
    Color(0xFFE91E63), // ピンク
    Color(0xFF9C27B0), // 紫
    Color(0xFF3F51B5), // インディゴ
    Color(0xFF2196F3), // 青
    Color(0xFF00BCD4), // シアン
    Color(0xFF009688), // ティール
    Color(0xFFFF9800), // オレンジ
    Color(0xFF795548), // ブラウン
    Color(0xFFFFC107), // アンバー
    Color(0xFF607D8B), // ブルーグレー
    Color(0xFF8BC34A), // ライトグリーン
    Color(0xFF673AB7), // ディープパープル
    Color(0xFFE91E63), // ピンク（重複）
    Color(0xFF4CAF50), // 緑
    Color(0xFFF44336), // 赤
    Color(0xFF9E9E9E), // グレー
    Color(0xFF424242), // ダークグレー
    Color(0xFF795548), // ブラウン（重複）
    Color(0xFF3F51B5), // インディゴ（重複）
    Color(0xFF00BCD4), // シアン（重複）
  ];

  // ハッシュ値を使ってパレットから色を選択
  int colorIndex = hash.abs() % colorPalette.length;
  return colorPalette[colorIndex];
}

IconData getGenreIcon(String genre) {
  switch (genre) {
    case '収入':
      return Icons.arrow_upward;
    case '食費':
      return Icons.restaurant;
    case '日用品':
      return Icons.shopping_basket;
    case '交通費':
      return Icons.directions_car;
    case '住居費':
      return Icons.home;
    case '水道・光熱費':
      return Icons.electric_bolt;
    case '通信費':
      return Icons.phone_android;
    case '保険':
      return Icons.security;
    case '医療・健康':
      return Icons.local_hospital;
    case '教育・学習':
      return Icons.school;
    case '交際費':
      return Icons.people;
    case '趣味・娯楽':
      return Icons.sports_esports;
    case '美容・衣服':
      return Icons.checkroom;
    case '子ども関連':
      return Icons.child_care;
    case '税金':
      return Icons.account_balance;
    case 'その他':
      return Icons.more_horiz;
    default:
      return Icons.arrow_downward;
  }
}
