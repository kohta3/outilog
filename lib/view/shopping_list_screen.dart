import 'package:flutter/material.dart';
import 'package:outi_log/constant/color.dart';
import 'package:outi_log/view/component/shoppingList/add_shopping_list_bottom_sheet.dart';
import 'package:outi_log/view/component/shoppingList/no_data.dart';
import 'package:outi_log/view/component/shoppingList/shopping_list_card.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  // ダミーデータ
  final List<Map<String, dynamic>> _shoppingLists = [
    {
      'id': 1,
      'name': '今日の買い物',
      'items': [
        {'name': '白米', 'checked': true, 'cost': 500},
        {'name': 'パン', 'checked': false, 'cost': 200},
        {'name': '卵', 'checked': true, 'cost': 280},
        {'name': '牛乳', 'checked': false, 'cost': null},
      ],
    },
    {
      'id': 2,
      'name': '日用品リスト',
      'items': [
        {'name': 'トイレットペーパー', 'checked': false, 'cost': 800},
        {'name': '洗剤', 'checked': false, 'cost': 500},
        {'name': 'シャンプー', 'checked': true, 'cost': 800},
      ],
    },
    {
      'id': 3,
      'name': 'カレーの材料',
      'items': [
        {'name': 'じゃがいも', 'checked': true, 'cost': 150},
        {'name': 'にんじん', 'checked': true, 'cost': 100},
        {'name': '玉ねぎ', 'checked': true, 'cost': 120},
        {'name': '豚肉', 'checked': false, 'cost': 610},
        {'name': 'カレールー', 'checked': false, 'cost': null},
      ],
    },
  ];

  void _deleteShoppingList(int id) {
    setState(() {
      _shoppingLists.removeWhere((list) => list['id'] == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: _shoppingLists.isEmpty
            ? NoData()
            : ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 90),
                itemCount: _shoppingLists.length,
                itemBuilder: (context, index) {
                  final listData = _shoppingLists[index];
                  // 型安全のためにキャスト
                  final listId = listData['id'] as int;
                  final name = listData['name'] as String;
                  final items = listData['items'] as List;

                  return ShoppingListCard(
                    listData: {
                      'name': name,
                      'items': items,
                    },
                    onDelete: () => _deleteShoppingList(listId),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newList = await showModalBottomSheet<Map<String, dynamic>>(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) {
              return const AddShoppingListBottomSheet();
            },
          );

          if (newList != null) {
            setState(() {
              _shoppingLists.insert(0, newList);
            });
          }
        },
        shape: const CircleBorder(),
        backgroundColor: themeColor,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
}
