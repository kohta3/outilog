import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleFirestoreModel {
  final String id;
  final String spaceId;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String color;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  ScheduleFirestoreModel({
    required this.id,
    required this.spaceId,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.color,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
  });

  factory ScheduleFirestoreModel.fromFirestore(Map<String, dynamic> data) {
    return ScheduleFirestoreModel(
      id: data['id'] ?? '',
      spaceId: data['space_id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      startTime: (data['start_time'] as Timestamp).toDate(),
      endTime: (data['end_time'] as Timestamp).toDate(),
      color: data['color'] ?? '#2196F3',
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
      'description': description,
      'start_time': Timestamp.fromDate(startTime),
      'end_time': Timestamp.fromDate(endTime),
      'color': color,
      'created_by': createdBy,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'is_active': isActive,
    };
  }

  ScheduleFirestoreModel copyWith({
    String? id,
    String? spaceId,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? color,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return ScheduleFirestoreModel(
      id: id ?? this.id,
      spaceId: spaceId ?? this.spaceId,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      color: color ?? this.color,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

class TransactionFirestoreModel {
  final String id;
  final String spaceId;
  final String title;
  final double amount;
  final String category;
  final String type; // 'income' or 'expense'
  final DateTime transactionDate;
  final String description;
  final String? receiptUrl;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  TransactionFirestoreModel({
    required this.id,
    required this.spaceId,
    required this.title,
    required this.amount,
    required this.category,
    required this.type,
    required this.transactionDate,
    required this.description,
    this.receiptUrl,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
  });

  factory TransactionFirestoreModel.fromFirestore(Map<String, dynamic> data) {
    return TransactionFirestoreModel(
      id: data['id'] ?? '',
      spaceId: data['space_id'] ?? '',
      title: data['title'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      category: data['category'] ?? '',
      type: data['type'] ?? 'expense',
      transactionDate: (data['transaction_date'] as Timestamp).toDate(),
      description: data['description'] ?? '',
      receiptUrl: data['receipt_url'],
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
      'category': category,
      'type': type,
      'transaction_date': Timestamp.fromDate(transactionDate),
      'description': description,
      'receipt_url': receiptUrl,
      'created_by': createdBy,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'is_active': isActive,
    };
  }

  TransactionFirestoreModel copyWith({
    String? id,
    String? spaceId,
    String? title,
    double? amount,
    String? category,
    String? type,
    DateTime? transactionDate,
    String? description,
    String? receiptUrl,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return TransactionFirestoreModel(
      id: id ?? this.id,
      spaceId: spaceId ?? this.spaceId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      type: type ?? this.type,
      transactionDate: transactionDate ?? this.transactionDate,
      description: description ?? this.description,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

class ShoppingListFirestoreModel {
  final String id;
  final String spaceId;
  final String name;
  final String description;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final int itemsCount;

  ShoppingListFirestoreModel({
    required this.id,
    required this.spaceId,
    required this.name,
    required this.description,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    this.itemsCount = 0,
  });

  factory ShoppingListFirestoreModel.fromFirestore(Map<String, dynamic> data) {
    return ShoppingListFirestoreModel(
      id: data['id'] ?? '',
      spaceId: data['space_id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      createdBy: data['created_by'] ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['is_active'] ?? true,
      itemsCount: (data['items_count'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'space_id': spaceId,
      'name': name,
      'description': description,
      'created_by': createdBy,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'is_active': isActive,
    };
  }
}

class ShoppingItemFirestoreModel {
  final String id;
  final String shoppingListId;
  final String itemName;
  final double quantity;
  final double price;
  final String unit;
  final bool isCompleted;
  final String? completedBy;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  ShoppingItemFirestoreModel({
    required this.id,
    required this.shoppingListId,
    required this.itemName,
    required this.quantity,
    required this.price,
    required this.unit,
    required this.isCompleted,
    this.completedBy,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShoppingItemFirestoreModel.fromFirestore(Map<String, dynamic> data) {
    return ShoppingItemFirestoreModel(
      id: data['id'] ?? '',
      shoppingListId: data['shopping_list_id'] ?? '',
      itemName: data['item_name'] ?? '',
      quantity: (data['quantity'] as num?)?.toDouble() ?? 1.0,
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      unit: data['unit'] ?? '個',
      isCompleted: data['is_completed'] ?? false,
      completedBy: data['completed_by'],
      completedAt: (data['completed_at'] as Timestamp?)?.toDate(),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'shopping_list_id': shoppingListId,
      'item_name': itemName,
      'quantity': quantity,
      'price': price,
      'unit': unit,
      'is_completed': isCompleted,
      'completed_by': completedBy,
      'completed_at':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }
}
