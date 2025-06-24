# outi_log

家族とカップルの共有アプリ

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Folder Structure

```
lib
├── application         # アプリケーションのビジネスロジック
├── constant            # 定数（色、スタイルなど）
├── infrastructure      # データ層の実装（APIクライアント、DBなど）
├── models              # データモデル
├── provider            # 状態管理 (Riverpod / Provider)
├── repository          # データ層のインターフェース (Abstract Class)
├── utils               # 汎用的なユーティリティ関数
└── view                # UI（画面、ウィジェット）
    ├── component       # 共通で利用するウィジェット
    ├── household_budget # 家計簿関連の画面
    ├── schedule        # スケジュール関連の画面
    ├── settings        # 設定関連の画面
    └── shopping_list   # 買い物リスト関連の画面
```
