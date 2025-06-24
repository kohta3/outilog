import 'package:flutter/material.dart';
import 'package:outi_log/constant/color.dart';
import 'package:outi_log/constant/genre.dart';
import 'package:outi_log/utils/format.dart';

class HouseholdBudgetList extends StatefulWidget {
  const HouseholdBudgetList(
      {super.key, required this.data, required this.currentDate});
  final Map<String, List<Map<String, String>>> data;
  final DateTime currentDate;

  @override
  State<HouseholdBudgetList> createState() => _HouseholdBudgetListState();
}

class _HouseholdBudgetListState extends State<HouseholdBudgetList> {
  late DateTime _currentDate;

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
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: getGenreColor(genre).withOpacity(0.1),
                              ),
                              child: Icon(
                                getGenreIcon(genre),
                                color: getGenreColor(genre),
                                size: 20,
                              ),
                            ),
                            title: Text(
                              genre,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            subtitle: Text(
                              '${formatMonthJp(_currentDate)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            trailing: Text(
                              '-${formatCurrency(amount)}円',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[600],
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
