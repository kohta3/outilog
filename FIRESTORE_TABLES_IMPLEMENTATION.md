# 🗄️ Firestore テーブル実装ガイド
## スケジュール・家計簿・買い物リスト のスペース紐づけ

## 📊 **データベース構造**

### **コレクション構成**

```
📁 spaces (スペース基本情報) 
└── space_id
    ├── space_name: string
    ├── owner_id: string
    └── created_at: timestamp

📁 space_participants (参加者管理)
└── participant_id
    ├── space_id: string (FK)
    ├── user_id: string (FK)
    └── role: string

📁 schedules (スケジュール)
└── schedule_id
    ├── space_id: string (FK)
    ├── title: string
    ├── start_time: timestamp
    ├── end_time: timestamp
    ├── created_by: string (FK)
    └── is_active: boolean

📁 transactions (家計簿)
└── transaction_id
    ├── space_id: string (FK)
    ├── title: string
    ├── amount: number
    ├── type: string ('income'|'expense')
    ├── category: string
    ├── transaction_date: timestamp
    ├── created_by: string (FK)
    └── is_active: boolean

📁 shopping_lists (買い物リスト)
└── list_id
    ├── space_id: string (FK)
    ├── name: string
    ├── created_by: string (FK)
    └── is_active: boolean

📁 shopping_items (買い物アイテム)
└── item_id
    ├── shopping_list_id: string (FK)
    ├── item_name: string
    ├── quantity: number
    ├── price: number
    ├── is_completed: boolean
    └── completed_by: string (FK)
```

## 🛠️ **実装ファイル**

### **1. インフラストラクチャ層（Firestore操作）**
- `lib/infrastructure/schedule_firestore_infrastructure.dart`
- `lib/infrastructure/transaction_firestore_infrastructure.dart`
- `lib/infrastructure/shopping_list_firestore_infrastructure.dart`

### **2. モデル層**
- `lib/models/schedule_firestore_model.dart`
- 既存の `lib/models/schedule_model.dart` に `fromFirestore()` メソッド追加

### **3. リポジトリ層**
- `lib/repository/schedule_firestore_repo.dart`
- `lib/repository/transaction_firestore_repo.dart`
- `lib/repository/shopping_list_firestore_repo.dart`

### **4. セキュリティルール**
- 更新された `firestore.rules`

## 🚀 **主な機能**

### **📅 スケジュール機能**
```dart
// スペース内のスケジュール取得
final schedules = await scheduleRepo.getSpaceSchedules(spaceId);

// スケジュール追加
await scheduleRepo.addSchedule(
  spaceId: spaceId,
  title: '会議',
  startTime: DateTime.now(),
  endTime: DateTime.now().add(Duration(hours: 1)),
  color: '#2196F3',
  createdBy: userId,
);

// 期間指定でスケジュール取得
final monthlySchedules = await scheduleRepo.getSchedulesByDateRange(
  spaceId: spaceId,
  startDate: DateTime(2024, 1, 1),
  endDate: DateTime(2024, 1, 31),
);
```

### **💰 家計簿機能**
```dart
// スペース内の取引取得
final transactions = await transactionRepo.getSpaceTransactions(spaceId);

// 取引追加
await transactionRepo.addTransaction(
  spaceId: spaceId,
  title: '食費',
  amount: 1500.0,
  category: '食事',
  type: 'expense',
  transactionDate: DateTime.now(),
  createdBy: userId,
);

// 月次サマリー取得
final summary = await transactionInfra.getMonthlySummary(
  spaceId: spaceId,
  year: 2024,
  month: 1,
);
// 結果: {'income': 250000, 'expense': 180000, 'balance': 70000}

// カテゴリ別統計
final categoryStats = await transactionInfra.getCategoryExpenseSummary(
  spaceId: spaceId,
  startDate: DateTime(2024, 1, 1),
  endDate: DateTime(2024, 1, 31),
);
```

### **🛒 買い物リスト機能**
```dart
// スペース内の買い物リスト取得
final lists = await shoppingRepo.getSpaceShoppingLists(spaceId);

// 買い物リスト作成
final listId = await shoppingRepo.addShoppingList(
  spaceId: spaceId,
  name: '今日の買い物',
  createdBy: userId,
);

// アイテム追加
await shoppingRepo.addShoppingItem(
  listId: listId,
  itemName: '牛乳',
  quantity: 2,
  unit: '本',
  price: 200,
);

// 完了状態の切り替え
await shoppingRepo.toggleItemCompletion(
  itemId: itemId,
  isCompleted: true,
  userId: userId,
);

// 進捗取得
final progress = await shoppingInfra.getShoppingListProgress(listId);
// 結果: {'total': 10, 'completed': 7, 'remaining': 3}
```

## 🔧 **実装手順**

### **1. Firestoreセキュリティルールの設定**
```bash
# Firebase Console で firestore.rules の内容を設定
# または Firebase CLI を使用
firebase deploy --only firestore:rules
```

### **2. 既存コードとの統合**
既存のプロバイダーを拡張してFirestore対応：

```dart
// example: Schedule Provider の拡張
final scheduleFirestoreProvider = StateNotifierProvider<ScheduleNotifier, List<ScheduleModel>>((ref) {
  final repo = ref.watch(scheduleFirestoreRepoProvider);
  final currentSpace = ref.watch(firestoreSpacesProvider)?.currentSpace;
  return ScheduleNotifier(repo, currentSpace?.id);
});

class ScheduleNotifier extends StateNotifier<List<ScheduleModel>> {
  final ScheduleFirestoreRepo _repo;
  final String? _spaceId;
  
  ScheduleNotifier(this._repo, this._spaceId) : super([]) {
    if (_spaceId != null) {
      loadSchedules();
    }
  }
  
  Future<void> loadSchedules() async {
    if (_spaceId == null) return;
    final schedules = await _repo.getSpaceSchedules(_spaceId!);
    state = schedules;
  }
  
  Future<void> addSchedule(ScheduleModel schedule) async {
    if (_spaceId == null) return;
    await _repo.addSchedule(/* parameters */);
    await loadSchedules(); // 再読み込み
  }
}
```

### **3. UI コンポーネントの更新**
既存のスケジュール、家計簿、買い物リスト画面でFirestoreプロバイダーを使用：

```dart
// HomeScreen.dart など
final currentSpace = ref.watch(firestoreSpacesProvider)?.currentSpace;
final schedules = ref.watch(scheduleFirestoreProvider);

if (currentSpace != null) {
  // スペースが選択されている場合のみデータを表示
  ScheduleScreen(spaceId: currentSpace.id);
}
```

## 📋 **マイグレーション計画**

### **段階1: 基盤整備**
- [x] Firestore インフラストラクチャ作成
- [x] セキュリティルール設定
- [x] モデル拡張

### **段階2: プロバイダー作成**
- [ ] Schedule Firestore Provider 作成
- [ ] Transaction Firestore Provider 作成  
- [ ] Shopping List Firestore Provider 作成

### **段階3: UI統合**
- [ ] 既存画面でFirestoreプロバイダーを使用
- [ ] ローカルデータからFirestoreへの移行機能
- [ ] オフライン対応とキャッシュ機能

### **段階4: 高度な機能**
- [ ] リアルタイム同期
- [ ] 権限管理の詳細化
- [ ] 統計・分析機能の強化

## 🔍 **デバッグとテスト**

### **データ確認方法**
```dart
// Firebase Console でデータを確認
// または開発者ツールでログ確認
print('DEBUG: Schedules for space $spaceId');
final schedules = await scheduleInfra.getSpaceSchedules(spaceId);
print('DEBUG: Found ${schedules.length} schedules');
```

### **よくある問題と解決策**

#### **1. セキュリティルールエラー**
```
PERMISSION_DENIED: Missing or insufficient permissions
```
→ Firebase Console でセキュリティルールが正しく設定されているか確認

#### **2. スペースIDが null**
```
Exception: スペースが選択されていません
```
→ 現在のスペースが正しく設定されているか確認

#### **3. データが表示されない**
```
DEBUG: Found 0 schedules
```
→ Firestoreにデータが正しく保存されているか Firebase Console で確認

## 🎯 **次のステップ**

1. **セキュリティルールの設定**
2. **プロバイダーの作成と統合**
3. **既存UIコンポーネントの更新**
4. **データ移行機能の実装**
5. **テストとデバッグ**

これで、スペースに紐づいたスケジュール、家計簿、買い物リストのFirestore管理システムが完成です！🎉
