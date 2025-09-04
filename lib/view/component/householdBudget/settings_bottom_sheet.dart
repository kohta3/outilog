import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outi_log/constant/color.dart';
import 'package:outi_log/models/category_model.dart';
import 'package:outi_log/provider/category_provider.dart';
import 'package:outi_log/view/component/householdBudget/add_category_bottom_sheet.dart';
import 'package:outi_log/view/component/householdBudget/edit_category_modal.dart';
import 'package:outi_log/view/component/householdBudget/edit_subcategory_modal.dart';
import 'package:outi_log/utils/toast.dart';

class SettingsBottomSheet extends ConsumerStatefulWidget {
  const SettingsBottomSheet({super.key});

  @override
  ConsumerState<SettingsBottomSheet> createState() =>
      _SettingsBottomSheetState();
}

class _SettingsBottomSheetState extends ConsumerState<SettingsBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // カテゴリーデータを読み込み
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryProvider.notifier).loadCategories();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryState = ref.watch(categoryProvider);

    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: EdgeInsets.only(
          top: 12,
          left: 20,
          right: 20,
          bottom: 20 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: const BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const Text(
              '分類・カテゴリー管理',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 16),
            TabBar(
              controller: _tabController,
              labelColor: primaryColor,
              unselectedLabelColor: secondaryTextColor,
              indicatorColor: primaryColor,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(text: '支出'),
                Tab(text: '収入'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCategoryList(
                      'expense', categoryState.expenseCategories),
                  _buildCategoryList('income', categoryState.incomeCategories),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList(String type, List<CategoryModel> categories) {
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.category_outlined,
                size: 64, color: secondaryTextColor),
            const SizedBox(height: 16),
            Text(
              '分類が登録されていません',
              style: TextStyle(fontSize: 16, color: secondaryTextColor),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _showAddCategoryModal(type),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('分類を追加'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 分類追加ボタン
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          child: ElevatedButton.icon(
            onPressed: () => _showAddCategoryModal(type),
            icon: const Icon(Icons.add),
            label: const Text('分類を追加'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        // 分類・カテゴリーリスト
        Expanded(
          child: ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _buildCategoryItem(category);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(CategoryModel category) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Color(int.parse(category.color.replaceFirst('#', '0xff'))),
            shape: BoxShape.circle,
          ),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        onExpansionChanged: (expanded) {
          if (expanded) {
            // サブカテゴリーを読み込み
            ref.read(categoryProvider.notifier).loadSubCategories(category.id);
          }
        },
        children: [
          // 分類編集ボタン
          ListTile(
            leading: const Icon(Icons.edit, color: primaryColor),
            title: const Text('分類を編集'),
            onTap: () => _showEditCategoryModal(category),
          ),
          // サブカテゴリーリスト（仮の実装）
          _buildSubCategoryList(category),
          // カテゴリー追加ボタン
          ListTile(
            leading: const Icon(Icons.add, color: primaryColor),
            title: const Text('カテゴリーを追加'),
            onTap: () => _showAddSubCategoryModal(category),
          ),
        ],
      ),
    );
  }

  Widget _buildSubCategoryList(CategoryModel category) {
    final categoryState = ref.watch(categoryProvider);
    final subCategories =
        categoryState.subCategoriesByParent[category.id] ?? [];

    if (subCategories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          '  カテゴリーが登録されていません',
          style: TextStyle(
            color: secondaryTextColor,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Column(
      children: subCategories.map((subCategory) {
        return ListTile(
          leading: const SizedBox(width: 20),
          title: Text('  ${subCategory.name}'),
          trailing: const Icon(Icons.edit, size: 16),
          onTap: () => _showEditSubCategoryModal({
            'id': subCategory.id,
            'name': subCategory.name,
          }),
        );
      }).toList(),
    );
  }

  void _showAddCategoryModal(String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddCategoryBottomSheet(initialType: type),
    ).then((result) {
      if (result == true) {
        ref.read(categoryProvider.notifier).loadCategories();
        Toast.show(context, '分類が追加されました');
      }
    });
  }

  void _showAddSubCategoryModal(CategoryModel parentCategory) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddCategoryBottomSheet(
        initialType: parentCategory.type,
        parentCategoryId: parentCategory.id,
      ),
    ).then((result) {
      if (result == true) {
        ref.read(categoryProvider.notifier).loadCategories();
        Toast.show(context, 'カテゴリーが追加されました');
      }
    });
  }

  void _showEditCategoryModal(CategoryModel category) {
    showDialog(
      context: context,
      builder: (context) => EditCategoryModal(category: category),
    ).then((result) {
      if (result == true) {
        ref.read(categoryProvider.notifier).loadCategories();
        Toast.show(context, '分類が更新されました');
      }
    });
  }

  void _showEditSubCategoryModal(Map<String, String> subCategory) {
    showDialog(
      context: context,
      builder: (context) => EditSubCategoryModal(subCategory: subCategory),
    ).then((result) {
      if (result == true) {
        ref.read(categoryProvider.notifier).loadCategories();
        Toast.show(context, 'カテゴリーが更新されました');
      }
    });
  }
}
