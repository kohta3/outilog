import 'package:flutter/material.dart';
import 'package:outi_log/constant/genre.dart';
import 'package:outi_log/utils/format.dart';
import 'package:outi_log/infrastructure/transaction_firestore_infrastructure.dart';
import 'package:outi_log/utils/toast.dart';
import 'package:outi_log/view/component/householdBudget/edit_transaction_bottom_sheet.dart';
import 'package:outi_log/provider/auth_provider.dart';
import 'package:outi_log/provider/firestore_space_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HouseholdBudgetList extends ConsumerStatefulWidget {
  const HouseholdBudgetList({
    super.key,
    required this.data,
    required this.currentDate,
    this.onDataChanged,
  });
  final Map<String, List<Map<String, String>>> data;
  final DateTime currentDate;
  final VoidCallback? onDataChanged; // データ変更時のコールバック

  @override
  ConsumerState<HouseholdBudgetList> createState() =>
      _HouseholdBudgetListState();
}

class _HouseholdBudgetListState extends ConsumerState<HouseholdBudgetList> {
  late DateTime _currentDate;
  final TransactionFirestoreInfrastructure _transactionInfrastructure =
      TransactionFirestoreInfrastructure();

  @override
  void initState() {
    super.initState();
    _currentDate = widget.currentDate;
  }

  @override
  void didUpdateWidget(HouseholdBudgetList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentDate != widget.currentDate) {
      setState(() {
        _currentDate = widget.currentDate;
      });
    }
  }

  void _showTransactionOptions(BuildContext context, Map<String, String> item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '取引を選択',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  context,
                  icon: Icons.edit,
                  label: '編集',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _editTransaction(context, item);
                  },
                ),
                _buildActionButton(
                  context,
                  icon: Icons.delete,
                  label: '削除',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    _deleteTransaction(context, item);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editTransaction(BuildContext context, Map<String, String> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return EditTransactionBottomSheet(
          transactionData: item,
          onDataChanged: widget.onDataChanged,
        );
      },
    );
  }

  void _deleteTransaction(BuildContext context, Map<String, String> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除確認'),
        content: const Text('この取引を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performDelete(item);
            },
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _performDelete(Map<String, String> item) async {
    try {
      final transactionId = item['id'] ?? '';
      if (transactionId.isEmpty) {
        Toast.show(context, '取引IDが見つかりません');
        return;
      }

      final currentUser = ref.read(currentUserProvider);
      final spaceState = ref.read(firestoreSpacesProvider);
      final currentSpace = spaceState?.currentSpace;

      if (currentUser == null || currentSpace == null) {
        Toast.show(context, 'ユーザーまたはスペース情報が見つかりません');
        return;
      }

      await _transactionInfrastructure.deleteTransaction(
        transactionId: transactionId,
        spaceId: currentSpace.id,
        userId: currentUser.uid,
      );
      Toast.show(context, '取引を削除しました');

      // 親ウィジェットに削除完了を通知
      if (mounted && widget.onDataChanged != null) {
        widget.onDataChanged!();
      }
    } catch (e) {
      Toast.show(context, '削除に失敗しました: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 特定の月のデータを取得
    final currentMonthData = widget.data[formatMonth(_currentDate)] ?? [];

    return widget.data.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.list,
                  size: 80,
                  color: Colors.orange,
                ),
                SizedBox(height: 20),
                Text(
                  '取引履歴',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  '過去の収支記録をリストで確認できます',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          )
        : currentMonthData.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 80,
                      color: Colors.grey[300],
                    ),
                    SizedBox(height: 20),
                    Text(
                      '${formatMonthJp(_currentDate)}のデータがありません',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'この月の収支記録を追加してください',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  // 月選択ヘッダー

                  // リスト表示
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: currentMonthData.length,
                      itemBuilder: (context, index) {
                        final item = currentMonthData[index];
                        final genre = item['genre'] ?? '';
                        final amount =
                            double.tryParse(item['amount'] ?? '0') ?? 0;
                        final type = item['type'] ?? 'expense';
                        final dateString = item['date'] ?? '';
                        final title = item['title'] ?? '';

                        // 日付をパース
                        DateTime? transactionDate;
                        if (dateString.isNotEmpty) {
                          try {
                            transactionDate = DateTime.parse(dateString);
                          } catch (e) {
                            print('Error parsing date: $e');
                          }
                        }

                        // 収入と支出で表示を分ける
                        final isIncome = type == 'income';
                        final displayAmount = isIncome
                            ? '+${formatCurrency(amount)}円'
                            : '-${formatCurrency(amount)}円';
                        final amountColor =
                            isIncome ? Colors.green[600] : Colors.red[600];

                        // カテゴリーの色を使用
                        Color displayColor;
                        if (isIncome) {
                          displayColor = Colors.green;
                        } else {
                          final categoryColor = item['color'] ?? '#2196F3';
                          try {
                            displayColor = Color(int.parse(
                                categoryColor.replaceFirst('#', ''),
                                radix: 16));
                          } catch (e) {
                            displayColor = getGenreColor(genre);
                          }
                        }

                        final iconColor = displayColor;
                        final backgroundColor = displayColor.withOpacity(0.1);
                        final icon =
                            isIncome ? Icons.trending_up : getGenreIcon(genre);

                        return Container(
                          margin: EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            onTap: () => _showTransactionOptions(context, item),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: backgroundColor,
                              ),
                              child: Icon(
                                icon,
                                color: iconColor,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              title.isNotEmpty
                                  ? title
                                  : (isIncome ? '収入' : genre),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isIncome ? '収入' : genre,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  transactionDate != null
                                      ? '${transactionDate.month}/${transactionDate.day}'
                                      : '${formatMonthJp(_currentDate)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                            trailing: Text(
                              displayAmount,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: amountColor,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
  }
}
