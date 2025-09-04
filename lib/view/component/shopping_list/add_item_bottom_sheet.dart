import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outi_log/constant/color.dart';
import 'package:outi_log/provider/shopping_list_provider.dart';
import 'package:outi_log/provider/auth_provider.dart';
import 'package:outi_log/utils/toast.dart';
import 'package:outi_log/models/shopping_list_model.dart';

class AddItemBottomSheet extends ConsumerStatefulWidget {
  final ShoppingListItemModel? item; // nullの場合は新規作成
  final ShoppingListGroupModel? group; // グループ情報

  const AddItemBottomSheet({super.key, this.item, this.group});

  @override
  ConsumerState<AddItemBottomSheet> createState() => _AddItemBottomSheetState();
}

class _AddItemBottomSheetState extends ConsumerState<AddItemBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _itemNameController.text = widget.item!.itemName;
      if (widget.item!.amount != null) {
        _amountController.text = widget.item!.amount!.toString();
      }
    }
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー
            Row(
              children: [
                Icon(
                  isEditing ? Icons.edit : Icons.add,
                  color: themeColor,
                ),
                const SizedBox(width: 8),
                Text(
                  isEditing ? 'アイテムを編集' : '新しいアイテムを追加',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // アイテム名入力
            TextFormField(
              controller: _itemNameController,
              decoration: InputDecoration(
                labelText: 'アイテム名',
                hintText: '例: 牛乳',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: themeColor),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'アイテム名を入力してください';
                }
                if (value.trim().length > 100) {
                  return 'アイテム名は100文字以内で入力してください';
                }
                return null;
              },
              maxLength: 100,
            ),
            const SizedBox(height: 16),

            // 金額入力
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: '金額（任意）',
                hintText: '例: 150',
                suffixText: '円',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: themeColor),
                ),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final amount = double.tryParse(value);
                  if (amount == null) {
                    return '有効な金額を入力してください';
                  }
                  if (amount < 0) {
                    return '金額は0以上で入力してください';
                  }
                  if (amount > 999999) {
                    return '金額は999,999円以下で入力してください';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // 保存ボタン
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
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
                    : Text(
                        isEditing ? '更新' : '追加',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      Toast.show(context, 'ログインが必要です');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final itemName = _itemNameController.text.trim();
      final amountText = _amountController.text.trim();
      final amount = amountText.isNotEmpty ? double.tryParse(amountText) : null;

      if (widget.item == null) {
        // 新規作成
        final groupId = widget.group?.id ??
            ref.read(shoppingListProvider).selectedGroup?.id;
        if (groupId == null) {
          Toast.show(context, 'グループが選択されていません');
          return;
        }

        final itemId =
            await ref.read(shoppingListProvider.notifier).createItemForGroup(
                  groupId: groupId,
                  itemName: itemName,
                  amount: amount,
                  createdBy: currentUser.uid,
                );

        if (itemId != null) {
          Toast.show(context, 'アイテムを追加しました');
          Navigator.of(context).pop(true);
        } else {
          Toast.show(context, 'アイテムの追加に失敗しました');
        }
      } else {
        // 更新
        await ref.read(shoppingListProvider.notifier).updateItem(
              itemId: widget.item!.id,
              itemName: itemName,
              amount: amount,
            );

        Toast.show(context, 'アイテムを更新しました');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      Toast.show(context, 'エラーが発生しました: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
}
