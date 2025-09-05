import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionFirestoreInfrastructure {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _transactionsCollection = 'transactions';

  /// 取引を追加（支出・収入共通）
  Future<String> addTransaction({
    required String spaceId,
    required String title,
    required double amount,
    required String category,
    required String type, // 'income' or 'expense'
    required DateTime transactionDate,
    required String createdBy,
    String? description,
    String? receipt_url,
    String? color, // 色情報（16進数文字列）
  }) async {
    try {
      final transactionRef =
          _firestore.collection(_transactionsCollection).doc();

      await transactionRef.set({
        'id': transactionRef.id,
        'space_id': spaceId,
        'title': title,
        'amount': amount,
        'category': category,
        'type': type,
        'transaction_date': Timestamp.fromDate(transactionDate),
        'description': description ?? '',
        'receipt_url': receipt_url,
        'color': color, // 色情報を保存
        'created_by': createdBy,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'is_active': true,
      });

      return transactionRef.id;
    } catch (e) {
      throw Exception('取引の追加に失敗しました: $e');
    }
  }

  /// スペース内の取引一覧を取得
  Future<List<Map<String, dynamic>>> getSpaceTransactions(
      String spaceId) async {
    try {
      final query = await _firestore
          .collection(_transactionsCollection)
          .where('space_id', isEqualTo: spaceId)
          .where('is_active', isEqualTo: true)
          .orderBy('transaction_date', descending: true)
          .get();

      return query.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      throw Exception('取引一覧の取得に失敗しました: $e');
    }
  }

  /// 期間指定で取引を取得
  Future<List<Map<String, dynamic>>> getTransactionsByDateRange({
    required String spaceId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final query = await _firestore
          .collection(_transactionsCollection)
          .where('space_id', isEqualTo: spaceId)
          .where('is_active', isEqualTo: true)
          .where('transaction_date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('transaction_date',
              isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('transaction_date', descending: true)
          .get();

      return query.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      throw Exception('指定期間の取引取得に失敗しました: $e');
    }
  }

  /// カテゴリ別の取引を取得
  Future<List<Map<String, dynamic>>> getTransactionsByCategory({
    required String spaceId,
    required String category,
  }) async {
    try {
      final query = await _firestore
          .collection(_transactionsCollection)
          .where('space_id', isEqualTo: spaceId)
          .where('category', isEqualTo: category)
          .where('is_active', isEqualTo: true)
          .orderBy('transaction_date', descending: true)
          .get();

      return query.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      throw Exception('カテゴリ別取引の取得に失敗しました: $e');
    }
  }

  /// 収入・支出別の取引を取得
  Future<List<Map<String, dynamic>>> getTransactionsByType({
    required String spaceId,
    required String type, // 'income' or 'expense'
  }) async {
    try {
      final query = await _firestore
          .collection(_transactionsCollection)
          .where('space_id', isEqualTo: spaceId)
          .where('type', isEqualTo: type)
          .where('is_active', isEqualTo: true)
          .orderBy('transaction_date', descending: true)
          .get();

      return query.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      throw Exception('取引タイプ別の取得に失敗しました: $e');
    }
  }

  /// 取引を更新
  Future<bool> updateTransaction({
    required String transactionId,
    required String spaceId,
    required String userId,
    String? title,
    double? amount,
    String? category,
    String? type,
    DateTime? transactionDate,
    String? description,
    String? receiptUrl,
    String? color, // 色情報を追加
  }) async {
    try {
      // 取引の存在確認と権限チェック
      final transactionDoc = await _firestore
          .collection(_transactionsCollection)
          .doc(transactionId)
          .get();

      if (!transactionDoc.exists) {
        throw Exception('取引が見つかりません');
      }

      final transactionData = transactionDoc.data()!;
      if (transactionData['space_id'] != spaceId) {
        throw Exception('このスペースの取引ではありません');
      }

      // 更新データを準備
      final updateData = <String, dynamic>{
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (title != null) updateData['title'] = title;
      if (amount != null) updateData['amount'] = amount;
      if (category != null) updateData['category'] = category;
      if (type != null) updateData['type'] = type;
      if (transactionDate != null)
        updateData['transaction_date'] = Timestamp.fromDate(transactionDate);
      if (description != null) updateData['description'] = description;
      if (receiptUrl != null) updateData['receipt_url'] = receiptUrl;
      if (color != null) updateData['color'] = color;

      await _firestore
          .collection(_transactionsCollection)
          .doc(transactionId)
          .update(updateData);

      return true;
    } catch (e) {
      throw Exception('取引の更新に失敗しました: $e');
    }
  }

  /// 取引を削除
  Future<bool> deleteTransaction({
    required String transactionId,
    required String spaceId,
    required String userId,
  }) async {
    try {
      // 取引の存在確認と権限チェック
      final transactionDoc = await _firestore
          .collection(_transactionsCollection)
          .doc(transactionId)
          .get();

      if (!transactionDoc.exists) {
        throw Exception('取引が見つかりません');
      }

      final transactionData = transactionDoc.data()!;
      if (transactionData['space_id'] != spaceId) {
        throw Exception('このスペースの取引ではありません');
      }

      await _firestore
          .collection(_transactionsCollection)
          .doc(transactionId)
          .update({
        'is_active': false,
        'deleted_at': FieldValue.serverTimestamp(),
        'deleted_by': userId,
      });

      return true;
    } catch (e) {
      throw Exception('取引の削除に失敗しました: $e');
    }
  }

  /// 特定の取引を取得
  Future<Map<String, dynamic>?> getTransaction(String transactionId) async {
    try {
      final doc = await _firestore
          .collection(_transactionsCollection)
          .doc(transactionId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return {
        'id': doc.id,
        ...doc.data()!,
      };
    } catch (e) {
      throw Exception('取引の取得に失敗しました: $e');
    }
  }

  /// 月次収支サマリーを取得
  Future<Map<String, double>> getMonthlySummary({
    required String spaceId,
    required int year,
    required int month,
  }) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

      final transactions = await getTransactionsByDateRange(
        spaceId: spaceId,
        startDate: startDate,
        endDate: endDate,
      );

      double totalIncome = 0;
      double totalExpense = 0;

      for (final transaction in transactions) {
        final amount = (transaction['amount'] as num).toDouble();
        final type = transaction['type'] as String;

        if (type == 'income') {
          totalIncome += amount;
        } else if (type == 'expense') {
          totalExpense += amount;
        }
      }

      return {
        'income': totalIncome,
        'expense': totalExpense,
        'balance': totalIncome - totalExpense,
      };
    } catch (e) {
      throw Exception('月次サマリーの取得に失敗しました: $e');
    }
  }

  /// カテゴリ別の支出統計を取得
  Future<Map<String, double>> getCategoryExpenseSummary({
    required String spaceId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final transactions = await getTransactionsByDateRange(
        spaceId: spaceId,
        startDate: startDate,
        endDate: endDate,
      );

      final Map<String, double> categoryExpenses = {};

      for (final transaction in transactions) {
        if (transaction['type'] == 'expense') {
          final category = transaction['category'] as String;
          final amount = (transaction['amount'] as num).toDouble();

          categoryExpenses[category] =
              (categoryExpenses[category] ?? 0) + amount;
        }
      }

      return categoryExpenses;
    } catch (e) {
      throw Exception('カテゴリ別統計の取得に失敗しました: $e');
    }
  }
}
