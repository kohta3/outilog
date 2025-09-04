import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String spaceId;
  final String name;
  final String color;
  final String type; // 'expense' or 'income'
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  CategoryModel({
    required this.id,
    required this.spaceId,
    required this.name,
    required this.color,
    required this.type,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
  });

  factory CategoryModel.fromFirestore(Map<String, dynamic> data) {
    return CategoryModel(
      id: data['id'] ?? '',
      spaceId: data['space_id'] ?? '',
      name: data['name'] ?? '',
      color: data['color'] ?? '#2196F3',
      type: data['type'] ?? 'expense',
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
      'color': color,
      'type': type,
      'created_by': createdBy,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'is_active': isActive,
    };
  }

  CategoryModel copyWith({
    String? id,
    String? spaceId,
    String? name,
    String? color,
    String? type,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      spaceId: spaceId ?? this.spaceId,
      name: name ?? this.name,
      color: color ?? this.color,
      type: type ?? this.type,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
