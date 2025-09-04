import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:outi_log/constant/color.dart';
import 'package:outi_log/infrastructure/transaction_firestore_infrastructure.dart';
import 'package:outi_log/provider/auth_provider.dart';
import 'package:outi_log/provider/firestore_space_provider.dart';
import 'package:outi_log/provider/category_provider.dart';
import 'package:outi_log/utils/toast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddTransactionBottomSheet extends ConsumerStatefulWidget {
  final String transactionType; // '支出' or '収入'

  const AddTransactionBottomSheet({super.key, required this.transactionType});

  @override
  ConsumerState<AddTransactionBottomSheet> createState() =>
      _AddTransactionBottomSheetState();
}

class _AddTransactionBottomSheetState
    extends ConsumerState<AddTransactionBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _amountController = TextEditingController();
  final _memoController = TextEditingController();
  String? _selectedMainCategory;
  String? _selectedSubCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  final TransactionFirestoreInfrastructure _transactionInfrastructure =
      TransactionFirestoreInfrastructure();

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.transactionType == '支出' ? 0 : 1;
    _tabController =
        TabController(length: 2, vsync: this, initialIndex: initialIndex);

    // カテゴリーデータを読み込み
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryProvider.notifier).loadCategories();
    });
  }

  Future<void> _saveTransaction() async {
    // バリデーション
    if (_amountController.text.isEmpty) {
      Toast.show(context, '金額を入力してください');
      return;
    }

    if (_selectedMainCategory == null) {
      Toast.show(context, 'カテゴリーを選択してください');
      return;
    }

    // 支出の場合はカテゴリーも必須
    if (_tabController.index == 0 && _selectedSubCategory == null) {
      Toast.show(context, 'カテゴリーを選択してください');
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      Toast.show(context, '有効な金額を入力してください');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final currentUser = ref.read(currentUserProvider);
      final spaceState = ref.read(firestoreSpacesProvider);
      final currentSpace = spaceState?.currentSpace;

      if (currentUser == null) {
        Toast.show(context, 'ログインが必要です');
        return;
      }

      if (currentSpace == null) {
        Toast.show(context, 'スペースが選択されていません');
        return;
      }

      final transactionType = _tabController.index == 0 ? 'expense' : 'income';
      final categoryState = ref.read(categoryProvider);

      // 分類名を取得
      String categoryName = '';
      String title = '';

      if (_tabController.index == 0) {
        // 支出の場合
        final category = categoryState.expenseCategories
            .firstWhere((c) => c.id == _selectedMainCategory);
        categoryName = category.name;

        if (_selectedSubCategory != null) {
          final subCategories =
              categoryState.subCategoriesByParent[_selectedMainCategory] ?? [];
          final subCategory =
              subCategories.firstWhere((sc) => sc.id == _selectedSubCategory);
          title = '${category.name} - ${subCategory.name}';
        } else {
          title = category.name;
        }
      } else {
        // 収入の場合
        final category = categoryState.incomeCategories
            .firstWhere((c) => c.id == _selectedMainCategory);
        categoryName = category.name;
        title = category.name;
      }

      await _transactionInfrastructure.addTransaction(
        spaceId: currentSpace.id,
        title: title,
        amount: amount,
        category: categoryName,
        type: transactionType,
        transactionDate: _selectedDate,
        createdBy: currentUser.uid,
        description: _memoController.text,
      );

      Toast.show(
          context, '${transactionType == 'expense' ? '支出' : '収入'}を保存しました');
      Navigator.of(context).pop(true);
    } catch (e) {
      Toast.show(context, '保存に失敗しました: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
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
          mainAxisSize: MainAxisSize.min,
          children: [
            TabBar(
              controller: _tabController,
              labelColor: primaryColor,
              unselectedLabelColor: secondaryTextColor,
              indicatorColor: primaryColor,
              indicatorSize: TabBarIndicatorSize.tab,
              onTap: (index) {
                setState(() {
                  final categoryState = ref.read(categoryProvider);
                  if (index == 0) {
                    // 支出タブ
                    if (categoryState.expenseCategories.isNotEmpty) {
                      _selectedMainCategory =
                          categoryState.expenseCategories.first.id;
                      _selectedSubCategory = null;
                    }
                  } else {
                    // 収入タブ
                    if (categoryState.incomeCategories.isNotEmpty) {
                      _selectedMainCategory =
                          categoryState.incomeCategories.first.id;
                      _selectedSubCategory = null; // 収入はカテゴリーなし
                    }
                  }
                });
              },
              tabs: const [
                Tab(text: '支出'),
                Tab(text: '収入'),
              ],
            ),
            const SizedBox(height: 24),
            _buildLabeledField('金額', _buildAmountField()),
            const SizedBox(height: 16),
            _buildLabeledField('メモ', _buildTextField(_memoController, 'メモ')),
            const SizedBox(height: 16),
            _buildLabeledField('分類', _buildMainCategoryDropdown()),
            const SizedBox(height: 16),
            // 支出の場合のみカテゴリーを表示
            if (_tabController.index == 0) ...[
              _buildLabeledField('カテゴリー', _buildSubCategoryDropdown()),
              const SizedBox(height: 16),
            ],
            _buildLabeledField('日付', _buildDateField()),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: _isSaving ? null : _saveTransaction,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green,
                side: const BorderSide(color: themeColor),
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    )
                  : const Text('保存する'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabeledField(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: secondaryTextColor,
          ),
        ),
        const SizedBox(height: 8),
        field,
      ],
    );
  }

  Widget _buildAmountField() {
    return TextField(
      controller: _amountController,
      decoration: InputDecoration(
        prefix: const Text(
          '¥ ',
          style: TextStyle(
              fontSize: 18,
              color: primaryTextColor,
              fontWeight: FontWeight.bold),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildMainCategoryDropdown() {
    final categoryState = ref.watch(categoryProvider);
    final categories = _tabController.index == 0
        ? categoryState.expenseCategories
        : categoryState.incomeCategories;

    if (categories.isEmpty) {
      return Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            '分類が登録されていません',
            style: TextStyle(color: secondaryTextColor),
          ),
        ),
      );
    }

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: _selectedMainCategory,
        onChanged: (String? newValue) {
          setState(() {
            _selectedMainCategory = newValue;
            _selectedSubCategory = null; // 分類変更時はカテゴリーをリセット
          });
          // サブカテゴリーを読み込み
          if (newValue != null && _tabController.index == 0) {
            ref.read(categoryProvider.notifier).loadSubCategories(newValue);
          }
        },
        items: categories.map<DropdownMenuItem<String>>((category) {
          return DropdownMenuItem<String>(
            value: category.id,
            child: Text(
              category.name,
              style: const TextStyle(color: primaryTextColor),
            ),
          );
        }).toList(),
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: Colors.white,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildSubCategoryDropdown() {
    if (_selectedMainCategory == null || _tabController.index != 0)
      return const SizedBox();

    final categoryState = ref.watch(categoryProvider);
    final subCategories =
        categoryState.subCategoriesByParent[_selectedMainCategory] ?? [];

    if (subCategories.isEmpty) {
      return Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'カテゴリーが登録されていません',
            style: TextStyle(color: secondaryTextColor),
          ),
        ),
      );
    }

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: _selectedSubCategory,
        onChanged: (String? newValue) {
          setState(() {
            _selectedSubCategory = newValue;
          });
        },
        items: subCategories.map<DropdownMenuItem<String>>((subCategory) {
          return DropdownMenuItem<String>(
            value: subCategory.id,
            child: Text(
              subCategory.name,
              style: const TextStyle(color: primaryTextColor),
            ),
          );
        }).toList(),
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: Colors.white,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('yyyy/MM/dd').format(_selectedDate),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Icon(Icons.calendar_today,
                color: secondaryTextColor, size: 20),
          ],
        ),
      ),
    );
  }
}
