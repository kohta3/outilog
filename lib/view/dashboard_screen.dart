import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outi_log/constant/color.dart';
import 'package:outi_log/provider/firestore_space_provider.dart';
import 'package:outi_log/provider/space_prodiver.dart';
import 'package:outi_log/provider/schedule_firestore_provider.dart';
import 'package:outi_log/provider/auth_provider.dart';
import 'package:outi_log/infrastructure/transaction_firestore_infrastructure.dart';
import 'package:outi_log/view/space_add_screen.dart';
import 'package:outi_log/view/component/advertisement/native_ad_widget.dart';
import 'package:outi_log/utils/format.dart';
import 'package:outi_log/models/space_model.dart';
import 'package:outi_log/services/analytics_service.dart';
import 'package:outi_log/utils/image_optimizer.dart';

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
      // ダッシュボード画面の表示を記録
      AnalyticsService().logScreenView(screenName: 'dashboard');
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

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey[50]!,
            Colors.white,
          ],
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー画像セクション（AppBarと一体化）
            _buildStylishHeaderSection(currentSpace),

            // メインコンテンツ
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 今日の予定セクション
                  _buildModernTodayScheduleSection(ref),
                  const SizedBox(height: 24),

                  // ネイティブ広告を追加
                  const ListNativeAdWidget(
                    margin: EdgeInsets.symmetric(vertical: 8),
                  ),
                  const SizedBox(height: 16),

                  // 月間収支グラフセクション
                  _buildModernMonthlySummarySection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // モダンな月間収支グラフセクション
  Widget _buildModernMonthlySummarySection() {
    final income = _monthlySummary['income'] ?? 0.0;
    final expense = _monthlySummary['expense'] ?? 0.0;
    final balance = _monthlySummary['balance'] ?? 0.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.orange[50]!,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.orange[400]!, Colors.orange[600]!],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        '6カ月間の収支',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // 収支サマリー
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.grey[50]!,
                        Colors.white,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildModernSummaryItem('収入', income, Colors.green),
                      Container(
                        width: 1,
                        height: 60,
                        color: Colors.grey[300],
                      ),
                      _buildModernSummaryItem('支出', expense, Colors.red),
                      Container(
                        width: 1,
                        height: 60,
                        color: Colors.grey[300],
                      ),
                      _buildModernSummaryItem('収支', balance,
                          balance >= 0 ? Colors.blue : Colors.red),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // 6カ月比較グラフ
                _buildModernSixMonthChart(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernSummaryItem(String label, double amount, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '¥${formatCurrency(amount)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildModernSixMonthChart() {
    if (_sixMonthData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.bar_chart,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'データがありません',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '収支データを追加してみましょう',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
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

  /// 時間に応じた挨拶を取得
  String _getTimeBasedGreeting() {
    final now = DateTime.now();
    final hour = now.hour;

    if (hour >= 5 && hour < 11) {
      return 'おはようございます';
    } else if (hour >= 11 && hour < 15) {
      return 'こんにちは';
    } else if (hour >= 15 && hour < 19) {
      return 'お疲れ様です';
    } else if (hour >= 19 && hour < 22) {
      return 'こんばんは';
    } else {
      return 'おやすみなさい';
    }
  }

  /// おしゃれなヘッダー画像セクションを構築（AppBarと一体化）
  Widget _buildStylishHeaderSection(SpaceModel currentSpace) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32.0),
          bottomRight: Radius.circular(32.0),
        ),
        boxShadow: [
          BoxShadow(
            color: themeColor.withOpacity(0.4),
            blurRadius: 25,
            offset: const Offset(0, 10),
            spreadRadius: 3,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32.0),
          bottomRight: Radius.circular(32.0),
        ),
        child: currentSpace.headerImageUrl != null &&
                currentSpace.headerImageUrl!.isNotEmpty
            ? Stack(
                children: [
                  // ヘッダー画像（最適化版）
                  ImageOptimizer.buildOptimizedNetworkImage(
                    currentSpace.headerImageUrl!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    maxBytes: 2 * 1024 * 1024, // 2MB制限
                    errorWidget:
                        _buildStylishDefaultHeader(currentSpace.spaceName),
                    placeholder: Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  // グラデーションオーバーレイ（より美しいグラデーション）
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.2),
                          Colors.black.withOpacity(0.6),
                        ],
                        stops: const [0.0, 0.6, 1.0],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // 装飾的な要素
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 40,
                    right: 40,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // メインコンテンツ
                  Positioned(
                    bottom: 30,
                    left: 24,
                    right: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 挨拶とアイコン
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.25),
                                    Colors.white.withOpacity(0.15),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.home,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getTimeBasedGreeting(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    currentSpace.spaceName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                      shadows: [
                                        Shadow(
                                          offset: Offset(2, 2),
                                          blurRadius: 4,
                                          color: Colors.black54,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // 装飾的なライン
                        Container(
                          width: 60,
                          height: 4,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.8),
                                Colors.white.withOpacity(0.4),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : _buildStylishDefaultHeader(currentSpace.spaceName),
      ),
    );
  }

  /// おしゃれなデフォルトヘッダーを構築
  Widget _buildStylishDefaultHeader(String spaceName) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            themeColor,
            themeColor.withOpacity(0.9),
            themeColor.withOpacity(0.7),
            themeColor.withOpacity(0.5),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // 装飾的な円形要素
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 2,
                ),
              ),
            ),
          ),
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // メインコンテンツ
          Positioned(
            bottom: 30,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 挨拶とアイコン
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.25),
                            Colors.white.withOpacity(0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.home,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getTimeBasedGreeting(),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            spaceName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(
                                  offset: Offset(2, 2),
                                  blurRadius: 4,
                                  color: Colors.black54,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // 装飾的なライン
                Container(
                  width: 60,
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.8),
                        Colors.white.withOpacity(0.4),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // モダンな今日の予定セクション
  Widget _buildModernTodayScheduleSection(WidgetRef ref) {
    final todaySchedules =
        ref.watch(scheduleFirestoreProvider.notifier).todaySchedules;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.blue[50]!,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[400]!, Colors.blue[600]!],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '今日の予定',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${todaySchedules.length}件の予定',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                todaySchedules.isEmpty
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.event_available,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '今日の予定はありません',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '新しい予定を追加してみましょう',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _buildModernTimelineView(todaySchedules),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // モダンなタイムライン表示を構築
  Widget _buildModernTimelineView(List<dynamic> schedules) {
    // 終日予定と時間指定予定を分ける
    final allDaySchedules = schedules.where((s) => s.isAllDay).toList();
    final timedSchedules = schedules.where((s) => !s.isAllDay).toList();

    return Column(
      children: [
        if (allDaySchedules.isNotEmpty) ...[
          _buildModernAllDaySection(allDaySchedules),
          const SizedBox(height: 16),
        ],
        if (timedSchedules.isNotEmpty) ...[
          _buildTimelineScheduleSection(timedSchedules),
        ],
      ],
    );
  }

  // モダンな終日予定セクションを構築
  Widget _buildModernAllDaySection(List<dynamic> allDaySchedules) {
    return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
              spreadRadius: 1,
            ),
          ],
          gradient: LinearGradient(
            colors: [Colors.green[100]!, Colors.green[50]!],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple[50]!, Colors.purple[100]!],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.purple[200]!, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple[400],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.event_available,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '終日の予定',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[700],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.purple[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${allDaySchedules.length}件',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...allDaySchedules
                .map((schedule) => _buildModernAllDayItem(schedule)),
          ],
        ));
  }

  // モダンな終日予定アイテム
  Widget _buildModernAllDayItem(dynamic schedule) {
    final title = schedule.title ?? 'タイトルなし';
    final color = _getScheduleColor(schedule);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.event_available,
                size: 12,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // タイムライン形式の時間指定予定セクション
  Widget _buildTimelineScheduleSection(List<dynamic> timedSchedules) {
    // データが空の場合はデフォルト表示
    if (timedSchedules.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Column(
          children: [
            Icon(
              Icons.access_time,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '時間指定の予定がありません',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // 時間指定予定を時間順にソート
    timedSchedules.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[50]!, Colors.green[100]!],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[400],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.timeline,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'タイムライン',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${timedSchedules.length}件',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // タイムライン表示
          _buildTimelineView(timedSchedules),
        ],
      ),
    );
  }

  // タイムライン表示を構築
  Widget _buildTimelineView(List<dynamic> schedules) {
    return Container(
      height: 200,
      child: ListView.builder(
        itemCount: schedules.length,
        itemBuilder: (context, index) {
          final schedule = schedules[index];
          final isLast = index == schedules.length - 1;
          return _buildTimelineItem(schedule, isLast);
        },
      ),
    );
  }

  // タイムラインアイテムを構築
  Widget _buildTimelineItem(dynamic schedule, bool isLast) {
    final title = schedule.title ?? 'タイトルなし';
    final memo = schedule.memo ?? '';
    final startTime = schedule.startDateTime;
    final endTime = schedule.endDateTime;
    final color = _getScheduleColor(schedule);

    final startTimeStr =
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final endTimeStr =
        '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // タイムライン軸
        Column(
          children: [
            // 時間表示
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                startTimeStr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // 縦線
            Container(
              width: 2,
              height: isLast ? 20 : 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color,
                    isLast ? color.withOpacity(0.3) : color,
                  ],
                ),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            if (!isLast) const SizedBox(height: 8),
          ],
        ),
        const SizedBox(width: 16),
        // 予定内容
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  color.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 12,
                      color: color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$startTimeStr - $endTimeStr',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                if (memo.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    memo,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                      height: 1.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
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
