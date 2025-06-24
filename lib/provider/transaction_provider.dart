import 'package:flutter/foundation.dart';
import '../models/transaction.dart';

class TransactionNotifier extends ChangeNotifier {
  List<Transaction> _transactions = [];

  List<Transaction> get transactions => _transactions;

  // 収入のみを取得
  List<Transaction> get incomeTransactions =>
      _transactions.where((t) => t.type == 'income').toList();

  // 支出のみを取得
  List<Transaction> get expenseTransactions =>
      _transactions.where((t) => t.type == 'expense').toList();

  // 日付でソートされた取引を取得
  List<Transaction> get sortedTransactions {
    List<Transaction> sorted = List.from(_transactions);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted;
  }

  // 月別の取引を取得
  List<Transaction> getTransactionsForMonth(DateTime month) {
    return _transactions
        .where((transaction) =>
            transaction.date.year == month.year &&
            transaction.date.month == month.month)
        .toList();
  }

  // 取引を追加
  void addTransaction(Transaction transaction) {
    _transactions.add(transaction);
    notifyListeners();
  }

  // 取引を削除
  void removeTransaction(String id) {
    _transactions.removeWhere((transaction) => transaction.id == id);
    notifyListeners();
  }

  // 取引を更新
  void updateTransaction(Transaction updatedTransaction) {
    final index =
        _transactions.indexWhere((t) => t.id == updatedTransaction.id);
    if (index != -1) {
      _transactions[index] = updatedTransaction;
      notifyListeners();
    }
  }

  // サンプルデータを初期化
  void initializeSampleData() {
    _transactions = [
      Transaction(
        id: '1',
        title: 'スーパーで買い物',
        amount: 3500,
        category: '食費',
        subCategory: '食料品',
        date: DateTime.now().subtract(Duration(days: 1)),
        type: 'expense',
        memo: '週末の食材',
      ),
      Transaction(
        id: '2',
        title: '給料',
        amount: 250000,
        category: '収入',
        subCategory: '給与',
        date: DateTime.now().subtract(Duration(days: 2)),
        type: 'income',
        memo: '今月の給料',
      ),
      Transaction(
        id: '3',
        title: '電車賃',
        amount: 280,
        category: '交通費',
        subCategory: '電車・バス',
        date: DateTime.now().subtract(Duration(days: 3)),
        type: 'expense',
      ),
      Transaction(
        id: '4',
        title: '外食',
        amount: 1200,
        category: '食費',
        subCategory: '外食',
        date: DateTime.now().subtract(Duration(days: 4)),
        type: 'expense',
        memo: 'ランチ',
      ),
      Transaction(
        id: '5',
        title: '映画鑑賞',
        amount: 1800,
        category: '趣味・娯楽',
        subCategory: '映画',
        date: DateTime.now().subtract(Duration(days: 5)),
        type: 'expense',
      ),
      Transaction(
        id: '6',
        title: '副業収入',
        amount: 15000,
        category: '収入',
        subCategory: '副業',
        date: DateTime.now().subtract(Duration(days: 6)),
        type: 'income',
        memo: 'Web制作',
      ),
      Transaction(
        id: '7',
        title: '電気代',
        amount: 8500,
        category: '水道・光熱費',
        subCategory: '電気',
        date: DateTime.now().subtract(Duration(days: 7)),
        type: 'expense',
      ),
      Transaction(
        id: '8',
        title: '本代',
        amount: 1500,
        category: '教育・学習',
        subCategory: '本',
        date: DateTime.now().subtract(Duration(days: 8)),
        type: 'expense',
        memo: '技術書',
      ),
    ];
    notifyListeners();
  }

  // 月別の収支合計を取得
  Map<String, double> getMonthlyTotals(DateTime month) {
    final monthTransactions = getTransactionsForMonth(month);
    double income = 0;
    double expense = 0;

    for (var transaction in monthTransactions) {
      if (transaction.type == 'income') {
        income += transaction.amount;
      } else {
        expense += transaction.amount;
      }
    }

    return {
      'income': income,
      'expense': expense,
      'balance': income - expense,
    };
  }
}
