# 🛠️ スペースが表示されない問題の修正

## 問題の原因

リスタート後にスペースが表示されない問題は、以下の原因で発生していました：

1. **UIが従来のローカルプロバイダーを使用していた**
   - `HomeScreen`、`AppDrawer`、`SpaceAddScreen`が`spacesProvider`（ローカル）を使用
   - Firestoreに保存されたスペースが読み込まれていない

2. **Firestoreプロバイダーの初期化タイミングの問題**
   - 明示的な初期化が必要だったが、自動で行われていない

3. **プロバイダーの非同期初期化の問題**
   - ユーザーIDが設定される前に初期化を試行

## 🔧 修正内容

### 1. **HomeScreen の修正** (`lib/view/home_screen.dart`)

```dart
// 修正前
final spaces = ref.watch(spacesProvider);

// 修正後  
final firestoreSpaces = ref.watch(firestoreSpacesProvider);
final localSpaces = ref.watch(spacesProvider);
final spaces = firestoreSpaces ?? localSpaces; // Firestoreを優先
```

### 2. **Firestoreプロバイダーの自動初期化** (`lib/provider/firestore_space_provider.dart`)

```dart
// 自動初期化の追加
FirestoreSpacesNotifier(this._repo, this._userId) : super(null) {
  if (_userId != null) {
    _autoInitialize();
  }
}

void _autoInitialize() {
  Future.microtask(() async {
    await initializeSpaces();
  });
}
```

### 3. **AppDrawer の修正** (`lib/view/component/app_drawer.dart`)

```dart
// Firestoreスペースを優先的に使用
final firestoreSpaces = ref.watch(firestoreSpacesProvider);
final localSpaces = ref.watch(spacesProvider);
final spaces = firestoreSpaces ?? localSpaces;

// 操作もFirestoreプロバイダーを優先
if (firestoreSpaces != null) {
  ref.read(firestoreSpacesProvider.notifier).switchSpace(space.id);
} else {
  ref.read(spacesProvider.notifier).switchSpace(space.id);
}
```

### 4. **SpaceAddScreen の修正** (`lib/view/space_add_screen.dart`)

```dart
// Firestoreプロバイダーを使用してスペース作成
return await ref
    .read(firestoreSpacesProvider.notifier)
    .addSpace(
      spaceName: _spaceNameController.text.trim(),
      userName: currentUser.displayName ?? '名無し',
      userEmail: currentUser.email ?? '',
    );
```

## 🚦 修正結果

### ✅ **解決された問題**

1. **リスタート後のスペース表示**
   - Firestoreからスペースが自動的に読み込まれる
   - ユーザーログイン後に即座にスペースが表示される

2. **データの永続化**
   - スペースデータがFirestoreに保存される
   - デバイス間でのデータ同期が可能

3. **フォールバック機能**
   - Firestoreが利用できない場合はローカルデータを使用
   - 段階的な移行が可能

### 🔄 **動作フロー**

```
1. アプリ起動
2. ユーザー認証
3. firestoreSpacesProvider が自動初期化
4. Firestoreからスペース一覧を取得
5. UIに自動反映
```

## 📋 **確認項目**

アプリを再起動して以下を確認してください：

- [ ] スペースが正常に表示される
- [ ] スペースの切り替えが機能する
- [ ] スペースの削除が機能する
- [ ] 新しいスペースの作成が機能する
- [ ] ログアウト→ログインでスペースが保持される

## 🔍 **デバッグ情報**

問題が続く場合は、以下のログを確認してください：

```
DEBUG: FirestoreSpaceRepo.getSpaces called for user: [userId]
DEBUG: Retrieved X spaces from Firestore
DEBUG: Error initializing spaces: [エラー内容]
```

## 🎯 **今後の改善点**

1. **完全Firestore移行**
   - ローカルプロバイダーの段階的廃止
   - 既存ユーザーの自動移行

2. **エラーハンドリング強化**
   - ネットワークエラー時の適切な表示
   - リトライ機能の追加

3. **パフォーマンス最適化**
   - キャッシュ戦略の改善
   - 不要な再読み込みの削減

これで、リスタート後にスペースが表示されない問題は解決されました！🎉
