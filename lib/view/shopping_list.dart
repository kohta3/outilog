import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outi_log/constant/color.dart';
import 'package:outi_log/provider/shopping_list_provider.dart';
import 'package:outi_log/view/component/shopping_list/add_group_bottom_sheet.dart';
import 'package:outi_log/view/component/shopping_list/add_item_bottom_sheet.dart';
import 'package:outi_log/models/shopping_list_model.dart';

class ShoppingListScreen extends ConsumerStatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  ConsumerState<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen> {
  final Map<String, bool> _expandedGroups = {};

  @override
  void initState() {
    super.initState();
    // グループ一覧を読み込み
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shoppingListProvider.notifier).loadGroups();
    });
  }

  @override
  Widget build(BuildContext context) {
    final shoppingListState = ref.watch(shoppingListProvider);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('買い物リスト'),
        backgroundColor: background,
        elevation: 0,
      ),
      body: Column(
        children: [
          // エラー表示
          if (shoppingListState.error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      shoppingListState.error!,
                      style: TextStyle(color: Colors.red.shade600),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      ref.read(shoppingListProvider.notifier).clearError();
                    },
                    icon: Icon(Icons.close, color: Colors.red.shade600),
                  ),
                ],
              ),
            ),

          // メインコンテンツ
          Expanded(
            child: shoppingListState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildGroupListWithItems(shoppingListState),
          ),

          // フッターボタン
          Container(
            padding: const EdgeInsets.all(16),
            child: _buildActionButton(
              context,
              themeColor,
              'グループ作成',
              Icons.add,
              () => _showAddGroupSheet(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupListWithItems(shoppingListState) {
    if (shoppingListState.groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              '買い物リストグループがありません',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '下のボタンからグループを作成してください',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(shoppingListProvider.notifier).loadGroups();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: shoppingListState.groups.length,
        itemBuilder: (context, index) {
          final group = shoppingListState.groups[index];
          return _buildExpandableGroupCard(group);
        },
      ),
    );
  }

  Widget _buildExpandableGroupCard(ShoppingListGroupModel group) {
    final isExpanded = _expandedGroups[group.id] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // グループヘッダー
          ListTile(
            title: Text(
              group.groupName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '作成日: ${_formatDate(group.createdAt)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _showAddItemSheet(group),
                  icon: const Icon(Icons.add, color: themeColor),
                  tooltip: 'アイテム追加',
                ),
                IconButton(
                  onPressed: () => _showEditGroupSheet(group),
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  tooltip: '編集',
                ),
                IconButton(
                  onPressed: () => _showDeleteGroupDialog(group),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: '削除',
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _expandedGroups[group.id] = !isExpanded;
                    });
                    if (!isExpanded) {
                      // 展開時にアイテムを読み込み
                      ref
                          .read(shoppingListProvider.notifier)
                          .loadItemsForGroup(group.id);
                    }
                  },
                  icon: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: themeColor,
                  ),
                ),
              ],
            ),
          ),

          // 展開されたアイテムリスト
          if (isExpanded) _buildGroupItems(group),
        ],
      ),
    );
  }

  Widget _buildGroupItems(ShoppingListGroupModel group) {
    return FutureBuilder<List<ShoppingListItemModel>>(
      future:
          ref.read(shoppingListProvider.notifier).getItemsForGroup(group.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'エラー: ${snapshot.error}',
              style: TextStyle(color: Colors.red.shade600),
            ),
          );
        }

        final items = snapshot.data ?? [];

        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(
                  Icons.list_alt_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                Text(
                  'アイテムがありません',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '上の+ボタンからアイテムを追加してください',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: items.map((item) => _buildItemCard(item)).toList(),
        );
      },
    );
  }

  Widget _buildItemCard(ShoppingListItemModel item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          title: Text(
            item.itemName,
            style: TextStyle(
              decoration: item.isPurchased ? TextDecoration.lineThrough : null,
              color: item.isPurchased ? Colors.grey.shade600 : null,
            ),
          ),
          subtitle:
              item.amount != null ? Text('${item.amount!.toInt()}円') : null,
          leading: Checkbox(
            value: item.isPurchased,
            onChanged: (value) {
              ref.read(shoppingListProvider.notifier).togglePurchaseStatus(
                    item.id,
                    value ?? false,
                  );
            },
            activeColor: themeColor,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _showEditItemSheet(item),
                icon: const Icon(Icons.edit, size: 20),
                tooltip: '編集',
              ),
              IconButton(
                onPressed: () => _showDeleteItemDialog(item),
                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                tooltip: '削除',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    Color color,
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }

  void _showAddGroupSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const AddGroupBottomSheet(),
    ).then((result) {
      if (result == true) {
        ref.read(shoppingListProvider.notifier).loadGroups();
      }
    });
  }

  void _showEditGroupSheet(group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AddGroupBottomSheet(group: group),
    ).then((result) {
      if (result == true) {
        ref.read(shoppingListProvider.notifier).loadGroups();
      }
    });
  }

  void _showAddItemSheet(ShoppingListGroupModel group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AddItemBottomSheet(group: group),
    ).then((result) {
      if (result == true) {
        // 展開されているグループのアイテムを再読み込み
        if (_expandedGroups[group.id] == true) {
          setState(() {
            // 状態を更新してアイテムを再読み込み
          });
        }
      }
    });
  }

  void _showEditItemSheet(ShoppingListItemModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AddItemBottomSheet(item: item),
    ).then((result) {
      if (result == true) {
        // 展開されているグループのアイテムを再読み込み
        setState(() {
          // 状態を更新してアイテムを再読み込み
        });
      }
    });
  }

  void _showDeleteGroupDialog(ShoppingListGroupModel group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('グループを削除'),
        content: Text('「${group.groupName}」を削除しますか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(shoppingListProvider.notifier).deleteGroup(group.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  void _showDeleteItemDialog(ShoppingListItemModel item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('アイテムを削除'),
        content: Text('「${item.itemName}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(shoppingListProvider.notifier).deleteItem(item.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }
}
