import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:outi_log/constant/color.dart';

class AddShoppingListBottomSheet extends StatefulWidget {
  const AddShoppingListBottomSheet({super.key});

  @override
  State<AddShoppingListBottomSheet> createState() =>
      _AddShoppingListBottomSheetState();
}

class _AddShoppingListBottomSheetState
    extends State<AddShoppingListBottomSheet> {
  final _listNameController = TextEditingController();
  final List<Map<String, TextEditingController>> _items = [];

  @override
  void initState() {
    super.initState();
    // 最初に空の商品を1つ追加しておく
    _addItem();
  }

  void _addItem() {
    setState(() {
      _items.add({
        'name': TextEditingController(),
        'cost': TextEditingController(),
      });
    });
  }

  void _removeItem(int index) {
    setState(() {
      // 最後の1つは消せないようにする
      if (_items.length > 1) {
        _items[index]['name']!.dispose();
        _items[index]['cost']!.dispose();
        _items.removeAt(index);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('商品は1つ以上必要です。')),
        );
      }
    });
  }

  void _saveList() {
    if (_listNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('リスト名を入力してください。')),
      );
      return;
    }

    final newItems = _items
        .map((item) {
          final name = item['name']!.text;
          final cost = int.tryParse(item['cost']!.text);
          if (name.isNotEmpty) {
            return {'name': name, 'checked': false, 'cost': cost};
          }
          return null;
        })
        .where((item) => item != null)
        .toList();

    if (newItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('商品を1つ以上追加してください。')),
      );
      return;
    }

    final newList = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'name': _listNameController.text,
      'items': newItems,
    };

    Navigator.of(context).pop(newList);
  }

  @override
  void dispose() {
    _listNameController.dispose();
    for (var item in _items) {
      item['name']!.dispose();
      item['cost']!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: 20 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: const BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        height: MediaQuery.of(context).size.height * 0.9,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: secondaryTextColor),
                  tooltip: '閉じる',
                ),
                const Text('新しい買い物リスト',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor)),
                TextButton(
                  onPressed: _saveList,
                  style: TextButton.styleFrom(
                    foregroundColor: primaryColor,
                  ),
                  child: const Text(
                    '保存する',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _listNameController,
              decoration: InputDecoration(
                labelText: 'リスト名',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('商品リスト',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: primaryTextColor)),
            const SizedBox(height: 8),
            const Divider(color: dividerColor),
            Expanded(
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildItemTextField(
                              _items[index]['name']!, '商品名'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: _buildItemTextField(
                              _items[index]['cost']!, '値段',
                              prefixText: '¥ ', isNumeric: true),
                        ),
                        IconButton(
                          icon: Icon(Icons.remove_circle_outline,
                              color: Colors.grey[400]),
                          onPressed: () => _removeItem(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('商品を追加'),
              onPressed: _addItem,
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: const BorderSide(color: primaryColor),
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemTextField(TextEditingController controller, String labelText,
      {String? prefixText, bool isNumeric = false}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        prefixText: prefixText,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      inputFormatters:
          isNumeric ? [FilteringTextInputFormatter.digitsOnly] : [],
    );
  }
}
