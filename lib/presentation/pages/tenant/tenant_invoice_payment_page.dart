import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TenantInvoicePaymentPage extends StatelessWidget {
  final String houseId;
  final String invoiceId;
  final Map<String, dynamic> invoiceData;
  final double remainingAmount;

  const TenantInvoicePaymentPage({
    super.key,
    required this.houseId,
    required this.invoiceId,
    required this.invoiceData,
    required this.remainingAmount,
  });

  String _formatCurrency(num value) {
    return NumberFormat.decimalPattern('vi_VN').format(value);
  }

  @override
  Widget build(BuildContext context) {
    final Timestamp? dueDateTs = invoiceData['dueDate'];
    final double paidAmount = (invoiceData['paidAmount'] ?? 0).toDouble();
    final double grandTotal = (invoiceData['grandTotal'] ?? 0).toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F8),
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "Thanh toán hóa đơn",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
            ),
            Text(
              "Chọn phương thức thanh toán",
              style: TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(height: 1, color: Colors.grey.shade200),
            const SizedBox(height: 24),
            
            // Due date text
            const Text(
              "Hạn chót thanh toán",
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              dueDateTs != null ? DateFormat('dd/MM/yyyy').format(dueDateTs.toDate()) : 'Không xác định',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
            ),
            
            const SizedBox(height: 24),
            
            // Two info blocks
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          children: [
                            const Text("Tổng cần thanh toán", style: TextStyle(color: Colors.black54, fontSize: 13)),
                            const SizedBox(height: 8),
                            Text("${_formatCurrency(grandTotal)} đ", style: const TextStyle(color: Color(0xFFE65100), fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                      ),
                    ),
                    VerticalDivider(width: 1, color: Colors.grey.shade200),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          children: [
                            const Text("Đã thanh toán", style: TextStyle(color: Colors.black54, fontSize: 13)),
                            const SizedBox(height: 8),
                            Text("${_formatCurrency(paidAmount)} đ", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Credit Card Icon Placeholder
            Container(
              width: 120,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.pink.shade400,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pink.withOpacity(0.3),
                    blurRadius: 10, offset: const Offset(5, 5)
                  )
                ]
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                       Container(
                         margin: const EdgeInsets.only(right: 8),
                         width: 24, height: 16,
                         decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)), // Fake mastercard
                       )
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text("VISA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  const Text("**** **** ****", style: TextStyle(color: Colors.white, fontSize: 10)),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Warning text
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                "Chủ nhà chưa cài đặt cổng thanh toán tự động. Vui lòng chọn chuyển khoản hoặc làm việc trực tiếp với chủ nhà bằng tiền mặt.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFE65100), fontSize: 14),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Payment Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Chọn phương thức",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentOption(
                    context,
                    title: "Chuyển khoản / Quét mã QR API",
                    subtitle: "Các ứng dụng ngân hàng và ví điện tử",
                    icon: Icons.qr_code_scanner,
                    color: Colors.blueAccent,
                    onTap: () {
                      _showPaymentSuccessDialog(context, "Chuyển khoản / Quét tiền");
                    }
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentOption(
                    context,
                    title: "Thanh toán Tiền mặt",
                    subtitle: "Đưa tiền trực tiếp cho chủ nhà lúc thu",
                    icon: Icons.money,
                    color: Colors.green,
                    onTap: () {
                       _handleCashPayment(context);
                    }
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black54),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentSuccessDialog(BuildContext context, String method) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận thanh toán"),
        content: Text("Bạn đã chọn thanh toán qua $method. Tính năng mô phỏng API ngân hàng hiện chưa tích hợp chức năng chuyển khoản thực tế."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Đóng", style: TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCashPayment(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF00A651))),
    );

    try {
      await FirebaseFirestore.instance
          .collection('houses')
          .doc(houseId)
          .collection('invoices')
          .doc(invoiceId)
          .update({'status': 'Chờ xác nhận'});
          
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi yêu cầu thanh toán tiền mặt. Vui lòng chờ chủ nhà xác nhận!'),
            backgroundColor: Color(0xFF00A651),
          ),
        );
        
        Navigator.pop(context); // Pop back out of payment page
        Navigator.pop(context); // Pop back out of detail page
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật: $e')),
        );
      }
    }
  }
}
