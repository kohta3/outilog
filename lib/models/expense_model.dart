import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final String spaceId;
  final String title;
  final double amount;
  final String categoryId;
  final String paymentMethodId;
  final String memo;
  final DateTime transactionDate;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  ExpenseModel({
    required this.id,
    required this.spaceId,
    required this.title,
    required this.amount,
    required this.categoryId,
    required this.paymentMethodId,
    required this.memo,
    required this.transactionDate,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
  });

  factory ExpenseModel.fromFirestore(Map<String, dynamic> data) {
    return ExpenseModel(
      id: data['id'] ?? '',
      spaceId: data['space_id'] ?? '',
      title: data['title'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      categoryId: data['category_id'] ?? '',
      paymentMethodId: data['payment_method_id'] ?? '',
      memo: data['memo'] ?? '',
      transactionDate: (data['transaction_date'] as Timestamp).toDate(),
      createdBy: data['created_by'] ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'space_id': spaceId,
      'title': title,
      'amount': amount,
      'category_id': categoryId,
      'payment_method_id': paymentMethodId,
      'memo': memo,
      'transaction_date': Timestamp.fromDate(transactionDate),
      'created_by': createdBy,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'is_active': isActive,
    };
  }

  ExpenseModel copyWith({
    String? id,
    String? spaceId,
    String? title,
    double? amount,
    String? categoryId,
    String? paymentMethodId,
    String? memo,
    DateTime? transactionDate,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      spaceId: spaceId ?? this.spaceId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      memo: memo ?? this.memo,
      transactionDate: transactionDate ?? this.transactionDate,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
