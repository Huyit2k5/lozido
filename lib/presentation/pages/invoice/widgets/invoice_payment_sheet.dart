import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/currency_formatter.dart';

class InvoicePaymentSheet extends StatefulWidget {
  final String houseId;
  final String invoiceId;
  final Map<String, dynamic> invoiceData;

  const InvoicePaymentSheet({
    super.key,
    required this.houseId,
    required this.invoiceId,
    required this.invoiceData,
  });

  @override
  State<InvoicePaymentSheet> createState() => _InvoicePaymentSheetState();
}

class _InvoicePaymentSheetState extends State<InvoicePaymentSheet> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String? _paymentMethod = 'Tiền mặt';
  DateTime _paymentDate = DateTime.now();

  late double _remaining;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final grandTotal = (widget.invoiceData['grandTotal'] ?? 0).toDouble();
    final paidAmount = (widget.invoiceData['paidAmount'] ?? 0).toDouble();
    _remaining = grandTotal - paidAmount;
    
    // Auto fill with remaining (formatted)
    _amountController.text = formatCurrency(_remaining);
  }

  Future<void> _submitPayment() async {
    final String amountStr = _amountController.text.replaceAll('.', '').replaceAll(',', '');
    final double amount = double.tryParse(amountStr) ?? 0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ')),
      );
      return;
    }
    
    if (_paymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn phương thức thanh toán')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final oldPaid = (widget.invoiceData['paidAmount'] ?? 0).toDouble();
      final grandTotal = (widget.invoiceData['grandTotal'] ?? 0).toDouble();
      final newPaid = oldPaid + amount;
      
      String newStatus;
      if (newPaid >= grandTotal) {
        newStatus = 'Đã thu xong';
      } else {
        newStatus = 'Đang nợ tiền';
      }

      final newPaymentRecord = {
        'amount': amount,
        'method': _paymentMethod,
        'date': Timestamp.fromDate(_paymentDate),
        'note': _noteController.text,
        'createdAt': Timestamp.now(),
      };

      final transactionRef = FirebaseFirestore.instance
          .collection('houses')
          .doc(widget.houseId)
          .collection('transactions')
          .doc();

      final invoiceRef = FirebaseFirestore.instance
          .collection('houses')
          .doc(widget.houseId)
          .collection('invoices')
          .doc(widget.invoiceId);

      final batch = FirebaseFirestore.instance.batch();

      batch.update(invoiceRef, {
        'paidAmount': newPaid,
        'status': newStatus,
        'payments': FieldValue.arrayUnion([newPaymentRecord]),
      });

      batch.set(transactionRef, {
        'type': 'Thu',
        'category': 'Thu tiền phòng',
        'amount': amount,
        'date': Timestamp.fromDate(_paymentDate),
        'note': _noteController.text.isNotEmpty 
            ? _noteController.text 
            : 'Thu tiền hóa đơn tháng ${widget.invoiceData['billingMonth'] ?? ''} - ${widget.invoiceData['roomName'] ?? ''}',
        'createdAt': FieldValue.serverTimestamp(),
        'paymentMethod': _paymentMethod,
        'systemGenerated': true,
      });

      await batch.commit();

      if (mounted) {
        Navigator.pop(context, true); // Return true to signal refresh
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thu tiền thành công')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_offer_outlined, color: Colors.black87),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Thu tiền hóa đơn",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("Có thể thu nhiều lần",
                        style: TextStyle(color: Colors.black54, fontSize: 13)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Amount Input
            RichText(
              text: const TextSpan(
                text: "Nhập số tiền khách trả kỳ này ",
                style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold),
                children: [TextSpan(text: "*", style: TextStyle(color: Colors.red))],
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.green, fontWeight: FontWeight.bold, fontSize: 20),
              decoration: InputDecoration(
                suffixText: "đ",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
            ),
            const SizedBox(height: 16),
            
            // Method and Date
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: const TextSpan(
                          text: "P.thức thanh toán ",
                          style: TextStyle(color: Colors.black87, fontSize: 13),
                          children: [TextSpan(text: "*", style: TextStyle(color: Colors.red))],
                        ),
                      ),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        value: _paymentMethod,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'Tiền mặt', child: Text('Tiền mặt')),
                          DropdownMenuItem(
                              value: 'Chuyển khoản', child: Text('Chuyển khoản')),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _paymentMethod = val;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Ngày thu/chi",
                          style: TextStyle(color: Colors.black87, fontSize: 13)),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _paymentDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now().add(const Duration(days: 3650)),
                          );
                          if (picked != null) {
                            setState(() {
                              _paymentDate = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade500),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(DateFormat('dd/MM/yyyy').format(_paymentDate),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 14)),
                              const Icon(Icons.close, size: 16, color: Colors.black54),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Note
            const Text("Ghi chú khi thanh toán",
                style: TextStyle(color: Colors.black87, fontSize: 13)),
            const SizedBox(height: 4),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: "Ghi chú khi thanh toán",
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 32),
            
            // Bottom Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child: const Text("Đóng",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _submitPayment,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.attach_money, color: Colors.white, size: 18),
                    label: Text(_isSaving ? "Đang xử lý..." : "Thực hiện thu tiền",
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A651),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
