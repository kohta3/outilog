class Transaction {
  final String id;
  final String title;
  final double amount;
  final String category;
  final String subCategory;
  final DateTime date;
  final String type; // 'income' or 'expense'
  final String? memo;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.subCategory,
    required this.date,
    required this.type,
    this.memo,
  });

  // JSONからオブジェクトを作成
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      title: json['title'],
      amount: json['amount'].toDouble(),
      category: json['category'],
      subCategory: json['subCategory'],
      date: DateTime.parse(json['date']),
      type: json['type'],
      memo: json['memo'],
    );
  }

  // オブジェクトをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'subCategory': subCategory,
      'date': date.toIso8601String(),
      'type': type,
      'memo': memo,
    };
  }
}
