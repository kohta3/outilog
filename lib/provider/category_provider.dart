import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:outi_log/infrastructure/category_firestore_infrastructure.dart';
import 'package:outi_log/models/category_model.dart';
import 'package:outi_log/provider/firestore_space_provider.dart';

// カテゴリーインフラストラクチャのプロバイダー
final categoryInfrastructureProvider =
    Provider<CategoryFirestoreInfrastructure>((ref) {
  return CategoryFirestoreInfrastructure();
});

// サブカテゴリーモデル
class SubCategoryModel {
  final String id;
  final String spaceId;
  final String parentCategoryId;
  final String name;
  final String color;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  SubCategoryModel({
    required this.id,
    required this.spaceId,
    required this.parentCategoryId,
    required this.name,
    required this.color,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
  });

  factory SubCategoryModel.fromFirestore(Map<String, dynamic> data) {
    return SubCategoryModel(
      id: data['id'] ?? '',
      spaceId: data['space_id'] ?? '',
      parentCategoryId: data['parent_category_id'] ?? '',
      name: data['name'] ?? '',
      color: data['color'] ?? '#2196F3',
      createdBy: data['created_by'] ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['is_active'] ?? true,
    );
  }
}

// カテゴリー状態のプロバイダー
class CategoryState {
  final List<CategoryModel> categories;
  final List<CategoryModel> expenseCategories;
  final List<CategoryModel> incomeCategories;
  final Map<String, List<SubCategoryModel>> subCategoriesByParent;
  final bool isLoading;
  final String? error;

  CategoryState({
    this.categories = const [],
    this.expenseCategories = const [],
    this.incomeCategories = const [],
    this.subCategoriesByParent = const {},
    this.isLoading = false,
    this.error,
  });

  CategoryState copyWith({
    List<CategoryModel>? categories,
    List<CategoryModel>? expenseCategories,
    List<CategoryModel>? incomeCategories,
    Map<String, List<SubCategoryModel>>? subCategoriesByParent,
    bool? isLoading,
    String? error,
  }) {
    return CategoryState(
      categories: categories ?? this.categories,
      expenseCategories: expenseCategories ?? this.expenseCategories,
      incomeCategories: incomeCategories ?? this.incomeCategories,
      subCategoriesByParent:
          subCategoriesByParent ?? this.subCategoriesByParent,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// カテゴリープロバイダー
class CategoryNotifier extends StateNotifier<CategoryState> {
  final CategoryFirestoreInfrastructure _infrastructure;
  final Ref _ref;

  CategoryNotifier(this._infrastructure, this._ref) : super(CategoryState());

  // カテゴリー一覧を読み込み
  Future<void> loadCategories() async {
    final spaceState = _ref.read(firestoreSpacesProvider);
    final currentSpace = spaceState?.currentSpace;

    if (currentSpace == null) {
      state = state.copyWith(error: 'スペースが選択されていません');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final categories =
          await _infrastructure.getCategoriesBySpace(currentSpace.id);
      final expenseCategories =
          categories.where((c) => c.type == 'expense').toList();
      final incomeCategories =
          categories.where((c) => c.type == 'income').toList();

      state = state.copyWith(
        categories: categories,
        expenseCategories: expenseCategories,
        incomeCategories: incomeCategories,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // サブカテゴリー一覧を読み込み
  Future<void> loadSubCategories(String parentCategoryId) async {
    final spaceState = _ref.read(firestoreSpacesProvider);
    final currentSpace = spaceState?.currentSpace;

    if (currentSpace == null) {
      return;
    }

    try {
      final subCategoriesData = await _infrastructure.getSubCategoriesByParent(
        currentSpace.id,
        parentCategoryId,
      );

      final subCategories = subCategoriesData
          .map((data) => SubCategoryModel.fromFirestore(data))
          .toList();

      final updatedSubCategories = Map<String, List<SubCategoryModel>>.from(
        state.subCategoriesByParent,
      );
      updatedSubCategories[parentCategoryId] = subCategories;

      state = state.copyWith(
        subCategoriesByParent: updatedSubCategories,
      );
    } catch (e) {
      // エラーは無視（サブカテゴリーがない場合もある）
    }
  }

  // カテゴリーを追加
  Future<String?> addCategory({
    required String name,
    required String color,
    required String type,
    required String createdBy,
  }) async {
    final spaceState = _ref.read(firestoreSpacesProvider);
    final currentSpace = spaceState?.currentSpace;

    if (currentSpace == null) {
      state = state.copyWith(error: 'スペースが選択されていません');
      return null;
    }

    try {
      final categoryId = await _infrastructure.addCategory(
        spaceId: currentSpace.id,
        name: name,
        color: color,
        type: type,
        createdBy: createdBy,
      );

      // カテゴリー一覧を再読み込み
      await loadCategories();
      return categoryId;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  // サブカテゴリーを追加
  Future<void> addSubCategory({
    required String parentCategoryId,
    required String name,
    required String color,
    required String createdBy,
  }) async {
    final spaceState = _ref.read(firestoreSpacesProvider);
    final currentSpace = spaceState?.currentSpace;

    if (currentSpace == null) {
      state = state.copyWith(error: 'スペースが選択されていません');
      return;
    }

    try {
      await _infrastructure.addSubCategory(
        spaceId: currentSpace.id,
        parentCategoryId: parentCategoryId,
        name: name,
        color: color,
        createdBy: createdBy,
      );

      // カテゴリー一覧を再読み込み
      await loadCategories();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // カテゴリーを更新
  Future<void> updateCategory({
    required String categoryId,
    required String name,
    required String color,
  }) async {
    try {
      await _infrastructure.updateCategory(
        categoryId: categoryId,
        name: name,
        color: color,
      );

      // カテゴリー一覧を再読み込み
      await loadCategories();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // カテゴリーを削除
  Future<void> deleteCategory(String categoryId) async {
    try {
      await _infrastructure.deleteCategory(categoryId);

      // カテゴリー一覧を再読み込み
      await loadCategories();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // エラーをクリア
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// カテゴリープロバイダー
final categoryProvider =
    StateNotifierProvider<CategoryNotifier, CategoryState>((ref) {
  final infrastructure = ref.watch(categoryInfrastructureProvider);
  return CategoryNotifier(infrastructure, ref);
});
