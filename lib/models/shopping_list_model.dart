import 'package:cloud_firestore/cloud_firestore.dart';

/// 買い物リストグループのモデル
class ShoppingListGroupModel {
  final String id;
  final String spaceId;
  final String groupName;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  ShoppingListGroupModel({
    required this.id,
    required this.spaceId,
    required this.groupName,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
  });

  factory ShoppingListGroupModel.fromFirestore(Map<String, dynamic> data) {
    return ShoppingListGroupModel(
      id: data['id'] ?? '',
      spaceId: data['space_id'] ?? '',
      groupName: data['group_name'] ?? '',
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
      'group_name': groupName,
      'created_by': createdBy,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'is_active': isActive,
    };
  }

  ShoppingListGroupModel copyWith({
    String? id,
    String? spaceId,
    String? groupName,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return ShoppingListGroupModel(
      id: id ?? this.id,
      spaceId: spaceId ?? this.spaceId,
      groupName: groupName ?? this.groupName,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// 買い物リストアイテムのモデル
class ShoppingListItemModel {
  final String id;
  final String groupId;
  final String itemName;
  final bool isPurchased;
  final double? amount;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  ShoppingListItemModel({
    required this.id,
    required this.groupId,
    required this.itemName,
    required this.isPurchased,
    this.amount,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
  });

  factory ShoppingListItemModel.fromFirestore(Map<String, dynamic> data) {
    return ShoppingListItemModel(
      id: data['id'] ?? '',
      groupId: data['group_id'] ?? '',
      itemName: data['item_name'] ?? '',
      isPurchased: data['is_purchased'] ?? false,
      amount: (data['amount'] as num?)?.toDouble(),
      createdBy: data['created_by'] ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'group_id': groupId,
      'item_name': itemName,
      'is_purchased': isPurchased,
      'amount': amount,
      'created_by': createdBy,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'is_active': isActive,
    };
  }

  ShoppingListItemModel copyWith({
    String? id,
    String? groupId,
    String? itemName,
    bool? isPurchased,
    double? amount,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return ShoppingListItemModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      itemName: itemName ?? this.itemName,
      isPurchased: isPurchased ?? this.isPurchased,
      amount: amount ?? this.amount,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
