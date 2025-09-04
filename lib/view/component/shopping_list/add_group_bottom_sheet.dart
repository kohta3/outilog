import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outi_log/constant/color.dart';
import 'package:outi_log/provider/shopping_list_provider.dart';
import 'package:outi_log/provider/auth_provider.dart';
import 'package:outi_log/utils/toast.dart';
import 'package:outi_log/models/shopping_list_model.dart';

class AddGroupBottomSheet extends ConsumerStatefulWidget {
  final ShoppingListGroupModel? group; // nullの場合は新規作成

  const AddGroupBottomSheet({super.key, this.group});

  @override
  ConsumerState<AddGroupBottomSheet> createState() =>
      _AddGroupBottomSheetState();
}

class _AddGroupBottomSheetState extends ConsumerState<AddGroupBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.group != null) {
      _groupNameController.text = widget.group!.groupName;
    }
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.group != null;

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
                  isEditing ? 'グループを編集' : '新しいグループを作成',
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

            // グループ名入力
            TextFormField(
              controller: _groupNameController,
              decoration: InputDecoration(
                labelText: 'グループ名',
                hintText: '例: 週末の買い物',
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
                  return 'グループ名を入力してください';
                }
                if (value.trim().length > 50) {
                  return 'グループ名は50文字以内で入力してください';
                }
                return null;
              },
              maxLength: 50,
            ),
            const SizedBox(height: 24),

            // 保存ボタン
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveGroup,
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
                        isEditing ? '更新' : '作成',
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

  Future<void> _saveGroup() async {
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
      final groupName = _groupNameController.text.trim();

      if (widget.group == null) {
        // 新規作成
        final groupId =
            await ref.read(shoppingListProvider.notifier).createGroup(
                  groupName: groupName,
                  createdBy: currentUser.uid,
                );

        if (groupId != null) {
          Toast.show(context, 'グループを作成しました');
          Navigator.of(context).pop(true);
        } else {
          Toast.show(context, 'グループの作成に失敗しました');
        }
      } else {
        // 更新
        await ref.read(shoppingListProvider.notifier).updateGroup(
              groupId: widget.group!.id,
              groupName: groupName,
            );

        Toast.show(context, 'グループを更新しました');
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
