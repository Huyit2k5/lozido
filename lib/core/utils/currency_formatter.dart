import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    // Lấy chuỗi chỉ chứa số
    String value = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (value.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Parse sang double
    double doubleValue = double.parse(value);
    
    // Định dạng kiểu tiền Việt Nam (sử dụng dấu chấm làm phân cách hàng nghìn)
    final formattedString = formatCurrency(doubleValue);

    return newValue.copyWith(
      text: formattedString,
      selection: TextSelection.collapsed(offset: formattedString.length),
    );
  }
}

/// Định dạng số tiền theo chuẩn Việt Nam (vd: 1.000.000)
String formatCurrency(num value) {
  final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0);
  return formatter.format(value).trim();
}
