# 🔐 Firestore セキュリティルール設定ガイド

## 🚨 **現在のエラー状況**

```
Status{code=PERMISSION_DENIED, description=Missing or insufficient permissions., cause=null}
```

このエラーは、Firestoreのセキュリティルールが設定されていないか、適切でないために発生しています。

## 📋 **設定手順**

### **1. Firebase Console にアクセス**

1. [Firebase Console](https://console.firebase.google.com/) にアクセス
2. プロジェクト `outi-log` を選択
3. 左サイドバーから「Firestore Database」をクリック

### **2. セキュリティルールを設定**

1. 「ルール」タブをクリック
2. 現在のルール内容を確認
3. 以下のルールに置き換える：

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // ユーザー認証が必要な基本ルール
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // スペースコレクション
    match /spaces/{spaceId} {
      // 認証済みユーザーは全てのスペースを読み取り可能
      allow read: if isAuthenticated();
      
      // スペース作成は認証済みユーザーのみ
      allow create: if isAuthenticated() && 
                       request.auth.uid == resource.data.owner_id;
      
      // スペース更新・削除はオーナーのみ
      allow update, delete: if isAuthenticated() && 
                               request.auth.uid == resource.data.owner_id;
    }

    // スペース参加者コレクション
    match /space_participants/{participantId} {
      // 認証済みユーザーは全ての参加者情報を読み取り可能
      allow read: if isAuthenticated();
      
      // 参加者追加は認証済みユーザーのみ
      allow create: if isAuthenticated();
      
      // 自分の参加者情報は更新・削除可能
      allow update, delete: if isAuthenticated() && 
                               request.auth.uid == resource.data.user_id;
    }

    // 招待コードコレクション
    match /space_invites/{inviteId} {
      // 認証済みユーザーは招待コードを読み取り可能
      allow read: if isAuthenticated();
      
      // 招待コード作成は認証済みユーザーのみ
      allow create: if isAuthenticated();
      
      // 招待コード更新・削除は作成者のみ
      allow update, delete: if isAuthenticated() && 
                               request.auth.uid == resource.data.created_by;
    }

    // その他のコレクション（予定、家計簿など）
    match /schedules/{scheduleId} {
      allow read, write: if isAuthenticated();
    }
    
    match /transactions/{transactionId} {
      allow read, write: if isAuthenticated();
    }
    
    match /shopping_lists/{listId} {
      allow read, write: if isAuthenticated();
    }
  }
}
```

### **3. ルールを公開**

1. 「公開」ボタンをクリック
2. 確認ダイアログで「公開」を選択
3. ルールが適用されるまで数分待機

## 🔧 **Firebase CLI を使用した設定（推奨）**

### **1. Firebase CLI のインストール**

```bash
npm install -g firebase-tools
```

### **2. プロジェクトにログイン**

```bash
firebase login
```

### **3. プロジェクトを初期化**

```bash
# プロジェクトディレクトリで実行
firebase init firestore

# 既存のプロジェクトを選択: outi-log
# ルールファイル: firestore.rules (デフォルト)
# インデックスファイル: firestore.indexes.json (デフォルト)
```

### **4. ルールをデプロイ**

```bash
firebase deploy --only firestore:rules
```

## 🚀 **一時的な開発用ルール（テスト用）**

**⚠️ 注意: 本番環境では使用しないでください！**

開発・テスト中に一時的に使用できる緩いルール：

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## 📊 **セキュリティルールの確認**

### **1. ルールシミュレータを使用**

Firebase Console > Firestore > ルール > 「ルールの実行場」

### **2. 実際のアクセステスト**

```dart
// アプリでテスト実行
final spaces = await FirebaseFirestore.instance
    .collection('space_participants')
    .where('user_id', isEqualTo: 'ユーザーID')
    .where('is_active', isEqualTo: true)
    .get();
```

## 🔍 **トラブルシューティング**

### **よくあるエラーと解決策**

#### **1. PERMISSION_DENIED が続く場合**

- Firebase Console でルールが正しく公開されているか確認
- ユーザーが正しく認証されているか確認
- ルールの構文エラーがないか確認

#### **2. ルールが反映されない場合**

- 最大5分程度待機
- アプリを完全に再起動
- Firebase Console でルールのバージョンを確認

#### **3. 認証エラーが発生する場合**

```dart
// 認証状態の確認
final user = FirebaseAuth.instance.currentUser;
print('Current user: ${user?.uid}');
print('Is authenticated: ${user != null}');
```

## 📝 **次のステップ**

1. **セキュリティルールを設定**
2. **アプリを再起動**
3. **スペース表示を確認**
4. **必要に応じてルールを調整**

## 🎯 **本番環境への注意事項**

- より厳密な権限制御の実装
- スペース参加者のみがデータアクセス可能にする
- レート制限の設定
- セキュリティ監査の実施

設定完了後、アプリを再起動してスペースが正常に表示されることを確認してください！
