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

  // カテゴリーごとの合計を計算する関数（支出のみ）
  List<Map<String, dynamic>> _calculateCategoryTotals() {
    Map<String, double> categoryTotals = {};
    Map<String, String> categoryColors = {};

    for (var item in widget.data) {
      String genre = item['genre'] ?? '';
      double amount = double.tryParse(item['amount'] ?? '0') ?? 0;
      String color = item['color'] ?? '';
      String type = item['type'] ?? 'expense';

      // 支出のみを対象とする
      if (genre.isNotEmpty && type == 'expense') {
        categoryTotals[genre] = (categoryTotals[genre] ?? 0) + amount;
        if (color.isNotEmpty) {
          categoryColors[genre] = color;
        }
      }
    }

    // 合計金額で降順ソート
    var sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.map((entry) {
      return {
        'genre': entry.key,
        'amount': entry.value,
        'color': categoryColors[entry.key] ?? '',
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    // カテゴリーごとの合計を計算（支出のみ）
    List<Map<String, dynamic>> categoryData = _calculateCategoryTotals();

    // 支出の総合計を計算
    double totalExpense =
        categoryData.fold(0.0, (sum, item) => sum + (item['amount'] as double));

    // データが空の場合の表示
    if (categoryData.isEmpty) {
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
                    sections: categoryData.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final isTouched = index == touchedIndex;
                      double value = item['amount'] as double;
                      String genre = item['genre'] as String;

                      // 円グラフの割合計算には支出の総合計を使用
                      double percentage =
                          totalExpense > 0 ? (value / totalExpense * 100) : 0;

                      // カテゴリーの色を使用
                      Color sectionColor;
                      final categoryColor = item['color'] as String?;
                      if (categoryColor != null && categoryColor.isNotEmpty) {
                        try {
                          sectionColor = Color(int.parse(
                                  categoryColor.replaceFirst('#', ''),
                                  radix: 16))
                              .withOpacity(0.8);
                        } catch (e) {
                          sectionColor = getGenreColor(genre).withOpacity(0.8);
                        }
                      } else {
                        sectionColor = getGenreColor(genre).withOpacity(0.8);
                      }

                      // 表示用のタイトルを生成
                      String displayTitle = '';
                      if (percentage > 3) {
                        displayTitle =
                            '${genre}\n${percentage.toStringAsFixed(1)}%';
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
                          '支出合計',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          formatCurrency(totalExpense),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[600],
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
            '支出の割合',
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
            '今月の支出データはありません',
            style: TextStyle(fontSize: 16, color: secondaryTextColor),
          ),
        ],
      ),
    );
  }
}
