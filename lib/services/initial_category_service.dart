import 'package:outi_log/infrastructure/category_firestore_infrastructure.dart';

class InitialCategoryService {
  final CategoryFirestoreInfrastructure _categoryInfrastructure;

  InitialCategoryService(this._categoryInfrastructure);

  /// 初期の分類とカテゴリーを登録
  Future<void> createInitialCategories({
    required String spaceId,
    required String createdBy,
  }) async {
    try {
      // 支出の初期分類とカテゴリー
      await _createExpenseCategories(spaceId, createdBy);

      // 収入の初期分類
      await _createIncomeCategories(spaceId, createdBy);
    } catch (e) {
      throw Exception('初期分類・カテゴリーの作成に失敗しました: $e');
    }
  }

  /// 支出の初期分類とカテゴリーを作成
  Future<void> _createExpenseCategories(
      String spaceId, String createdBy) async {
    final expenseCategories = [
      {
        'name': '食費',
        'color': '#4CAF50',
        'subCategories': ['食費', '食料品', '外食', '朝ご飯', '昼ご飯', '夜ご飯', 'その他食費'],
      },
      {
        'name': '日用品',
        'color': '#FF9800',
        'subCategories': ['日用品', '生活雑貨', '子ども関連', 'ペット関連', 'タバコ', 'その他日用品'],
      },
      {
        'name': '交通費',
        'color': '#2196F3',
        'subCategories': ['電車', 'バス', 'タクシー', '飛行機', '新幹線', 'その他交通費'],
      },
      {
        'name': '趣味・娯楽',
        'color': '#9C27B0',
        'subCategories': ['本・雑誌', '映画・音楽', 'ゲーム', '旅行', 'スポーツ', 'その他趣味・娯楽'],
      },
      {
        'name': '衣服・美容',
        'color': '#E91E63',
        'subCategories': ['洋服', '靴・バッグ', 'アクセサリー', '美容院', '化粧品', 'その他衣服・美容'],
      },
      {
        'name': '交際費',
        'color': '#FF5722',
        'subCategories': ['飲み会', 'プレゼント', '冠婚葬祭', 'その他交際費'],
      },
      {
        'name': '健康・医療',
        'color': '#FFEB3B',
        'subCategories': ['病院', '薬', 'サプリメント', 'マッサージ', 'その他健康・医療'],
      },
      {
        'name': '教育・教養',
        'color': '#00BCD4',
        'subCategories': ['学費', '習い事', '参考書', '塾', 'その他教育・教養'],
      },
      {
        'name': '現金・カード',
        'color': '#607D8B',
        'subCategories': ['ATM引き出し', 'クレジットカード支払い', '電子マネーチャージ', 'その他現金・カード'],
      },
      {
        'name': '水道・光熱費',
        'color': '#F44336',
        'subCategories': ['水道代', '電気代', 'ガス代', 'その他水道・光熱費'],
      },
      {
        'name': '通信費',
        'color': '#3F51B5',
        'subCategories': ['携帯電話料金', 'インターネット料金', '固定電話料金', 'その他通信費'],
      },
      {
        'name': '住宅',
        'color': '#795548',
        'subCategories': ['家賃', '住宅ローン', '管理費・修繕積立金', 'リフォーム', 'その他住宅'],
      },
      {
        'name': '車・バイク',
        'color': '#FFC107',
        'subCategories': [
          'ガソリン代',
          '駐車場代',
          '高速道路料金',
          '自動車税',
          '車検・メンテナンス',
          'その他車・バイク'
        ],
      },
      {
        'name': '税・社会保険',
        'color': '#9E9E9E',
        'subCategories': ['所得税', '住民税', '国民年金', '国民健康保険', 'その他税・社会保険'],
      },
      {
        'name': '保険',
        'color': '#673AB7',
        'subCategories': ['生命保険', '医療保険', '自動車保険', '火災保険', 'その他保険'],
      },
      {
        'name': '特別な支出',
        'color': '#FF4081',
        'subCategories': ['家電購入', '家具購入', '引っ越し', 'ご祝儀', 'その他特別な支出'],
      },
      {
        'name': '資産形成',
        'color': '#4CAF50',
        'subCategories': ['投資', '貯金', 'iDeCo', 'NISA', 'その他資産形成'],
      },
      {
        'name': 'その他',
        'color': '#607D8B',
        'subCategories': ['仕送り', '寄付', '雑費', '使途不明金'],
      },
    ];

    for (final categoryData in expenseCategories) {
      // 分類を作成
      final categoryId = await _categoryInfrastructure.addCategory(
        spaceId: spaceId,
        name: categoryData['name'] as String,
        color: categoryData['color'] as String,
        type: 'expense',
        createdBy: createdBy,
      );

      // サブカテゴリーを作成
      final subCategories = categoryData['subCategories'] as List<String>;
      for (final subCategoryName in subCategories) {
        await _categoryInfrastructure.addSubCategory(
          spaceId: spaceId,
          parentCategoryId: categoryId,
          name: subCategoryName,
          color: categoryData['color'] as String,
          createdBy: createdBy,
        );
      }
    }
  }

  /// 収入の初期分類を作成
  Future<void> _createIncomeCategories(String spaceId, String createdBy) async {
    final incomeCategories = [
      {'name': '給与', 'color': '#4CAF50'},
      {'name': 'ボーナス', 'color': '#2196F3'},
      {'name': '副業', 'color': '#FF9800'},
      {'name': '投資収益', 'color': '#9C27B0'},
      {'name': '臨時収入', 'color': '#FF5722'},
      {'name': 'その他', 'color': '#795548'},
    ];

    for (final categoryData in incomeCategories) {
      await _categoryInfrastructure.addCategory(
        spaceId: spaceId,
        name: categoryData['name'] as String,
        color: categoryData['color'] as String,
        type: 'income',
        createdBy: createdBy,
      );
    }
  }
}
