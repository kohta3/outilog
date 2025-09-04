import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outi_log/constant/color.dart';
import 'package:outi_log/utils/toast.dart';

class EditSubCategoryModal extends ConsumerStatefulWidget {
  final Map<String, String> subCategory;

  const EditSubCategoryModal({super.key, required this.subCategory});

  @override
  ConsumerState<EditSubCategoryModal> createState() =>
      _EditSubCategoryModalState();
}

class _EditSubCategoryModalState extends ConsumerState<EditSubCategoryModal> {
  late TextEditingController _nameController;
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
    _nameController =
        TextEditingController(text: widget.subCategory['name'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateSubCategory() async {
    if (_nameController.text.trim().isEmpty) {
      Toast.show(context, 'カテゴリー名を入力してください');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // TODO: サブカテゴリーの更新処理を実装
      await Future.delayed(const Duration(seconds: 1)); // 仮の遅延

      Navigator.of(context).pop(true);
    } catch (e) {
      Toast.show(context, '更新に失敗しました: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _deleteSubCategory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('カテゴリーを削除'),
        content: const Text('このカテゴリーを削除しますか？\n削除されたカテゴリーは復元できません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isSaving = true;
      });

      try {
        // TODO: サブカテゴリーの削除処理を実装
        await Future.delayed(const Duration(seconds: 1)); // 仮の遅延
        Navigator.of(context).pop(true);
      } catch (e) {
        Toast.show(context, '削除に失敗しました: $e');
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'カテゴリーを編集',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 24),
            _buildLabeledField('カテゴリー名', _buildNameField()),
            const SizedBox(height: 16),
            _buildLabeledField('色', _buildColorSelector()),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : _deleteSubCategory,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('削除'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _updateSubCategory,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
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
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('更新'),
                  ),
                ),
              ],
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

  Widget _buildNameField() {
    return TextField(
      controller: _nameController,
      decoration: InputDecoration(
        hintText: 'カテゴリー名を入力',
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
