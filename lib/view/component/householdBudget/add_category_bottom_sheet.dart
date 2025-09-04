import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outi_log/constant/color.dart';
import 'package:outi_log/provider/auth_provider.dart';
import 'package:outi_log/provider/category_provider.dart';
import 'package:outi_log/utils/toast.dart';

class AddCategoryBottomSheet extends ConsumerStatefulWidget {
  final String? initialType;
  final String? parentCategoryId;

  const AddCategoryBottomSheet({
    super.key,
    this.initialType,
    this.parentCategoryId,
  });

  @override
  ConsumerState<AddCategoryBottomSheet> createState() =>
      _AddCategoryBottomSheetState();
}

class _AddCategoryBottomSheetState extends ConsumerState<AddCategoryBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _categoryNameController = TextEditingController();
  final _subCategoryNameController = TextEditingController();
  String _selectedType = 'expense';
  String _selectedColor = '#2196F3';
  bool _isSaving = false;

  // カラーパレット
  final List<String> colorPalette = [
    '#2196F3', // Blue
    '#4CAF50', // Green
    '#FF9800', // Orange
    '#F44336', // Red
    '#9C27B0', // Purple
    '#00BCD4', // Cyan
    '#FFEB3B', // Yellow
    '#795548', // Brown
    '#607D8B', // Blue Grey
    '#E91E63', // Pink
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // 初期タイプが指定されている場合は対応するタブを選択
    if (widget.initialType == 'expense') {
      _tabController.index = 0;
    } else if (widget.initialType == 'income') {
      _tabController.index = 1;
    }

    // 親分類IDが指定されている場合はカテゴリー追加タブを選択
    if (widget.parentCategoryId != null) {
      _tabController.index = 1;
    }
  }

  Future<void> _saveCategory() async {
    // バリデーション
    if (_categoryNameController.text.trim().isEmpty) {
      Toast.show(context, '分類名を入力してください');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final currentUser = ref.read(currentUserProvider);
      final categoryNotifier = ref.read(categoryProvider.notifier);

      if (currentUser == null) {
        Toast.show(context, 'ログインが必要です');
        return;
      }

      await categoryNotifier.addCategory(
        name: _categoryNameController.text.trim(),
        color: _selectedColor,
        type: _selectedType,
        createdBy: currentUser.uid,
      );

      Toast.show(context, '分類を保存しました');
      Navigator.of(context).pop(true);
    } catch (e) {
      Toast.show(context, '保存に失敗しました: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _saveSubCategory() async {
    // バリデーション
    if (_subCategoryNameController.text.trim().isEmpty) {
      Toast.show(context, 'カテゴリー名を入力してください');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final currentUser = ref.read(currentUserProvider);
      final categoryNotifier = ref.read(categoryProvider.notifier);

      if (currentUser == null) {
        Toast.show(context, 'ログインが必要です');
        return;
      }

      // 親分類IDが指定されていない場合はエラー
      if (widget.parentCategoryId == null) {
        Toast.show(context, '親分類が指定されていません');
        return;
      }

      await categoryNotifier.addSubCategory(
        parentCategoryId: widget.parentCategoryId!,
        name: _subCategoryNameController.text.trim(),
        color: _selectedColor,
        createdBy: currentUser.uid,
      );

      Toast.show(context, 'カテゴリーを保存しました');
      Navigator.of(context).pop(true);
    } catch (e) {
      Toast.show(context, '保存に失敗しました: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _categoryNameController.dispose();
    _subCategoryNameController.dispose();
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
              tabs: const [
                Tab(text: '分類追加'),
                Tab(text: 'カテゴリー追加'),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCategoryForm(),
                  _buildSubCategoryForm(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryForm() {
    return Column(
      children: [
        _buildLabeledField(
            '分類名', _buildTextField(_categoryNameController, '例: 食費')),
        const SizedBox(height: 16),
        _buildLabeledField('タイプ', _buildTypeSelector()),
        const SizedBox(height: 16),
        _buildLabeledField('色', _buildColorSelector()),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: _isSaving ? null : _saveCategory,
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
              : const Text('分類を保存'),
        ),
      ],
    );
  }

  Widget _buildSubCategoryForm() {
    return Column(
      children: [
        _buildLabeledField(
            'カテゴリー名', _buildTextField(_subCategoryNameController, '例: 外食')),
        const SizedBox(height: 16),
        _buildLabeledField('親分類', _buildParentCategorySelector()),
        const SizedBox(height: 16),
        _buildLabeledField('色', _buildColorSelector()),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: _isSaving ? null : _saveSubCategory,
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
              : const Text('カテゴリーを保存'),
        ),
      ],
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

  Widget _buildTextField(TextEditingController controller, String hintText) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
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

  Widget _buildTypeSelector() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: _selectedType,
        onChanged: (String? newValue) {
          setState(() {
            _selectedType = newValue!;
          });
        },
        items: const [
          DropdownMenuItem<String>(
            value: 'expense',
            child: Text('支出', style: TextStyle(color: primaryTextColor)),
          ),
          DropdownMenuItem<String>(
            value: 'income',
            child: Text('収入', style: TextStyle(color: primaryTextColor)),
          ),
        ],
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: Colors.white,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildParentCategorySelector() {
    // TODO: 実際の親分類リストを取得
    final parentCategories = [
      '食費',
      '交通費',
      '日用品',
      '光熱費',
      '娯楽',
      '衣服',
      '医療費',
      'その他'
    ];

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: parentCategories.first,
        onChanged: (String? newValue) {
          // TODO: 親分類の選択処理
        },
        items: parentCategories.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
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

  Widget _buildColorSelector() {
    return Container(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: colorPalette.length,
        itemBuilder: (context, index) {
          final color = colorPalette[index];
          final isSelected = _selectedColor == color;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedColor = color;
              });
            },
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Color(int.parse(color.replaceFirst('#', '0xff'))),
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(color: Colors.black, width: 3)
                    : null,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : null,
            ),
          );
        },
      ),
    );
  }
}
