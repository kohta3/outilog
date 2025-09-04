# 🔥 Firestore スペース管理システム

Firebase Firestoreを使用したスペース管理とリレーションテーブルによる参加者管理システムの実装です。

## 📊 データベース構造

### コレクション構成

```
📁 spaces (スペース基本情報)
├── id: string (ドキュメントID)
├── space_name: string (スペース名)
├── owner_id: string (オーナーのユーザーID)
├── created_at: timestamp (作成日時)
├── updated_at: timestamp (更新日時)
├── max_participants: number (最大参加者数)
└── is_active: boolean (アクティブ状態)

📁 space_participants (参加者リレーション)
├── id: string (ドキュメントID)
├── space_id: string (スペースID)
├── user_id: string (ユーザーID)
├── user_name: string (ユーザー名)
├── user_email: string (ユーザーメールアドレス)
├── role: string (権限: 'owner' | 'member')
├── joined_at: timestamp (参加日時)
└── is_active: boolean (アクティブ状態)

📁 space_invites (招待コード管理)
├── id: string (ドキュメントID)
├── invite_code: string (8桁の招待コード)
├── space_id: string (スペースID)
├── created_by: string (作成者のユーザーID)
├── created_at: timestamp (作成日時)
├── expires_at: timestamp (有効期限)
├── is_active: boolean (アクティブ状態)
├── use_count: number (使用回数)
└── max_uses: number (最大使用回数)
```

## 🚀 実装ファイル

### インフラストラクチャ層
- `lib/infrastructure/space_infrastructure.dart` - スペース管理のFirestore操作
- `lib/infrastructure/invite_infrastructure.dart` - 招待コード管理の操作

### リポジトリ層
- `lib/repository/firestore_space_repo.dart` - Firestore対応のスペースリポジトリ

### プロバイダー層
- `lib/provider/firestore_space_provider.dart` - Firestoreスペースの状態管理

### 移行ツール
- `lib/migration/space_data_migration.dart` - ローカルからFirestoreへのデータ移行

## 🔧 使用方法

### 1. プロバイダーの切り替え

既存のプロバイダーから新しいFirestoreプロバイダーに切り替えます：

```dart
// 従来
final spaces = ref.watch(spacesProvider);

// 新しいFirestore版
final spaces = ref.watch(firestoreSpacesProvider);
```

### 2. スペース作成

```dart
final success = await ref.read(firestoreSpacesProvider.notifier).addSpace(
  spaceName: 'マイホーム',
  userName: 'ユーザー名',
  userEmail: 'user@example.com',
);
```

### 3. スペース削除

```dart
final success = await ref.read(firestoreSpacesProvider.notifier).deleteSpace(spaceId);
```

### 4. 招待コード作成

```dart
final inviteCode = await ref.read(firestoreSpacesProvider.notifier).createInviteCode(spaceId);
```

### 5. 招待コードでスペース参加

```dart
final success = await ref.read(firestoreSpacesProvider.notifier).joinSpaceWithInviteCode(
  inviteCode: 'ABC12345',
  userName: 'ユーザー名',
  userEmail: 'user@example.com',
);
```

## 🔄 データ移行

### 自動移行の実行

アプリ起動時にローカルデータからFirestoreへの移行を自動実行：

```dart
void main() async {
  // ... Firebase初期化

  final container = ProviderContainer();
  
  // 移行チェック
  final migration = SpaceDataMigration(
    localRepo: container.read(spaceRepoProvider),
    firestoreRepo: container.read(firestoreSpaceRepoProvider),
    secureStorage: container.read(flutterSecureStorageControllerProvider.notifier),
  );
  
  final currentUser = container.read(currentUserProvider);
  if (currentUser != null && await migration.needsMigration()) {
    await migration.migrateToFirestore(
      userId: currentUser.uid,
      userName: currentUser.displayName ?? '名無し',
      userEmail: currentUser.email ?? '',
    );
  }

  runApp(MyApp());
}
```

## 🛡️ セキュリティルール

Firestoreのセキュリティルールの例：

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // スペースは認証済みユーザーのみアクセス可能
    match /spaces/{spaceId} {
      allow read, write: if request.auth != null;
    }
    
    // 参加者情報は関連ユーザーのみアクセス可能
    match /space_participants/{participantId} {
      allow read, write: if request.auth != null 
        && request.auth.uid == resource.data.user_id;
    }
    
    // 招待コードは認証済みユーザーのみアクセス可能
    match /space_invites/{inviteId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## ✨ 主な機能

### ✅ 実装済み機能
- スペースの作成・削除・切り替え
- 参加者のリレーション管理
- 招待コード生成・管理
- 権限管理（オーナー・メンバー）
- オーナー譲渡機能
- ローカルデータからの自動移行
- オフライン対応（ローカルキャッシュ）

### 🔒 セキュリティ機能
- オーナーのみがスペース削除可能
- 参加者数の上限チェック
- 招待コードの有効期限管理
- 重複参加の防止

### 📱 ユーザビリティ
- 自動的なスペース切り替え
- エラーハンドリングとフォールバック
- ローカルキャッシュによる高速表示

## 🧪 テスト

```dart
// テストケース例
void main() {
  group('Firestore Space Tests', () {
    test('スペース作成テスト', () async {
      // テスト実装
    });
    
    test('招待コード機能テスト', () async {
      // テスト実装
    });
  });
}
```

## 📝 マイグレーション手順

1. **新しいファイルを確認**: 上記のファイルがすべて作成されていることを確認
2. **Firebase設定確認**: `firebase_options.dart`にFirestoreの設定があることを確認
3. **プロバイダー切り替え**: UIコンポーネントで使用するプロバイダーを新しいものに変更
4. **テスト実行**: 基本的な機能が動作することを確認
5. **本番適用**: Firestoreのセキュリティルールを設定して本番適用

## 🎯 今後の拡張予定

- [ ] スペース内のデータ（予定、家計簿等）もFirestore化
- [ ] リアルタイム同期機能
- [ ] 高度な権限管理
- [ ] スペース招待のプッシュ通知
- [ ] スペース使用量の制限管理
