import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:outi_log/models/category_model.dart';

class CategoryFirestoreInfrastructure {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // カテゴリーを追加
  Future<String> addCategory({
    required String spaceId,
    required String name,
    required String color,
    required String type,
    required String createdBy,
  }) async {
    try {
      final categoryId = _firestore.collection('categories').doc().id;
      final now = DateTime.now();

      final category = CategoryModel(
        id: categoryId,
        spaceId: spaceId,
        name: name,
        color: color,
        type: type,
        createdBy: createdBy,
        createdAt: now,
        updatedAt: now,
        isActive: true,
      );

      await _firestore
          .collection('categories')
          .doc(categoryId)
          .set(category.toFirestore());

      return categoryId;
    } catch (e) {
      throw Exception('カテゴリーの追加に失敗しました: $e');
    }
  }

  // サブカテゴリーを追加
  Future<void> addSubCategory({
    required String spaceId,
    required String parentCategoryId,
    required String name,
    required String color,
    required String createdBy,
  }) async {
    try {
      final subCategoryId = _firestore.collection('sub_categories').doc().id;
      final now = DateTime.now();

      final subCategory = {
        'id': subCategoryId,
        'space_id': spaceId,
        'parent_category_id': parentCategoryId,
        'name': name,
        'color': color,
        'created_by': createdBy,
        'created_at': Timestamp.fromDate(now),
        'updated_at': Timestamp.fromDate(now),
        'is_active': true,
      };

      await _firestore
          .collection('sub_categories')
          .doc(subCategoryId)
          .set(subCategory);
    } catch (e) {
      throw Exception('サブカテゴリーの追加に失敗しました: $e');
    }
  }

  // スペースのカテゴリー一覧を取得
  Future<List<CategoryModel>> getCategoriesBySpace(String spaceId) async {
    try {
      final snapshot = await _firestore
          .collection('categories')
          .where('space_id', isEqualTo: spaceId)
          .where('is_active', isEqualTo: true)
          .orderBy('created_at', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('カテゴリーの取得に失敗しました: $e');
    }
  }

  // タイプ別のカテゴリー一覧を取得
  Future<List<CategoryModel>> getCategoriesByType(
    String spaceId,
    String type,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('categories')
          .where('space_id', isEqualTo: spaceId)
          .where('type', isEqualTo: type)
          .where('is_active', isEqualTo: true)
          .orderBy('created_at', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('カテゴリーの取得に失敗しました: $e');
    }
  }

  // サブカテゴリー一覧を取得
  Future<List<Map<String, dynamic>>> getSubCategoriesByParent(
    String spaceId,
    String parentCategoryId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('sub_categories')
          .where('space_id', isEqualTo: spaceId)
          .where('parent_category_id', isEqualTo: parentCategoryId)
          .where('is_active', isEqualTo: true)
          .orderBy('created_at', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // ドキュメントIDを追加
        return data;
      }).toList();
    } catch (e) {
      throw Exception('サブカテゴリーの取得に失敗しました: $e');
    }
  }

  // カテゴリーを更新
  Future<void> updateCategory({
    required String categoryId,
    required String name,
    required String color,
  }) async {
    try {
      await _firestore.collection('categories').doc(categoryId).update({
        'name': name,
        'color': color,
        'updated_at': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('カテゴリーの更新に失敗しました: $e');
    }
  }

  // サブカテゴリーを更新
  Future<void> updateSubCategory({
    required String subCategoryId,
    required String name,
    required String color,
  }) async {
    try {
      await _firestore.collection('sub_categories').doc(subCategoryId).update({
        'name': name,
        'color': color,
        'updated_at': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('サブカテゴリーの更新に失敗しました: $e');
    }
  }

  // カテゴリーを削除（論理削除）
  Future<void> deleteCategory(String categoryId) async {
    try {
      await _firestore.collection('categories').doc(categoryId).update({
        'is_active': false,
        'updated_at': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('カテゴリーの削除に失敗しました: $e');
    }
  }

  // サブカテゴリーを削除（論理削除）
  Future<void> deleteSubCategory(String subCategoryId) async {
    try {
      await _firestore.collection('sub_categories').doc(subCategoryId).update({
        'is_active': false,
        'updated_at': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('サブカテゴリーの削除に失敗しました: $e');
    }
  }
}
