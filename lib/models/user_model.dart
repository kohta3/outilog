class UserModel {
  final String id; // Firebase AuthenticationのUID
  final String username; // ユーザー名
  final String email; // メールアドレス
  final String? profileImageUrl; // プロフィール画像のURL
  final DateTime createdAt; // 作成日時
  final DateTime updatedAt; // 更新日時

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  // Firestoreからデータを取得する際のファクトリコンストラクタ
  factory UserModel.fromFirestore(Map<String, dynamic> data) {
    return UserModel(
      id: data['id'] ?? '',
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      profileImageUrl: data['profile_image_url'],
      createdAt: data['created_at']?.toDate() ?? DateTime.now(),
      updatedAt: data['updated_at']?.toDate() ?? DateTime.now(),
    );
  }

  // Firestoreに保存する際のMapに変換
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'profile_image_url': profileImageUrl,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // セキュアストレージ用のJSON文字列に変換
  String toJson() {
    return '{"id":"$id","username":"$username","email":"$email","profileImageUrl":"${profileImageUrl ?? ""}","createdAt":"${createdAt.toIso8601String()}","updatedAt":"${updatedAt.toIso8601String()}"}';
  }

  // セキュアストレージから復元する際のファクトリコンストラクタ
  factory UserModel.fromJson(String jsonString) {
    // 簡単なJSONパース（dart:convertを使わずに）
    final idMatch = RegExp(r'"id":"([^"]*)"').firstMatch(jsonString);
    final usernameMatch =
        RegExp(r'"username":"([^"]*)"').firstMatch(jsonString);
    final emailMatch = RegExp(r'"email":"([^"]*)"').firstMatch(jsonString);
    final profileImageUrlMatch =
        RegExp(r'"profileImageUrl":"([^"]*)"').firstMatch(jsonString);
    final createdAtMatch =
        RegExp(r'"createdAt":"([^"]*)"').firstMatch(jsonString);
    final updatedAtMatch =
        RegExp(r'"updatedAt":"([^"]*)"').firstMatch(jsonString);

    return UserModel(
      id: idMatch?.group(1) ?? '',
      username: usernameMatch?.group(1) ?? '',
      email: emailMatch?.group(1) ?? '',
      profileImageUrl: profileImageUrlMatch?.group(1)?.isEmpty == true
          ? null
          : profileImageUrlMatch?.group(1),
      createdAt:
          DateTime.tryParse(createdAtMatch?.group(1) ?? '') ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse(updatedAtMatch?.group(1) ?? '') ?? DateTime.now(),
    );
  }

  // コピーを作成する際のメソッド
  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, username: $username, email: $email, profileImageUrl: $profileImageUrl, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.username == username &&
        other.email == email &&
        other.profileImageUrl == profileImageUrl &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        username.hashCode ^
        email.hashCode ^
        profileImageUrl.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
