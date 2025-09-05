import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outi_log/constant/color.dart';
import 'package:outi_log/provider/firestore_space_provider.dart';
import 'package:outi_log/provider/space_prodiver.dart';
import 'package:outi_log/provider/schedule_firestore_provider.dart';
import 'package:outi_log/provider/auth_provider.dart';
import 'package:outi_log/infrastructure/transaction_firestore_infrastructure.dart';
import 'package:outi_log/view/space_add_screen.dart';
import 'package:outi_log/utils/format.dart';
import 'package:outi_log/models/space_model.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final TransactionFirestoreInfrastructure _transactionInfrastructure =
      TransactionFirestoreInfrastructure();

  Map<String, double> _monthlySummary = {};
  List<Map<String, dynamic>> _sixMonthData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();

    // スケジュールの初期化を追加
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSchedules();
    });
  }

  Future<void> _loadDashboardData() async {
    final currentSpace = ref.read(firestoreSpacesProvider)?.currentSpace;
    if (currentSpace == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // 月間収支を取得
      final now = DateTime.now();
      Map<String, double> monthlySummary = {};
      try {
        monthlySummary = await _transactionInfrastructure.getMonthlySummary(
          spaceId: currentSpace.id,
          year: now.year,
          month: now.month,
        );
      } catch (e) {
        print('Warning: Could not load monthly summary: $e');
        // 月間収支データの取得に失敗しても続行
      }

      // 6カ月のデータを取得
      List<Map<String, dynamic>> sixMonthData = [];
      try {
        sixMonthData = await _loadSixMonthData(currentSpace.id, now);
      } catch (e) {
        print('Warning: Could not load six month data: $e');
        // 6カ月データの取得に失敗しても続行
      }

      setState(() {
        _monthlySummary = monthlySummary;
        _sixMonthData = sixMonthData;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// スケジュールの初期化処理
  Future<void> _initializeSchedules() async {
    try {
      // スペースとユーザーが利用可能になるまで待機
      final currentSpace = ref.read(firestoreSpacesProvider)?.currentSpace;
      final currentUser = ref.read(currentUserProvider);

      if (currentSpace != null && currentUser != null) {
        print('DEBUG: Initializing schedules for dashboard');
        await ref.read(scheduleFirestoreProvider.notifier).reloadSchedules();
      }
    } catch (e) {
      print('DEBUG: Error initializing schedules: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Firestoreスペースを優先的に使用
    final firestoreSpaces = ref.watch(firestoreSpacesProvider);
    final localSpaces = ref.watch(spacesProvider);

    // Firestoreにスペースがある場合はそちらを使用、なければローカルを使用
    final spaces = firestoreSpaces ?? localSpaces;
    final currentSpace = spaces?.currentSpace;

    return Scaffold(
      body: currentSpace != null
          ? _buildDashboardContent(context, ref, currentSpace)
          : _buildNoSpaceView(context),
    );
  }

  Widget _buildDashboardContent(
      BuildContext context, WidgetRef ref, SpaceModel currentSpace) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー画像セクション
          _buildHeaderImageSection(currentSpace),
          const SizedBox(height: 24),

          // 今日の予定セクション
          _buildTodayScheduleSection(ref),
          const SizedBox(height: 24),

          // 月間収支グラフセクション
          _buildMonthlySummarySection(),
        ],
      ),
    );
  }

  // 月間収支グラフセクション
  Widget _buildMonthlySummarySection() {
    final income = _monthlySummary['income'] ?? 0.0;
    final expense = _monthlySummary['expense'] ?? 0.0;
    final balance = _monthlySummary['balance'] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.account_balance_wallet,
              color: themeColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              '6カ月の収支比較',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // 収支サマリー
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem('収入', income, Colors.green),
                    _buildSummaryItem('支出', expense, Colors.red),
                    _buildSummaryItem(
                        '収支', balance, balance >= 0 ? Colors.blue : Colors.red),
                  ],
                ),
                const SizedBox(height: 16),
                // 6カ月比較グラフ
                _buildSixMonthChart(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '¥${formatCurrency(amount)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSixMonthChart() {
    if (_sixMonthData.isEmpty) {
      return const Center(
        child: Text(
          'データがありません',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      );
    }

    // 最大値を計算（グラフのスケール用）
    double maxValue = 0;
    for (var data in _sixMonthData) {
      final income = data['income'] as double;
      final expense = data['expense'] as double;
      maxValue = [maxValue, income, expense].reduce((a, b) => a > b ? a : b);
    }

    // 最大値を最小値1に設定してゼロ除算を防ぐ
    if (maxValue == 0) maxValue = 1;

    return Column(
      children: [
        // グラフエリア
        Container(
          height: 200,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _sixMonthData.map((data) {
              final income = data['income'] as double;
              final expense = data['expense'] as double;
              final balance = data['balance'] as double;
              final monthName = data['monthName'] as String;

              // 収入と支出の合計を計算
              double totalAmount = income + expense;

              // 各棒の高さを計算（合計が100を超えないように調整）
              double incomeHeight =
                  totalAmount > 0 ? (income / maxValue) * 100 : 0;
              double expenseHeight =
                  totalAmount > 0 ? (expense / maxValue) * 100 : 0;

              // 合計が100を超える場合は比例配分
              if (incomeHeight + expenseHeight > 100) {
                double ratio = 100 / (incomeHeight + expenseHeight);
                incomeHeight *= ratio;
                expenseHeight *= ratio;
              }

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      // 積み上げ棒グラフ（収入・支出）
                      Expanded(
                        child: Center(
                          child: ClipRect(
                            child: Container(
                              width: 30,
                              height: 120,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // 支出の棒（上）
                                  if (expense > 0)
                                    Container(
                                      width: 30,
                                      height: expenseHeight.clamp(0.0, 100.0),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.7),
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(4),
                                          topRight: Radius.circular(4),
                                        ),
                                      ),
                                    ),
                                  // 収入の棒（下）
                                  if (income > 0)
                                    Container(
                                      width: 30,
                                      height: incomeHeight.clamp(0.0, 100.0),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.7),
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(4),
                                          topRight: const Radius.circular(4),
                                          bottomLeft: expense > 0
                                              ? Radius.zero
                                              : const Radius.circular(4),
                                          bottomRight: expense > 0
                                              ? Radius.zero
                                              : const Radius.circular(4),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // 折れ線グラフの点（収支）
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: balance >= 0 ? Colors.blue : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // 月名
                      Text(
                        monthName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        // 凡例
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegendItem('収入（下）', Colors.green),
            _buildLegendItem('支出（上）', Colors.red),
            _buildLegendItem('収支', Colors.blue),
          ],
        ),
        const SizedBox(height: 8),
        // 数値表示
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: _sixMonthData.map((data) {
              final monthName = data['monthName'] as String;
              final income = data['income'] as double;
              final expense = data['expense'] as double;
              final balance = data['balance'] as double;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      monthName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '収:¥${formatCurrency(income)}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '支:¥${formatCurrency(expense)}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '¥${formatCurrency(balance)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: balance >= 0 ? Colors.blue : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  /// ヘッダー画像セクションを構築
  Widget _buildHeaderImageSection(SpaceModel currentSpace) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: currentSpace.headerImageUrl != null &&
                currentSpace.headerImageUrl!.isNotEmpty
            ? Stack(
                children: [
                  // ヘッダー画像
                  Image.network(
                    currentSpace.headerImageUrl!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildDefaultHeader(currentSpace.spaceName);
                    },
                  ),
                  // グラデーションオーバーレイ
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // スペース名
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Text(
                      currentSpace.spaceName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: Offset(1, 1),
                            blurRadius: 3,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : _buildDefaultHeader(currentSpace.spaceName),
      ),
    );
  }

  /// デフォルトヘッダーを構築
  Widget _buildDefaultHeader(String spaceName) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [themeColor, themeColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home,
              size: 48,
              color: Colors.white.withOpacity(0.8),
            ),
            const SizedBox(height: 12),
            Text(
              spaceName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 今日の予定セクション
  Widget _buildTodayScheduleSection(WidgetRef ref) {
    final todaySchedules =
        ref.watch(scheduleFirestoreProvider.notifier).todaySchedules;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: themeColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              '今日の予定',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Container(
            padding: const EdgeInsets.all(4.0),
            child: todaySchedules.isEmpty
                ? const Center(
                    child: Text(
                      '今日の予定はありません',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  )
                : _buildTimelineView(todaySchedules),
          ),
        ),
      ],
    );
  }

  // タイムライン表示を構築（改善版）
  Widget _buildTimelineView(List<dynamic> schedules) {
    // 終日予定と時間指定予定を分ける
    final allDaySchedules = schedules.where((s) => s.isAllDay).toList();
    final timedSchedules = schedules.where((s) => !s.isAllDay).toList();

    // 予定が多い場合はリスト表示も提供
    final totalSchedules = allDaySchedules.length + timedSchedules.length;

    return Column(
      children: [
        // 表示切り替えボタン（予定が多い場合のみ表示）
        if (totalSchedules > 6) _buildViewToggleButtons(),
        const SizedBox(height: 8),
        // 統合タイムテーブル（終日予定 + 時間指定予定）
        _buildIntegratedTimeTable(allDaySchedules, timedSchedules),
      ],
    );
  }

  // 表示切り替えボタンを構築
  Widget _buildViewToggleButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                // タイムライン表示（現在の表示）
                // 何もしない（既にタイムライン表示）
              },
              icon: const Icon(Icons.timeline, size: 16),
              label: const Text('タイムライン'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[100],
                foregroundColor: Colors.blue[700],
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                // リスト表示に切り替え（将来の実装）
                // TODO: リスト表示の実装
              },
              icon: const Icon(Icons.list, size: 16),
              label: const Text('リスト'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[600],
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 統合タイムテーブル表示（終日予定 + 時間指定予定）
  Widget _buildIntegratedTimeTable(
      List<dynamic> allDaySchedules, List<dynamic> timedSchedules) {
    // データが空の場合はデフォルト表示
    if (allDaySchedules.isEmpty && timedSchedules.isEmpty) {
      return const Center(
        child: Text(
          '今日の予定がありません',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
      );
    }

    // 時間指定予定を時間順にソート
    timedSchedules.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

    // 日をまたぐ予定があるかチェック
    final hasMultiDaySchedules = timedSchedules.any((schedule) {
      final startDate = DateTime(
        schedule.startDateTime.year,
        schedule.startDateTime.month,
        schedule.startDateTime.day,
      );
      final endDate = DateTime(
        schedule.endDateTime.year,
        schedule.endDateTime.month,
        schedule.endDateTime.day,
      );
      return !startDate.isAtSameMomentAs(endDate);
    });

    int safeStartHour, safeEndHour, totalHours;

    if (hasMultiDaySchedules) {
      // 日をまたぐ予定がある場合は24時間表示
      safeStartHour = 0;
      safeEndHour = 24;
      totalHours = 24;
    } else if (timedSchedules.isNotEmpty) {
      // 通常の予定の場合
      final today = DateTime.now();
      final todayStartOfDay =
          DateTime(today.year, today.month, today.day, 0, 0, 0);
      final todayEndOfDay =
          DateTime(today.year, today.month, today.day, 23, 59, 59);

      int minHour = 24;
      int maxHour = 0;

      for (final schedule in timedSchedules) {
        // 今日の範囲内での有効な時間を計算
        int scheduleStartHour = schedule.startDateTime.isBefore(todayStartOfDay)
            ? 0
            : schedule.startDateTime.hour;
        int scheduleEndHour = schedule.endDateTime.isAfter(todayEndOfDay)
            ? 24
            : schedule.endDateTime.hour +
                (schedule.endDateTime.minute > 0 ? 1 : 0);

        minHour = min(minHour, scheduleStartHour);
        maxHour = max(maxHour, scheduleEndHour);
      }

      // 最小6時間、最大24時間の範囲を確保
      final calculatedStartHour = (minHour - 1).clamp(0, 23);
      final calculatedEndHour = (maxHour + 1).clamp(6, 24);

      safeStartHour = calculatedStartHour;
      safeEndHour = calculatedEndHour;
      totalHours = safeEndHour - safeStartHour;
    } else {
      // 終日予定のみの場合
      safeStartHour = 0;
      safeEndHour = 24;
      totalHours = 24;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        // タイムテーブル（改善版）
        Container(
          constraints: BoxConstraints(
            minHeight: 100,
            maxHeight: 300, // 最大高さを制限
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: [
                // スクロール可能なタイムテーブル
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SizedBox(
                        width: totalHours * 100.0 + 80, // 時間あたり100px + 余白
                        height: 50 +
                            (allDaySchedules.length * 40) + // 終日予定の高さを少し増やす
                            (_calculateMaxLanes(timedSchedules) *
                                40) + // 時間指定予定のレーン高さを少し増やす
                            20, // 下部の余白を増やす
                        child: Stack(
                          children: [
                            // 横向き時間軸
                            _buildHorizontalTimeAxis(
                                safeStartHour, safeEndHour),
                            // 終日予定バー
                            ...allDaySchedules.asMap().entries.map((entry) {
                              final index = entry.key;
                              final schedule = entry.value;
                              return _buildAllDayBar(
                                  schedule, index, totalHours);
                            }),
                            // 横向き予定バー
                            ..._buildNonOverlappingScheduleBars(
                                timedSchedules, safeStartHour),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // // 終日予定セクション（旧版）
  // Widget _buildAllDaySection(List<dynamic> allDaySchedules) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Container(
  //         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  //         decoration: BoxDecoration(
  //           color: Colors.blue[50],
  //           borderRadius: BorderRadius.circular(8),
  //           border: Border.all(color: Colors.blue[200]!, width: 1),
  //         ),
  //         child: Row(
  //           children: [
  //             Icon(
  //               Icons.event_available,
  //               color: Colors.blue[600],
  //               size: 18,
  //             ),
  //             const SizedBox(width: 8),
  //             Text(
  //               '終日予定',
  //               style: TextStyle(
  //                 fontSize: 14,
  //                 fontWeight: FontWeight.w600,
  //                 color: Colors.blue[600],
  //               ),
  //             ),
  //             const Spacer(),
  //             Container(
  //               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
  //               decoration: BoxDecoration(
  //                 color: Colors.blue[100],
  //                 borderRadius: BorderRadius.circular(12),
  //               ),
  //               child: Text(
  //                 '${allDaySchedules.length}件',
  //                 style: TextStyle(
  //                   fontSize: 12,
  //                   fontWeight: FontWeight.w500,
  //                   color: Colors.blue[700],
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //       const SizedBox(height: 12),
  //       ...allDaySchedules
  //           .map((schedule) => _buildEnhancedAllDayItem(schedule)),
  //     ],
  //   );
  // }

  // // 改善された終日予定アイテム
  // Widget _buildEnhancedAllDayItem(dynamic schedule) {
  //   final title = schedule.title ?? 'タイトルなし';
  //   final memo = schedule.memo ?? '';
  //   final color = _getScheduleColor(schedule);

  //   return Container(
  //     margin: const EdgeInsets.only(bottom: 10),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(12),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.grey.withOpacity(0.1),
  //           blurRadius: 8,
  //           offset: const Offset(0, 2),
  //         ),
  //       ],
  //       border: Border.all(
  //         color: color.withOpacity(0.2),
  //         width: 1,
  //       ),
  //     ),
  //     child: Padding(
  //       padding: const EdgeInsets.all(16),
  //       child: Row(
  //         children: [
  //           Container(
  //             width: 6,
  //             height: 40,
  //             decoration: BoxDecoration(
  //               color: color,
  //               borderRadius: BorderRadius.circular(3),
  //             ),
  //           ),
  //           const SizedBox(width: 16),
  //           Expanded(
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Row(
  //                   children: [
  //                     Icon(
  //                       Icons.event_available,
  //                       size: 16,
  //                       color: color,
  //                     ),
  //                     const SizedBox(width: 6),
  //                     Text(
  //                       '終日',
  //                       style: TextStyle(
  //                         fontSize: 12,
  //                         fontWeight: FontWeight.w500,
  //                         color: color,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //                 const SizedBox(height: 8),
  //                 Text(
  //                   title,
  //                   style: const TextStyle(
  //                     fontSize: 16,
  //                     fontWeight: FontWeight.w600,
  //                     color: Colors.black87,
  //                   ),
  //                 ),
  //                 if (memo.isNotEmpty) ...[
  //                   const SizedBox(height: 6),
  //                   Text(
  //                     memo,
  //                     style: TextStyle(
  //                       fontSize: 13,
  //                       color: Colors.grey[600],
  //                       height: 1.3,
  //                     ),
  //                   ),
  //                 ],
  //               ],
  //             ),
  //           ),
  //           Container(
  //             padding: const EdgeInsets.all(8),
  //             decoration: BoxDecoration(
  //               color: color.withOpacity(0.1),
  //               borderRadius: BorderRadius.circular(8),
  //             ),
  //             child: Icon(
  //               Icons.calendar_today,
  //               size: 20,
  //               color: color,
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // // 改善されたタイムテーブル表示
  // Widget _buildEnhancedTimeTable(List<dynamic> timedSchedules) {
  //   // データが空の場合はデフォルト表示
  //   if (timedSchedules.isEmpty) {
  //     return const Center(
  //       child: Text(
  //         '時間指定の予定がありません',
  //         style: TextStyle(
  //           color: Colors.grey,
  //           fontSize: 14,
  //         ),
  //       ),
  //     );
  //   }

  //   // 時間順にソート
  //   timedSchedules.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

  //   // 日をまたぐ予定があるかチェック
  //   final hasMultiDaySchedules = timedSchedules.any((schedule) {
  //     final startDate = DateTime(
  //       schedule.startDateTime.year,
  //       schedule.startDateTime.month,
  //       schedule.startDateTime.day,
  //     );
  //     final endDate = DateTime(
  //       schedule.endDateTime.year,
  //       schedule.endDateTime.month,
  //       schedule.endDateTime.day,
  //     );
  //     return !startDate.isAtSameMomentAs(endDate);
  //   });

  //   int safeStartHour, safeEndHour, totalHours;

  //   if (hasMultiDaySchedules) {
  //     // 日をまたぐ予定がある場合は24時間表示
  //     safeStartHour = 0;
  //     safeEndHour = 24;
  //     totalHours = 24;
  //   } else {
  //     // 通常の予定の場合
  //     final today = DateTime.now();
  //     final todayStartOfDay =
  //         DateTime(today.year, today.month, today.day, 0, 0, 0);
  //     final todayEndOfDay =
  //         DateTime(today.year, today.month, today.day, 23, 59, 59);

  //     int minHour = 24;
  //     int maxHour = 0;

  //     for (final schedule in timedSchedules) {
  //       // 今日の範囲内での有効な時間を計算
  //       int scheduleStartHour = schedule.startDateTime.isBefore(todayStartOfDay)
  //           ? 0
  //           : schedule.startDateTime.hour;
  //       int scheduleEndHour = schedule.endDateTime.isAfter(todayEndOfDay)
  //           ? 24
  //           : schedule.endDateTime.hour +
  //               (schedule.endDateTime.minute > 0 ? 1 : 0);

  //       minHour = min(minHour, scheduleStartHour);
  //       maxHour = max(maxHour, scheduleEndHour);
  //     }

  //     // 最小6時間、最大24時間の範囲を確保
  //     final calculatedStartHour = (minHour - 1).clamp(0, 23);
  //     final calculatedEndHour = (maxHour + 1).clamp(6, 24);

  //     safeStartHour = calculatedStartHour;
  //     safeEndHour = calculatedEndHour;
  //     totalHours = safeEndHour - safeStartHour;
  //   }

  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Container(
  //         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  //         decoration: BoxDecoration(
  //           color: Colors.green[50],
  //           borderRadius: BorderRadius.circular(8),
  //           border: Border.all(color: Colors.green[200]!, width: 1),
  //         ),
  //         child: Row(
  //           children: [
  //             Icon(
  //               Icons.access_time,
  //               color: Colors.green[600],
  //               size: 18,
  //             ),
  //             const SizedBox(width: 8),
  //             Text(
  //               '時間指定予定',
  //               style: TextStyle(
  //                 fontSize: 14,
  //                 fontWeight: FontWeight.w600,
  //                 color: Colors.green[600],
  //               ),
  //             ),
  //             const Spacer(),
  //             Container(
  //               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
  //               decoration: BoxDecoration(
  //                 color: Colors.green[100],
  //                 borderRadius: BorderRadius.circular(12),
  //               ),
  //               child: Text(
  //                 '${timedSchedules.length}件',
  //                 style: TextStyle(
  //                   fontSize: 12,
  //                   fontWeight: FontWeight.w500,
  //                   color: Colors.green[700],
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //       const SizedBox(height: 12),
  //       Container(
  //         height: 200,
  //         decoration: BoxDecoration(
  //           color: Colors.white,
  //           borderRadius: BorderRadius.circular(12),
  //           boxShadow: [
  //             BoxShadow(
  //               color: Colors.grey.withOpacity(0.1),
  //               blurRadius: 8,
  //               offset: const Offset(0, 2),
  //             ),
  //           ],
  //         ),
  //         child: ClipRRect(
  //           borderRadius: BorderRadius.circular(12),
  //           child: SingleChildScrollView(
  //             scrollDirection: Axis.horizontal,
  //             child: SizedBox(
  //               width: totalHours * 100.0 + 80, // 時間あたり100px + 余白
  //               height: 200,
  //               child: Stack(
  //                 children: [
  //                   // 横向き時間軸
  //                   _buildHorizontalTimeAxis(safeStartHour, safeEndHour),
  //                   // 横向き予定バー
  //                   ...timedSchedules.map((schedule) =>
  //                       _buildHorizontalScheduleBar(schedule, safeStartHour)),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  // // タイムテーブル表示（旧版）
  // Widget _buildTimeTable(List<dynamic> timedSchedules) {
  //   // データが空の場合はデフォルト表示
  //   if (timedSchedules.isEmpty) {
  //     return const Center(
  //       child: Text(
  //         '時間指定の予定がありません',
  //         style: TextStyle(
  //           color: Colors.grey,
  //           fontSize: 14,
  //         ),
  //       ),
  //     );
  //   }

  //   // 時間順にソート
  //   timedSchedules.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

  //   // 日をまたぐ予定があるかチェック
  //   final hasMultiDaySchedules = timedSchedules.any((schedule) {
  //     final startDate = DateTime(
  //       schedule.startDateTime.year,
  //       schedule.startDateTime.month,
  //       schedule.startDateTime.day,
  //     );
  //     final endDate = DateTime(
  //       schedule.endDateTime.year,
  //       schedule.endDateTime.month,
  //       schedule.endDateTime.day,
  //     );
  //     return !startDate.isAtSameMomentAs(endDate);
  //   });

  //   int safeStartHour, safeEndHour, totalHours;

  //   if (hasMultiDaySchedules) {
  //     // 日をまたぐ予定がある場合は24時間表示
  //     safeStartHour = 0;
  //     safeEndHour = 24;
  //     totalHours = 24;
  //   } else {
  //     // 通常の予定の場合
  //     final startHour = timedSchedules.first.startDateTime.hour;
  //     final endHour = timedSchedules.last.endDateTime.hour + 1;

  //     // 最小6時間、最大24時間の範囲を確保
  //     final minStartHour = (startHour - 1).clamp(0, 23);
  //     final maxEndHour = (endHour + 1).clamp(6, 24);
  //     safeStartHour = minStartHour;
  //     safeEndHour = maxEndHour;
  //     totalHours = safeEndHour - safeStartHour;
  //   }

  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Row(
  //         children: [
  //           Icon(
  //             Icons.access_time,
  //             color: Colors.green[600],
  //             size: 16,
  //           ),
  //           const SizedBox(width: 4),
  //           Text(
  //             '時間指定',
  //             style: TextStyle(
  //               fontSize: 12,
  //               fontWeight: FontWeight.w600,
  //               color: Colors.green[600],
  //             ),
  //           ),
  //         ],
  //       ),
  //       const SizedBox(height: 8),
  //       SizedBox(
  //         height: 200,
  //         child: SingleChildScrollView(
  //           scrollDirection: Axis.horizontal,
  //           child: SizedBox(
  //             width: totalHours * 80.0 + 60, // 時間あたり80px + 余白
  //             child: Stack(
  //               children: [
  //                 // 時間軸
  //                 _buildTimeAxis(safeStartHour, safeEndHour),
  //                 // 予定バー
  //                 ...timedSchedules.map(
  //                     (schedule) => _buildScheduleBar(schedule, safeStartHour)),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  // 横向き時間軸を構築
  Widget _buildHorizontalTimeAxis(int startHour, int endHour) {
    // 安全な範囲を確保
    final safeStartHour = startHour.clamp(0, 23);
    final safeEndHour = endHour.clamp(safeStartHour + 1, 24);
    final hourCount = safeEndHour - safeStartHour;

    // 最小1時間は確保
    final finalHourCount = hourCount.clamp(1, 24);

    return Positioned(
      left: 0,
      top: 0,
      right: 0,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          border: Border(
            bottom: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
        ),
        child: Row(
          children: List.generate(finalHourCount, (index) {
            final hour = safeStartHour + index;
            final isMainHour = hour % 6 == 0; // 6時間ごとに強調

            return Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: isMainHour ? Colors.grey[400]! : Colors.grey[200]!,
                      width: isMainHour ? 2 : 1,
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    '${hour.toString().padLeft(2, '0')}:00',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isMainHour ? FontWeight.w600 : FontWeight.w400,
                      color: isMainHour ? Colors.grey[700] : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // 改善された時間軸を構築（旧版）
  Widget _buildEnhancedTimeAxis(int startHour, int endHour) {
    // 安全な範囲を確保
    final safeStartHour = startHour.clamp(0, 23);
    final safeEndHour = endHour.clamp(safeStartHour + 1, 24);
    final hourCount = safeEndHour - safeStartHour;

    // 最小1時間は確保
    final finalHourCount = hourCount.clamp(1, 24);

    return Positioned(
      left: 0,
      top: 0,
      bottom: 0,
      child: Container(
        width: 60,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          border: Border(
            right: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
        ),
        child: Column(
          children: List.generate(finalHourCount, (index) {
            final hour = safeStartHour + index;
            final isMainHour = hour % 6 == 0; // 6時間ごとに強調

            return Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isMainHour ? Colors.grey[400]! : Colors.grey[200]!,
                      width: isMainHour ? 2 : 1,
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    '${hour.toString().padLeft(2, '0')}:00',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isMainHour ? FontWeight.w600 : FontWeight.w400,
                      color: isMainHour ? Colors.grey[700] : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // 終日予定バーを構築（改善版）
  Widget _buildAllDayBar(dynamic schedule, int index, int totalHours) {
    final title = schedule.title ?? 'タイトルなし';
    final color = _getScheduleColor(schedule);

    // タイムテーブルの実際の幅を計算
    final timelineWidth = totalHours * 100.0 + 80; // 時間あたり100px + 余白

    return Positioned(
      left: 0,
      top: 50.0 + (index * 45), // 間隔を少し広げる
      child: Container(
        width: timelineWidth, // タイムテーブルの実際の幅に合わせる
        height: 38, // 高さを少し増やす
        margin: const EdgeInsets.symmetric(vertical: 2), // 上下にマージンを追加
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.9),
              color.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(8), // 角丸を少し大きく
          border: Border.all(
            color: color.withOpacity(0.8),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13, // フォントサイズを少し大きく
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  // 最大レーン数を計算
  int _calculateMaxLanes(List<dynamic> schedules) {
    if (schedules.isEmpty) return 0;

    // 予定を時間順にソート
    schedules.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

    List<List<dynamic>> lanes = [];

    for (final schedule in schedules) {
      final startTime = schedule.startDateTime;
      final endTime = schedule.endDateTime;

      // 適切なレーンを見つける
      int laneIndex = 0;
      bool foundLane = false;

      for (int i = 0; i < lanes.length; i++) {
        bool canPlaceInLane = true;

        for (final existingSchedule in lanes[i]) {
          final existingStartTime = existingSchedule.startDateTime;
          final existingEndTime = existingSchedule.endDateTime;

          // 既存の予定との重なりをチェック
          if (startTime.isBefore(existingEndTime) &&
              endTime.isAfter(existingStartTime)) {
            canPlaceInLane = false;
            break;
          }
        }

        if (canPlaceInLane) {
          laneIndex = i;
          foundLane = true;
          break;
        }
      }

      // 新しいレーンが必要な場合
      if (!foundLane) {
        lanes.add([]);
        laneIndex = lanes.length - 1;
      }

      // 予定をレーンに追加
      lanes[laneIndex].add(schedule);
    }

    return lanes.length;
  }

  // 重ならない予定バーを構築
  List<Widget> _buildNonOverlappingScheduleBars(
      List<dynamic> schedules, int startHour) {
    if (schedules.isEmpty) return [];

    // 予定を時間順にソート
    schedules.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

    List<Widget> bars = [];
    List<List<dynamic>> lanes = []; // 各レーンに配置された予定を管理

    for (final schedule in schedules) {
      final startTime = schedule.startDateTime;
      final endTime = schedule.endDateTime;

      // 位置計算は_buildHorizontalScheduleBarで行う

      // 適切なレーンを見つける
      int laneIndex = 0;
      bool foundLane = false;

      for (int i = 0; i < lanes.length; i++) {
        bool canPlaceInLane = true;

        for (final existingSchedule in lanes[i]) {
          final existingStartTime = existingSchedule.startDateTime;
          final existingEndTime = existingSchedule.endDateTime;

          // 既存の予定との重なりをチェック
          if (startTime.isBefore(existingEndTime) &&
              endTime.isAfter(existingStartTime)) {
            canPlaceInLane = false;
            break;
          }
        }

        if (canPlaceInLane) {
          laneIndex = i;
          foundLane = true;
          break;
        }
      }

      // 新しいレーンが必要な場合
      if (!foundLane) {
        lanes.add([]);
        laneIndex = lanes.length - 1;
      }

      // 予定をレーンに追加
      lanes[laneIndex].add(schedule);

      // 予定バーを構築
      bars.add(_buildHorizontalScheduleBar(schedule, startHour, laneIndex));
    }

    return bars;
  }

  // 横向き予定バーを構築
  Widget _buildHorizontalScheduleBar(dynamic schedule, int startHour,
      [int laneIndex = 0]) {
    final title = schedule.title ?? 'タイトルなし';
    final startTime = schedule.startDateTime;
    final endTime = schedule.endDateTime;
    final color = _getScheduleColor(schedule);

    // 今日の日付を取得
    final today = DateTime.now();
    final todayStartOfDay =
        DateTime(today.year, today.month, today.day, 0, 0, 0);

    // 日をまたぐ予定かチェック
    final startDate = DateTime(
      startTime.year,
      startTime.month,
      startTime.day,
    );
    final endDate = DateTime(
      endTime.year,
      endTime.month,
      endTime.day,
    );
    final isMultiDay = !startDate.isAtSameMomentAs(endDate);

    double left, top, width;

    if (isMultiDay) {
      // 日をまたぐ予定の場合
      if (startTime.isBefore(todayStartOfDay)) {
        // 昨日から始まる予定の場合、今日の00:00から表示
        left = 0.0;
        top = 50.0;
        width = 80.0;
      } else {
        // 今日から始まって明日にまたがる予定の場合
        final startMinutes = startTime.hour * 60 + startTime.minute;
        final startMinutesFromBase = startMinutes - (startHour * 60);

        left = (startMinutesFromBase / 60) * 100.0;
        top = 50.0;
        width = 80.0;
      }
    } else {
      // 通常の予定の場合
      final startMinutes = startTime.hour * 60 + startTime.minute;
      final endMinutes = endTime.hour * 60 + endTime.minute;
      final startMinutesFromBase = startMinutes - (startHour * 60);
      final durationMinutes = endMinutes - startMinutes;

      left = (startMinutesFromBase / 60) * 100.0;
      top = 50.0; // 中央に配置
      width = (durationMinutes / 60) * 100.0;
    }

    return Positioned(
      left: left,
      top: top + 50 + (laneIndex * 45), // レーンの間隔を広げる
      child: Container(
        width: width.clamp(80.0, 250.0), // 最小幅を少し大きく
        height: 38, // 高さを少し増やす
        margin: const EdgeInsets.symmetric(vertical: 2), // 上下にマージンを追加
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.9),
              color.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.8),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13, // フォントサイズを少し大きく
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  // 改善された予定バーを構築（旧版）
  Widget _buildEnhancedScheduleBar(dynamic schedule, int startHour) {
    final title = schedule.title ?? 'タイトルなし';
    final startTime = schedule.startDateTime;
    final endTime = schedule.endDateTime;
    final color = _getScheduleColor(schedule);

    // 日をまたぐ予定かチェック
    final startDate = DateTime(
      startTime.year,
      startTime.month,
      startTime.day,
    );
    final endDate = DateTime(
      endTime.year,
      endTime.month,
      endTime.day,
    );
    final isMultiDay = !startDate.isAtSameMomentAs(endDate);

    double left, top, height;

    if (isMultiDay) {
      // 日をまたぐ予定の場合は開始時刻のみ表示
      final startMinutes = startTime.hour * 60 + startTime.minute;
      final startMinutesFromBase = startMinutes - (startHour * 60);

      left = 70.0 + (startMinutesFromBase / 60) * 80.0;
      top = (startMinutesFromBase % 60) / 60 * 240.0;
      height = 30.0; // 固定の高さ
    } else {
      // 通常の予定の場合
      final startMinutes = startTime.hour * 60 + startTime.minute;
      final endMinutes = endTime.hour * 60 + endTime.minute;
      final startMinutesFromBase = startMinutes - (startHour * 60);
      final durationMinutes = endMinutes - startMinutes;

      left = 70.0 + (startMinutesFromBase / 60) * 80.0;
      top = (startMinutesFromBase % 60) / 60 * 240.0;
      height = (durationMinutes / 60) * 240.0;
    }

    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: 75,
        height: height.clamp(30.0, 240.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.9),
              color.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.8),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Text(
                isMultiDay
                    ? '${_formatTime(startTime)}〜翌日${_formatTime(endTime)}'
                    : '${_formatTime(startTime)}-${_formatTime(endTime)}',
                style: const TextStyle(
                  fontSize: 9,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 時間軸を構築（旧版）
  Widget _buildTimeAxis(int startHour, int endHour) {
    // 安全な範囲を確保
    final safeStartHour = startHour.clamp(0, 23);
    final safeEndHour = endHour.clamp(safeStartHour + 1, 24);
    final hourCount = safeEndHour - safeStartHour;

    // 最小1時間は確保
    final finalHourCount = hourCount.clamp(1, 24);

    return Positioned(
      left: 0,
      top: 0,
      bottom: 0,
      child: Container(
        width: 50,
        child: Column(
          children: List.generate(finalHourCount, (index) {
            final hour = safeStartHour + index;
            return Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    '${hour.toString().padLeft(2, '0')}:00',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // 予定バーを構築
  Widget _buildScheduleBar(dynamic schedule, int startHour) {
    final title = schedule.title ?? 'タイトルなし';
    final startTime = schedule.startDateTime;
    final endTime = schedule.endDateTime;
    final color = _getScheduleColor(schedule);

    // 日をまたぐ予定かチェック
    final startDate = DateTime(
      startTime.year,
      startTime.month,
      startTime.day,
    );
    final endDate = DateTime(
      endTime.year,
      endTime.month,
      endTime.day,
    );
    final isMultiDay = !startDate.isAtSameMomentAs(endDate);

    double left, top, height;

    if (isMultiDay) {
      // 日をまたぐ予定の場合は開始時刻のみ表示
      final startMinutes = startTime.hour * 60 + startTime.minute;
      final startMinutesFromBase = startMinutes - (startHour * 60);

      left = 60.0 + (startMinutesFromBase / 60) * 80.0;
      top = (startMinutesFromBase % 60) / 60 * 200.0;
      height = 20.0; // 固定の高さ
    } else {
      // 通常の予定の場合
      final startMinutes = startTime.hour * 60 + startTime.minute;
      final endMinutes = endTime.hour * 60 + endTime.minute;
      final startMinutesFromBase = startMinutes - (startHour * 60);
      final durationMinutes = endMinutes - startMinutes;

      left = 60.0 + (startMinutesFromBase / 60) * 80.0;
      top = (startMinutesFromBase % 60) / 60 * 200.0;
      height = (durationMinutes / 60) * 200.0;
    }

    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: 70,
        height: height.clamp(20.0, 200.0),
        decoration: BoxDecoration(
          color: color.withOpacity(0.8),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: color,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Text(
                isMultiDay
                    ? '${_formatTime(startTime)}〜翌日${_formatTime(endTime)}'
                    : '${_formatTime(startTime)}-${_formatTime(endTime)}',
                style: const TextStyle(
                  fontSize: 8,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // スケジュールの色を取得
  Color _getScheduleColor(dynamic schedule) {
    if (schedule.color != null && schedule.color.isNotEmpty) {
      return _hexToColor(schedule.color);
    }
    // デフォルト色
    return themeColor;
  }

  // 16進数文字列をColorに変換
  Color _hexToColor(String hexColor) {
    try {
      final hex = hexColor.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return themeColor;
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // 6カ月のデータを取得
  Future<List<Map<String, dynamic>>> _loadSixMonthData(
      String spaceId, DateTime now) async {
    List<Map<String, dynamic>> sixMonthData = [];

    for (int i = 5; i >= 0; i--) {
      final targetDate = DateTime(now.year, now.month - i, 1);
      final year = targetDate.year;
      final month = targetDate.month;

      try {
        final monthlySummary =
            await _transactionInfrastructure.getMonthlySummary(
          spaceId: spaceId,
          year: year,
          month: month,
        );

        sixMonthData.add({
          'year': year,
          'month': month,
          'monthName': '${month}月',
          'income': monthlySummary['income'] ?? 0.0,
          'expense': monthlySummary['expense'] ?? 0.0,
          'balance': monthlySummary['balance'] ?? 0.0,
        });
      } catch (e) {
        // データ取得に失敗した場合は0で埋める
        sixMonthData.add({
          'year': year,
          'month': month,
          'monthName': '${month}月',
          'income': 0.0,
          'expense': 0.0,
          'balance': 0.0,
        });
      }
    }

    return sixMonthData;
  }

  Widget _buildNoSpaceView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.home_outlined,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 24),
          const Text(
            'スペースがありません',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'スペースを作成して、\n家族やカップルと共有を始めましょう',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SpaceAddScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text(
              'スペースを作成',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
