import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:outi_log/constant/color.dart';
import 'package:outi_log/constant/genre.dart';
import 'package:outi_log/utils/format.dart';

class BarChartWidget extends StatelessWidget {
  const BarChartWidget({super.key, required this.data});

  final List<Map<String, String>> data;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    // データから最大値を計算
    double maxAmount = 0;
    if (data.isNotEmpty) {
      maxAmount = data
          .map((item) => double.tryParse(item['amount'] ?? '0') ?? 0)
          .reduce((a, b) => a > b ? a : b);
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            children: [
              Icon(
                Icons.bar_chart,
                color: themeColor,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                '各支出の合計',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
        Container(
          width: width * 0.95,
          height: 280,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: data.isNotEmpty
                ? Row(
                    children: [
                      // 固定のY軸
                      SizedBox(
                        width: 50,
                        height: 248,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(5, (index) {
                            double value = maxAmount > 0
                                ? (maxAmount * 1.2 / 4) * (4 - index).toDouble()
                                : 20.0 * (4 - index).toDouble();
                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                '${formatCurrency(value)}円',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.right,
                              ),
                            );
                          }),
                        ),
                      ),
                      // スクロール可能なチャート部分
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: data.length > 4
                                ? data.length * 80.0
                                : width * 0.85 - 82,
                            height: 248,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: maxAmount > 0 ? maxAmount * 1.2 : 100,
                                minY: 0,
                                barTouchData: BarTouchData(
                                  touchTooltipData: BarTouchTooltipData(
                                    getTooltipColor: (barData) => Colors.white,
                                    getTooltipItem:
                                        (group, groupIndex, rod, rodIndex) {
                                      return BarTooltipItem(
                                        '${data[group.x]['genre']}\n${formatCurrency(double.parse(data[group.x]['amount'] ?? '0'))}円',
                                        TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 40,
                                      getTitlesWidget: (value, meta) {
                                        if (value.toInt() >= 0 &&
                                            value.toInt() < data.length) {
                                          return Padding(
                                            padding: EdgeInsets.only(top: 8),
                                            child: Text(
                                              data[value.toInt()]['genre'] ??
                                                  '',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.grey[700],
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          );
                                        }
                                        return Text('');
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                borderData: FlBorderData(
                                  show: false,
                                ),
                                gridData: FlGridData(
                                  show: true,
                                  horizontalInterval:
                                      maxAmount > 0 ? maxAmount / 4 : 20,
                                  drawVerticalLine: false,
                                  getDrawingHorizontalLine: (value) {
                                    return FlLine(
                                      color: Colors.grey[100],
                                      strokeWidth: 1,
                                    );
                                  },
                                ),
                                barGroups: data.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final item = entry.value;
                                  final amount =
                                      double.tryParse(item['amount'] ?? '0') ??
                                          0;

                                  return BarChartGroupData(
                                    x: index,
                                    barRods: [
                                      BarChartRodData(
                                        toY: amount,
                                        color:
                                            getGenreColor(item['genre'] ?? '')
                                                .withOpacity(0.8),
                                        width: 24,
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(4),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bar_chart,
                          size: 60,
                          color: Colors.grey[300],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'データがありません',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
