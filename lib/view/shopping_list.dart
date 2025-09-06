import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outi_log/constant/color.dart';
import 'package:outi_log/provider/shopping_list_provider.dart';
import 'package:outi_log/view/component/shopping_list/add_group_bottom_sheet.dart';
import 'package:outi_log/view/component/shopping_list/add_item_bottom_sheet.dart';
import 'package:outi_log/view/component/advertisement/native_ad_widget.dart';
import 'package:outi_log/models/shopping_list_model.dart';

class ShoppingListScreen extends ConsumerStatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  ConsumerState<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen> {
  final Map<String, bool> _expandedGroups = {};
  bool _isEditMode = false;

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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: ElevatedButton(
                    onPressed: shoppingListState.groups.length >= 5
                        ? null
                        : () => _showAddGroupSheet(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: shoppingListState.groups.length >= 5
                          ? Colors.grey
                          : Colors.blue,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shadowColor: Colors.blue.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text('グループ作成'),
                      ],
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isEditMode = !_isEditMode;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isEditMode ? Colors.green : themeColor,
                      foregroundColor: Colors.white,
                      elevation: _isEditMode ? 4 : 2,
                      shadowColor: (_isEditMode ? Colors.green : themeColor)
                          .withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isEditMode ? Icons.check : Icons.edit,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(_isEditMode ? '完了' : '編集'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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

          // グループ数制限の案内
          if (shoppingListState.groups.length >= 5)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.orange.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '買い物リストグループは最大5件まで作成できます。新しいグループを作成するには、既存のグループを削除してください。',
                      style: TextStyle(color: Colors.orange.shade700),
                    ),
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
      child: _buildGroupsWithAds(shoppingListState),
    );
  }

  Widget _buildGroupsWithAds(shoppingListState) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: shoppingListState.groups.length,
      itemBuilder: (context, index) {
        final group = shoppingListState.groups[index];
        return _buildExpandableGroupCard(group);
      },
    );
  }

  Widget _buildExpandableGroupCard(ShoppingListGroupModel group) {
    final isExpanded = _expandedGroups[group.id] ?? false;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: isExpanded ? 8 : 3,
        shadowColor: themeColor.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                themeColor.withOpacity(0.02),
              ],
            ),
          ),
          child: Column(
            children: [
              // グループヘッダー
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                title: Text(
                  group.groupName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isExpanded ? themeColor : Colors.grey.shade800,
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
                    if (_isEditMode) ...[
                      _buildAnimatedIconButton(
                        onPressed: () => _showEditGroupSheet(group),
                        icon: Icons.edit,
                        color: Colors.blue,
                        tooltip: '編集',
                      ),
                      _buildAnimatedIconButton(
                        onPressed: () => _showDeleteGroupDialog(group),
                        icon: Icons.delete,
                        color: Colors.red,
                        tooltip: '削除',
                      ),
                    ],
                    _buildAnimatedIconButton(
                      onPressed: () {
                        setState(() {
                          _expandedGroups[group.id] = !isExpanded;
                        });
                        if (!isExpanded) {
                          // 展開時にアイテムを読み込み
                          ref.invalidate(groupItemsProvider(group.id));
                        }
                      },
                      icon: isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: themeColor,
                      tooltip: isExpanded ? '折りたたむ' : '展開',
                    ),
                  ],
                ),
              ),

              // 展開されたアイテムリスト
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: isExpanded
                    ? _buildGroupItems(group)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupItems(ShoppingListGroupModel group) {
    // グループのアイテムをプロバイダーから取得
    final itemsAsync = ref.watch(groupItemsProvider(group.id));

    return itemsAsync.when(
      data: (items) => _buildItemsList(items, group),
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'エラー: $error',
          style: TextStyle(color: Colors.red.shade600),
        ),
      ),
    );
  }

  Widget _buildItemsList(
      List<ShoppingListItemModel> items, ShoppingListGroupModel group) {
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
            const SizedBox(height: 16),
            // 追加ボタン
            Container(
              width: double.infinity,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: Card(
                  elevation: 2,
                  shadowColor: themeColor.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                        color: themeColor.withOpacity(0.3), width: 1.5),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          themeColor.withOpacity(0.05),
                          themeColor.withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.add, color: themeColor, size: 20),
                      ),
                      title: Text(
                        'アイテムを追加',
                        style: TextStyle(
                          color: themeColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      onTap: () => _showAddItemSheet(group),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    List<Widget> widgets = [];

    // アイテムを追加し、4アイテムごとにネイティブ広告を挿入
    for (int i = 0; i < items.length; i++) {
      widgets.add(_buildItemCard(items[i]));

      // 4アイテムごとにネイティブ広告を挿入
      if ((i + 1) % 4 == 0) {
        widgets.add(const ListNativeAdWidget(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ));
      }
    }

    // 追加ボタン
    widgets.add(
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: Card(
            elevation: 2,
            shadowColor: themeColor.withOpacity(0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: themeColor.withOpacity(0.3), width: 1.5),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    themeColor.withOpacity(0.05),
                    themeColor.withOpacity(0.1),
                  ],
                ),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.add, color: themeColor, size: 20),
                ),
                title: Text(
                  'アイテムを追加',
                  style: TextStyle(
                    color: themeColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                onTap: () => _showAddItemSheet(group),
              ),
            ),
          ),
        ),
      ),
    );

    return Column(
      children: widgets,
    );
  }

  Widget _buildAnimatedIconButton({
    required VoidCallback onPressed,
    required IconData icon,
    required Color color,
    required String tooltip,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(ShoppingListItemModel item) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Card(
        elevation: 2,
        shadowColor: Colors.grey.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey.shade50,
              ],
            ),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                decoration:
                    item.isPurchased ? TextDecoration.lineThrough : null,
                color: item.isPurchased
                    ? Colors.grey.shade600
                    : Colors.grey.shade800,
              ),
              child: Text(item.itemName),
            ),
            subtitle: item.amount != null
                ? Text(
                    '${item.amount!.toInt()}円',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  )
                : null,
            leading: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Checkbox(
                value: item.isPurchased,
                onChanged: (value) async {
                  // チェック状態を更新
                  await ref
                      .read(shoppingListProvider.notifier)
                      .togglePurchaseStatusForGroup(
                        item.id,
                        value ?? false,
                        item.groupId,
                      );
                  // プロバイダーを無効化して再読み込み
                  ref.invalidate(groupItemsProvider(item.groupId));
                },
                activeColor: themeColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            trailing: _isEditMode
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildAnimatedIconButton(
                        onPressed: () => _showEditItemSheet(item),
                        icon: Icons.edit,
                        color: Colors.blue,
                        tooltip: '編集',
                      ),
                      _buildAnimatedIconButton(
                        onPressed: () => _showDeleteItemDialog(item),
                        icon: Icons.delete,
                        color: Colors.red,
                        tooltip: '削除',
                      ),
                    ],
                  )
                : null,
          ),
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
          ref.invalidate(groupItemsProvider(group.id));
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
        ref.invalidate(groupItemsProvider(item.groupId));
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
              ref.invalidate(groupItemsProvider(item.groupId));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }
}
