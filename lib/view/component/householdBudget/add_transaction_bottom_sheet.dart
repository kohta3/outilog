import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:outi_log/constant/color.dart';
import 'package:outi_log/constant/genre.dart';

class AddTransactionBottomSheet extends StatefulWidget {
  final String transactionType; // '支出' or '収入'

  const AddTransactionBottomSheet({super.key, required this.transactionType});

  @override
  State<AddTransactionBottomSheet> createState() =>
      _AddTransactionBottomSheetState();
}

class _AddTransactionBottomSheetState extends State<AddTransactionBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _amountController = TextEditingController();
  final _memoController = TextEditingController();
  String? _selectedGenre;
  DateTime _selectedDate = DateTime.now();

  // 仮の収入ジャンルリスト
  final List<String> incomeGenres = ['給与', 'ボーナス', '臨時収入', 'その他'];

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.transactionType == '支出' ? 0 : 1;
    _tabController =
        TabController(length: 2, vsync: this, initialIndex: initialIndex);
    _selectedGenre =
        initialIndex == 0 ? genreList.keys.first : incomeGenres.first;
  }

  void _saveTransaction() {
    Navigator.of(context).pop();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        padding: EdgeInsets.only(
          top: 12,
          left: 20,
          right: 20,
          bottom: 20 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: const BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TabBar(
              controller: _tabController,
              labelColor: primaryColor,
              unselectedLabelColor: secondaryTextColor,
              indicatorColor: primaryColor,
              indicatorSize: TabBarIndicatorSize.tab,
              onTap: (index) {
                setState(() {
                  _selectedGenre =
                      index == 0 ? genreList.keys.first : incomeGenres.first;
                });
              },
              tabs: const [
                Tab(text: '支出'),
                Tab(text: '収入'),
              ],
            ),
            const SizedBox(height: 24),
            _buildAmountField(),
            const SizedBox(height: 16),
            _buildTextField(_memoController, 'メモ'),
            const SizedBox(height: 16),
            _buildGenreDropdown(),
            const SizedBox(height: 16),
            _buildDateField(),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: _saveTransaction,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green,
                side: const BorderSide(color: themeColor),
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('保存する'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return TextField(
      controller: _amountController,
      decoration: InputDecoration(
        labelText: '金額',
        prefixText: '¥ ',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        labelStyle: const TextStyle(color: secondaryTextColor),
        prefixStyle: const TextStyle(fontSize: 24, color: primaryTextColor),
      ),
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildGenreDropdown() {
    final genres =
        _tabController.index == 0 ? genreList.keys.toList() : incomeGenres;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        value: _selectedGenre,
        onChanged: (String? newValue) {
          setState(() {
            _selectedGenre = newValue;
          });
        },
        items: genres.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: Colors.white,
      ),
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('日付', style: TextStyle(color: secondaryTextColor)),
            Text(
              DateFormat('yyyy/MM/dd').format(_selectedDate),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
