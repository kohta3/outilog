import 'package:flutter/material.dart';
import 'package:outi_log/constant/color.dart';
import 'package:outi_log/utils/format.dart';
import 'package:outi_log/view/component/householdBudget/add_transaction_bottom_sheet.dart';
import 'package:outi_log/view/component/householdBudget/household_budget.dart';
import 'package:outi_log/view/component/householdBudget/household_budget_graph.dart';
import 'package:outi_log/view/component/householdBudget/household_budget_list.dart';

class AccountBookScreen extends StatefulWidget {
  const AccountBookScreen({super.key});

  @override
  State<AccountBookScreen> createState() => _AccountBookScreenState();
}

class _AccountBookScreenState extends State<AccountBookScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _currentDate = DateTime.now();

  Map<String, List<Map<String, String>>> data = {
    '2025/1': [
      {
        'genre': '食費',
        'amount': '10000',
      },
      {
        'genre': '交通費',
        'amount': '20000',
      },
      {
        'genre': '水道・光熱費',
        'amount': '30000',
      },
      {
        'genre': '趣味・娯楽',
        'amount': '3000',
      },
      {
        'genre': 'その他',
        'amount': '60000',
      },
    ],
    '2025/2': [
      {
        'genre': '食費',
        'amount': '10000',
      },
      {
        'genre': '交通費',
        'amount': '20000',
      },
      {
        'genre': '美容・衣服',
        'amount': '30000',
      },
      {
        'genre': 'その他',
        'amount': '60000',
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
                  },
                  icon: Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                    color: themeColor,
                  )),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // グラフタブ
                HouseholdBudgetGraph(data: data, currentDate: _currentDate),
                // リストタブ
                HouseholdBudgetList(data: data, currentDate: _currentDate),
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
    );
  }
}
