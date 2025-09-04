import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentMethodModel {
  final String id;
  final String spaceId;
  final String name;
  final String icon; // アイコン名または絵文字
  final String color;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  PaymentMethodModel({
    required this.id,
    required this.spaceId,
    required this.name,
    required this.icon,
    required this.color,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
  });

  factory PaymentMethodModel.fromFirestore(Map<String, dynamic> data) {
    return PaymentMethodModel(
      id: data['id'] ?? '',
      spaceId: data['space_id'] ?? '',
      name: data['name'] ?? '',
      icon: data['icon'] ?? '💳',
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
      'name': name,
      'icon': icon,
      'color': color,
      'created_by': createdBy,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'is_active': isActive,
    };
  }

  PaymentMethodModel copyWith({
    String? id,
    String? spaceId,
    String? name,
    String? icon,
    String? color,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return PaymentMethodModel(
      id: id ?? this.id,
      spaceId: spaceId ?? this.spaceId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
