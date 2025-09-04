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
        'subCategories': ['外食', '食材', '飲み物', 'お菓子', 'その他'],
      },
      {
        'name': '交通費',
        'color': '#2196F3',
        'subCategories': ['電車', 'バス', 'タクシー', 'ガソリン', 'その他'],
      },
      {
        'name': '日用品',
        'color': '#FF9800',
        'subCategories': ['洗剤', 'トイレットペーパー', '化粧品', '薬', 'その他'],
      },
      {
        'name': '光熱費',
        'color': '#F44336',
        'subCategories': ['電気', 'ガス', '水道', 'インターネット', 'その他'],
      },
      {
        'name': '娯楽',
        'color': '#9C27B0',
        'subCategories': ['映画', 'ゲーム', '本', 'スポーツ', 'その他'],
      },
      {
        'name': '衣服',
        'color': '#00BCD4',
        'subCategories': ['上着', '下着', '靴', 'アクセサリー', 'その他'],
      },
      {
        'name': '医療費',
        'color': '#FFEB3B',
        'subCategories': ['病院', '薬局', '歯科', '健康診断', 'その他'],
      },
      {
        'name': 'その他',
        'color': '#795548',
        'subCategories': ['雑費', '寄付', 'プレゼント', '修理費', 'その他'],
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
      {'name': '副業', 'color': '#2196F3'},
      {'name': '臨時収入', 'color': '#FF9800'},
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
