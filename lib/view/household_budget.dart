import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:outi_log/constant/color.dart';
import 'package:outi_log/utils/format.dart';
import 'package:outi_log/view/component/householdBudget/add_transaction_bottom_sheet.dart';
import 'package:outi_log/view/component/householdBudget/settings_bottom_sheet.dart';
import 'package:outi_log/view/component/householdBudget/household_budget.dart';
import 'package:outi_log/view/component/householdBudget/household_budget_graph.dart';
import 'package:outi_log/view/component/householdBudget/household_budget_list.dart';
import 'package:outi_log/infrastructure/transaction_firestore_infrastructure.dart';
import 'package:outi_log/provider/firestore_space_provider.dart';
import 'package:outi_log/utils/toast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AccountBookScreen extends ConsumerStatefulWidget {
  const AccountBookScreen({super.key});

  @override
  ConsumerState<AccountBookScreen> createState() => _AccountBookScreenState();
}

class _AccountBookScreenState extends ConsumerState<AccountBookScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _currentDate = DateTime.now();

  final TransactionFirestoreInfrastructure _transactionInfrastructure =
      TransactionFirestoreInfrastructure();
  Map<String, List<Map<String, String>>> data = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTransactionData();
  }

  Future<void> _loadTransactionData() async {
    try {
      final spaceState = ref.read(firestoreSpacesProvider);
      final currentSpace = spaceState?.currentSpace;

      if (currentSpace == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final transactions = await _transactionInfrastructure
          .getSpaceTransactions(currentSpace.id);

      // データを月別に整理
      final Map<String, Map<String, double>> monthlyData = {};

      for (final transaction in transactions) {
        final transactionDate =
            (transaction['transaction_date'] as Timestamp).toDate();
        final monthKey = '${transactionDate.year}/${transactionDate.month}';
        final category = transaction['category'] as String;
        final amount = (transaction['amount'] as num).toDouble();
        final type = transaction['type'] as String;

        // 支出のみを表示（収入は別途処理）
        if (type == 'expense') {
          if (!monthlyData.containsKey(monthKey)) {
            monthlyData[monthKey] = {};
          }
          monthlyData[monthKey]![category] =
              (monthlyData[monthKey]![category] ?? 0) + amount;
        }
      }

      // 表示用のデータ形式に変換
      final Map<String, List<Map<String, String>>> formattedData = {};
      monthlyData.forEach((month, categories) {
        formattedData[month] = categories.entries
            .map((entry) => {
                  'genre': entry.key,
                  'amount': entry.value.toInt().toString(),
                })
            .toList();
      });

      setState(() {
        data = formattedData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Toast.show(context, 'データの読み込みに失敗しました: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            indicatorColor: themeColor,
            labelColor: themeColor,
            unselectedLabelColor: Colors.grey,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: [
              Tab(
                text: 'グラフ',
              ),
              Tab(text: 'リスト')
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                  onPressed: () {
                    setState(() {
                      _currentDate = DateTime(
                        _currentDate.year,
                        _currentDate.month - 1,
                        _currentDate.day,
                      );
                    });
                    _loadTransactionData();
                  },
                  icon: Icon(
                    Icons.arrow_back_ios,
                    size: 18,
                    color: themeColor,
                  )),
              Text(formatMonthJp(_currentDate)),
              IconButton(
                  onPressed: () {
                    setState(() {
                      _currentDate = DateTime(
                        _currentDate.year,
                        _currentDate.month + 1,
                        _currentDate.day,
                      );
                    });
                    _loadTransactionData();
                  },
                  icon: Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                    color: themeColor,
                  )),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // グラフタブ
                      HouseholdBudgetGraph(
                          data: data, currentDate: _currentDate),
                      // リストタブ
                      HouseholdBudgetList(
                          data: data, currentDate: _currentDate),
                    ],
                  ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              householdBudget(context, Colors.red, '支出', () {
                _showAddTransactionSheet('支出');
              }),
              householdBudget(context, primaryColor, '収入', () {
                _showAddTransactionSheet('収入');
              }),
              householdBudget(context, Colors.grey, '設定', () {
                _showSettingsSheet();
              }),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddTransactionSheet(String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return AddTransactionBottomSheet(transactionType: type);
      },
    ).then((result) {
      // 取引が保存された場合はデータを再読み込み
      if (result == true) {
        _loadTransactionData();
      }
    });
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const SettingsBottomSheet();
      },
    );
  }
}
