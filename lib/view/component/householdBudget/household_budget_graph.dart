import 'package:flutter/material.dart';
import 'package:outi_log/constant/genre.dart';
import 'package:outi_log/utils/format.dart';
import 'package:outi_log/view/component/householdBudget/graph/bar_chart.dart';
import 'package:outi_log/view/component/householdBudget/graph/circle_chart.dart';

class HouseholdBudgetGraph extends StatefulWidget {
  HouseholdBudgetGraph(
      {super.key, required this.data, required this.currentDate});
  final Map<String, List<Map<String, String>>> data;
  final DateTime currentDate;
  @override
  State<HouseholdBudgetGraph> createState() => _HouseholdBudgetGraphState();
}

class _HouseholdBudgetGraphState extends State<HouseholdBudgetGraph> {
  // 統一された凡例ウィジェット
  Widget _buildLegend() {
    double width = MediaQuery.of(context).size.width;
    Map<String, double> genreTotals = {};

    // 現在の月のデータからジャンルごとの合計を計算
    String currentMonth = formatMonth(widget.currentDate);
    List<Map<String, String>> currentData = widget.data[currentMonth] ?? [];

    currentData.forEach((item) {
      String genre = item['genre'] ?? '';
      double amount = double.tryParse(item['amount'] ?? '0') ?? 0;
      genreTotals[genre] = (genreTotals[genre] ?? 0) + amount;
    });

    return Container(
      width: width * 0.85,
      margin: EdgeInsets.symmetric(vertical: 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: genreTotals.entries.map((entry) {
          String genre = entry.key;
          double total = entry.value;
          double percentage =
              genreTotals.values.fold(0.0, (sum, amount) => sum + amount) > 0
                  ? (total /
                      genreTotals.values
                          .fold(0.0, (sum, amount) => sum + amount) *
                      100)
                  : 0;

          // カテゴリーの色を使用
          Color displayColor = getGenreColor(genre);

          // 同じジャンルの最初のアイテムから色情報を取得
          final genreItems =
              currentData.where((item) => item['genre'] == genre).toList();
          if (genreItems.isNotEmpty) {
            final categoryColor = genreItems.first['color'] ?? '';
            if (categoryColor.isNotEmpty) {
              try {
                displayColor = Color(
                    int.parse(categoryColor.replaceFirst('#', ''), radix: 16));
              } catch (e) {
                displayColor = getGenreColor(genre);
              }
            }
          }

          return Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: displayColor.withOpacity(0.1),
              border: Border.all(
                color: displayColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: displayColor,
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      genre,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  '${formatCurrency(total)}円 (${percentage.toStringAsFixed(1)}%)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.data.isEmpty
        ? Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(
                Icons.bar_chart,
                size: 80,
                color: Colors.blue,
              ),
              SizedBox(height: 20),
              Text(
                '収支グラフ',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                '収支の推移をグラフで確認できます',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ]),
          )
        : SingleChildScrollView(
            child: Column(
              children: [
                _buildLegend(),
                BarChartWidget(
                    data: widget.data[formatMonth(widget.currentDate)] ?? []),
                CircleChartWidget(
                    data: widget.data[formatMonth(widget.currentDate)] ?? []),
              ],
            ),
          );
  }
}
