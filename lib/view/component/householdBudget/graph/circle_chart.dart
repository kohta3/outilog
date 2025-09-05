import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:outi_log/constant/color.dart';
import 'package:outi_log/constant/genre.dart';
import 'package:outi_log/utils/format.dart';

class CircleChartWidget extends StatefulWidget {
  CircleChartWidget({super.key, required this.data});

  final List<Map<String, String>> data;

  @override
  State<CircleChartWidget> createState() => _CircleChartWidgetState();
}

class _CircleChartWidgetState extends State<CircleChartWidget> {
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    // 収入と支出を分けて計算
    double incomeTotal = 0.0;
    double expenseTotal = 0.0;

    for (final item in widget.data) {
      final amount = double.parse(item['amount'] ?? '0');
      final type = item['type'] ?? 'expense';

      if (type == 'income') {
        incomeTotal += amount;
      } else {
        expenseTotal += amount;
      }
    }

    // 純利益（収入 - 支出）を計算
    double netIncome = incomeTotal - expenseTotal;

    // データが空の場合の表示
    if (widget.data.isEmpty) {
      return Column(
        children: [
          _buildHeader(),
          Container(
            width: width * 0.95,
            height: width * 0.85,
            decoration: _buildContainerDecoration(),
            child: _buildNoDataWidget(),
          ),
          SizedBox(height: 16),
        ],
      );
    }

    return Column(
      children: [
        _buildHeader(),
        Container(
          width: width * 0.95,
          height: width * 0.85,
          decoration: _buildContainerDecoration(),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (pieTouchResponse?.touchedSection != null) {
                            touchedIndex = pieTouchResponse!
                                .touchedSection!.touchedSectionIndex;
                          } else {
                            touchedIndex = null;
                          }
                        });
                      },
                      mouseCursorResolver: (event, response) {
                        return response == null ||
                                response.touchedSection == null
                            ? SystemMouseCursors.basic
                            : SystemMouseCursors.click;
                      },
                    ),
                    sections: widget.data.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final isTouched = index == touchedIndex;
                      double value = double.parse(item['amount'] ?? '0');
                      // 円グラフの割合計算には総合計を使用
                      double totalForPercentage = incomeTotal + expenseTotal;
                      double percentage = totalForPercentage > 0
                          ? (value / totalForPercentage * 100)
                          : 0;
                      final type = item['type'] ?? 'expense';

                      // 収入と支出で色を分ける
                      Color sectionColor;
                      if (type == 'income') {
                        sectionColor = Colors.green.withOpacity(0.8);
                      } else {
                        // カテゴリーの色を使用
                        final categoryColor = item['color'] ?? '#2196F3';
                        try {
                          sectionColor = Color(int.parse(
                                  categoryColor.replaceFirst('#', ''),
                                  radix: 16))
                              .withOpacity(0.8);
                        } catch (e) {
                          sectionColor = getGenreColor(item['genre'] ?? '')
                              .withOpacity(0.8);
                        }
                      }

                      // 表示用のタイトルを生成
                      String displayTitle = '';
                      if (percentage > 3) {
                        if (type == 'income') {
                          displayTitle =
                              '収入\n${percentage.toStringAsFixed(1)}%';
                        } else {
                          displayTitle =
                              '${item['genre']}\n${percentage.toStringAsFixed(1)}%';
                        }
                      }

                      return PieChartSectionData(
                        value: value,
                        title: displayTitle,
                        color: sectionColor,
                        radius: isTouched ? width * 0.22 : width * 0.18,
                        titleStyle: TextStyle(
                          fontSize: percentage > 8 ? 12 : 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                    centerSpaceRadius: width * 0.15,
                    sectionsSpace: 1,
                  ),
                ),
                // 中央の合計表示
                Center(
                  child: Container(
                    width: width * 0.3,
                    height: width * 0.3,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[50],
                      border: Border.all(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '収支',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          formatCurrency(netIncome),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: netIncome >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                        Text(
                          '円',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(
            Icons.pie_chart,
            color: themeColor,
            size: 24,
          ),
          SizedBox(width: 8),
          Text(
            '収支の割合',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _buildContainerDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 15,
          offset: Offset(0, 5),
        ),
      ],
    );
  }

  Widget _buildNoDataWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.data_usage_outlined,
            size: 64,
            color: Colors.grey[300],
          ),
          SizedBox(height: 16),
          Text(
            '今月の収支データはありません',
            style: TextStyle(fontSize: 16, color: secondaryTextColor),
          ),
        ],
      ),
    );
  }
}
