import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:outi_log/constant/color.dart';
import 'package:outi_log/infrastructure/transaction_firestore_infrastructure.dart';
import 'package:outi_log/provider/auth_provider.dart';
import 'package:outi_log/provider/firestore_space_provider.dart';
import 'package:outi_log/utils/toast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// カンマ区切り数値入力フォーマッター（9桁制限付き）
class _NumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 数字のみを抽出
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }

    // 9桁制限をチェック
    if (digitsOnly.length > 9) {
      // 9桁を超える場合は前の値を返す
      return oldValue;
    }

    // 数値に変換してカンマ区切りでフォーマット
    int number = int.parse(digitsOnly);
    String formatted = NumberFormat('#,###').format(number);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class EditTransactionBottomSheet extends ConsumerStatefulWidget {
  final Map<String, String> transactionData;
  final VoidCallback? onDataChanged;

  const EditTransactionBottomSheet({
    super.key,
    required this.transactionData,
    this.onDataChanged,
  });

  @override
  ConsumerState<EditTransactionBottomSheet> createState() =>
      _EditTransactionBottomSheetState();
}

class _EditTransactionBottomSheetState
    extends ConsumerState<EditTransactionBottomSheet> {
  final _amountController = TextEditingController();
  final _memoController = TextEditingController();
  final _storeNameController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  final TransactionFirestoreInfrastructure _transactionInfrastructure =
      TransactionFirestoreInfrastructure();

  @override
  void initState() {
    super.initState();

    // 取引データから初期値を設定
    _initializeFromTransactionData();
  }

  void _initializeFromTransactionData() {
    final data = widget.transactionData;

    // 金額を設定（カンマ区切りで表示）
    final amount = data['amount'] ?? '0';
    if (amount.isNotEmpty) {
      final amountInt = int.tryParse(amount) ?? 0;
      _amountController.text = NumberFormat('#,###').format(amountInt);
    }

    // メモを設定（descriptionカラムから取得）
    _memoController.text = data['description'] ?? '';

    // 店舗名を設定
    _storeNameController.text = data['storeName'] ?? '';

    // 日付を設定
    final dateString = data['date'] ?? '';
    if (dateString.isNotEmpty) {
      try {
        _selectedDate = DateTime.parse(dateString);
      } catch (e) {
        _selectedDate = DateTime.now();
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _memoController.dispose();
    _storeNameController.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction() async {
    // バリデーション
    if (_amountController.text.isEmpty) {
      Toast.show(context, '金額を入力してください');
      return;
    }

    // カンマを除去してから数値に変換
    final amountText = _amountController.text.replaceAll(',', '');
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      Toast.show(context, '有効な金額を入力してください');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final currentUser = ref.read(currentUserProvider);
      final spaceState = ref.read(firestoreSpacesProvider);
      final currentSpace = spaceState?.currentSpace;

      if (currentUser == null) {
        Toast.show(context, 'ログインが必要です');
        return;
      }

      if (currentSpace == null) {
        Toast.show(context, 'スペースが選択されていません');
        return;
      }

      final transactionId = widget.transactionData['id'] ?? '';
      if (transactionId.isEmpty) {
        Toast.show(context, '取引IDが見つかりません');
        return;
      }

      // 元のデータから分類とカテゴリーを取得
      final originalGenre = widget.transactionData['genre'] ?? '';
      final transactionType = widget.transactionData['type'] ?? 'expense';

      await _transactionInfrastructure.updateTransaction(
        transactionId: transactionId,
        spaceId: currentSpace.id,
        userId: currentUser.uid,
        title: originalGenre, // カテゴリー名をtitleとして使用
        amount: amount,
        category: originalGenre, // 元のカテゴリーを保持
        type: transactionType, // 元のタイプを保持
        transactionDate: _selectedDate,
        description: _memoController.text, // メモをdescriptionとして保存
        storeName: _storeNameController.text.isNotEmpty
            ? _storeNameController.text
            : null,
        receiptUrl: null, // レシートURLは更新しない
      );

      Toast.show(
          context, '${transactionType == 'expense' ? '支出' : '収入'}を更新しました');
      Navigator.of(context).pop(true);

      // データ変更を通知
      if (widget.onDataChanged != null) {
        widget.onDataChanged!();
      }
    } catch (e) {
      Toast.show(context, '更新に失敗しました: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Widget _buildLabeledField(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: primaryTextColor,
          ),
        ),
        const SizedBox(height: 8),
        field,
      ],
    );
  }

  Widget _buildAmountField() {
    return TextField(
      controller: _amountController,
      decoration: InputDecoration(
        prefix: const Text(
          '¥ ',
          style: TextStyle(
              fontSize: 18,
              color: primaryTextColor,
              fontWeight: FontWeight.bold),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      keyboardType: TextInputType.number,
      inputFormatters: [
        _NumberInputFormatter(),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: labelText,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      style: const TextStyle(fontSize: 16),
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('yyyy/MM/dd').format(_selectedDate),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Icon(Icons.calendar_today,
                color: secondaryTextColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTypeDisplay() {
    final type = widget.transactionData['type'] ?? 'expense';
    final typeText = type == 'income' ? '収入' : '支出';
    final typeColor = type == 'income' ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: typeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: typeColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            type == 'income' ? Icons.trending_up : Icons.trending_down,
            color: typeColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            typeText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: typeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDisplay() {
    final genre = widget.transactionData['genre'] ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Text(
        genre,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: primaryTextColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '編集',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 20),
              // 取引タイプを表示（読み取り専用）
              _buildLabeledField('タイプ', _buildTransactionTypeDisplay()),
              const SizedBox(height: 16),
              _buildLabeledField('金額', _buildAmountField()),
              const SizedBox(height: 16),
              _buildLabeledField('メモ', _buildTextField(_memoController, 'メモ')),
              const SizedBox(height: 16),
              // 支出の場合のみ店舗名を表示
              if (widget.transactionData['type'] == 'expense') ...[
                _buildLabeledField(
                    '店舗名', _buildTextField(_storeNameController, '店舗名（任意）')),
                const SizedBox(height: 16),
              ],
              _buildLabeledField('分類', _buildCategoryDisplay()),
              const SizedBox(height: 16),
              _buildLabeledField('日付', _buildDateField()),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: _isSaving ? null : _saveTransaction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: themeColor),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.green),
                        ),
                      )
                    : const Text('更新する'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
