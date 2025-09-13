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
                    child: _buildGroupedTransactionList(currentMonthData),
                  ),
                ],
              );
  }

  Widget _buildGroupedTransactionList(List<Map<String, String>> transactions) {
    // 日付ごとにグループ化
    Map<String, List<Map<String, String>>> groupedTransactions = {};

    for (final transaction in transactions) {
      final dateString = transaction['date'] ?? '';
      DateTime? transactionDate;

      if (dateString.isNotEmpty) {
        try {
          transactionDate = DateTime.parse(dateString);
        } catch (e) {
          print('Error parsing date: $e');
          continue;
        }
      } else {
        continue;
      }

      final dateKey =
          '${transactionDate.year}年${transactionDate.month}月${transactionDate.day}日';

      if (!groupedTransactions.containsKey(dateKey)) {
        groupedTransactions[dateKey] = [];
      }
      groupedTransactions[dateKey]!.add(transaction);
    }

    // 日付順でソート
    final sortedDates = groupedTransactions.keys.toList()
      ..sort((a, b) {
        final dateA = _parseDateFromKey(a);
        final dateB = _parseDateFromKey(b);
        return dateB.compareTo(dateA); // 新しい日付が上に来るように
      });

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: sortedDates.length * 2, // 日付ヘッダー + 取引リスト
      itemBuilder: (context, index) {
        if (index % 2 == 0) {
          // 日付ヘッダー
          final dateIndex = index ~/ 2;
          final dateKey = sortedDates[dateIndex];
          return _buildDateHeader(dateKey);
        } else {
          // 取引リスト
          final dateIndex = (index - 1) ~/ 2;
          final dateKey = sortedDates[dateIndex];
          final dayTransactions = groupedTransactions[dateKey]!;

          return Column(
            children: dayTransactions
                .map((transaction) => _buildTransactionItem(transaction))
                .toList(),
          );
        }
      },
    );
  }

  DateTime _parseDateFromKey(String dateKey) {
    // "20xx年xx月xx日" から DateTime を解析
    final regex = RegExp(r'(\d{4})年(\d{1,2})月(\d{1,2})日');
    final match = regex.firstMatch(dateKey);

    if (match != null) {
      final year = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final day = int.parse(match.group(3)!);
      return DateTime(year, month, day);
    }

    return DateTime.now();
  }

  Widget _buildDateHeader(String dateKey) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple[50]!, Colors.pink[50]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.1),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Colors.purple[400],
                  size: 16,
                ),
                SizedBox(width: 6),
                Text(
                  dateKey,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[700],
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, String> item) {
    final genre = item['genre'] ?? '';
    final amount = double.tryParse(item['amount'] ?? '0') ?? 0;
    final type = item['type'] ?? 'expense';
    final storeName = item['storeName'] ?? '';
    final description = item['description'] ?? '';

    // 収入と支出で表示を分ける
    final isIncome = type == 'income';
    final displayAmount = isIncome
        ? '+${formatCurrency(amount)}円'
        : '-${formatCurrency(amount)}円';
    final amountColor = isIncome ? Colors.green[600]! : Colors.red[600]!;

    // カテゴリーの色を使用
    Color displayColor;
    if (isIncome) {
      displayColor = Colors.green;
    } else {
      final categoryColor = item['color'] ?? '#2196F3';
      try {
        displayColor =
            Color(int.parse(categoryColor.replaceFirst('#', ''), radix: 16));
      } catch (e) {
        displayColor = getGenreColor(genre);
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
          BoxShadow(
            color: displayColor.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: displayColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showTransactionOptions(context, item),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // カテゴリー名と金額
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: displayColor,
                        boxShadow: [
                          BoxShadow(
                            color: displayColor.withOpacity(0.3),
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isIncome ? '収入' : genre,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: amountColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: amountColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        displayAmount,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: amountColor,
                        ),
                      ),
                    ),
                  ],
                ),

                // 店舗名
                if (storeName.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.orange[200]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.store,
                          size: 14,
                          color: Colors.orange[600],
                        ),
                        SizedBox(width: 4),
                        Text(
                          storeName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // メモ
                if (description.isNotEmpty) ...[
                  SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.note_alt_outlined,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            description,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
