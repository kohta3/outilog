class SpacesModel {
  final Map<String, SpaceModel> spaces;
  final String currentSpaceId;
  final int maxSpaces; // 最大スペース数（将来的に課金で変更）

  SpacesModel({
    required this.spaces,
    required this.currentSpaceId,
    this.maxSpaces = 2, // 無料版は2つまで
  });

  factory SpacesModel.fromJson(Map<String, dynamic> json) {
    final spacesMap = <String, SpaceModel>{};
    final spacesJson = json['spaces'] as Map<String, dynamic>;

    spacesJson.forEach((key, value) {
      spacesMap[key] = SpaceModel.fromJson(value);
    });

    return SpacesModel(
      spaces: spacesMap,
      currentSpaceId: json['currentSpaceId'],
      maxSpaces: json['maxSpaces'] ?? 2,
    );
  }

  Map<String, dynamic> toJson() {
    final spacesJson = <String, dynamic>{};
    spaces.forEach((key, value) {
      spacesJson[key] = value.toJson();
    });

    return {
      'spaces': spacesJson,
      'currentSpaceId': currentSpaceId,
      'maxSpaces': maxSpaces,
    };
  }

  bool get canCreateSpace => spaces.length < maxSpaces;
  int get remainingSpaces => maxSpaces - spaces.length;
  SpaceModel? get currentSpace => spaces[currentSpaceId];
}

class SpaceModel {
  final String id;
  final String spaceName;
  final List<SharedUser> sharedUsers;
  final String ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  SpaceModel({
    required this.id,
    required this.spaceName,
    required this.sharedUsers,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SpaceModel.fromJson(Map<String, dynamic> json) {
    return SpaceModel(
      id: json['id'],
      spaceName: json['spaceName'],
      sharedUsers: (json['sharedUsers'] as List<dynamic>)
          .map((user) => SharedUser.fromJson(user as Map<String, dynamic>))
          .toList(),
      ownerId: json['ownerId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'spaceName': spaceName,
      'sharedUsers': sharedUsers.map((user) => user.toJson()).toList(),
      'ownerId': ownerId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  SpaceModel copyWith({
    String? id,
    String? spaceName,
    List<SharedUser>? sharedUsers,
    String? ownerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SpaceModel(
      id: id ?? this.id,
      spaceName: spaceName ?? this.spaceName,
      sharedUsers: sharedUsers ?? this.sharedUsers,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class SharedUser {
  final String name;
  final String address;

  SharedUser({
    required this.name,
    required this.address,
  });

  factory SharedUser.fromJson(Map<String, dynamic> json) {
    return SharedUser(
      name: json['name'],
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
    };
  }
}
