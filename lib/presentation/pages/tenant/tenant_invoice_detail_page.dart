import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'tenant_invoice_payment_page.dart';

class TenantInvoiceDetailPage extends StatelessWidget {
  final String houseId;
  final String invoiceId;
  final Map<String, dynamic> invoiceData;

  const TenantInvoiceDetailPage({
    super.key,
    required this.houseId,
    required this.invoiceId,
    required this.invoiceData,
  });

  String _formatCurrency(num value) {
    return NumberFormat.decimalPattern('vi_VN').format(value);
  }

  @override
  Widget build(BuildContext context) {
    final String roomName = invoiceData['roomName'] ?? '';
    final String billingMonth = invoiceData['billingMonth'] ?? '';
    final Timestamp? createdAt = invoiceData['createdAt'];
    final Timestamp? dueDateTs = invoiceData['dueDate'];
    final String reason = invoiceData['reason'] ?? 'Thu tiền';
    final String status = invoiceData['status'] ?? 'Chưa thu';

    final double grandTotal = (invoiceData['grandTotal'] ?? 0).toDouble();
    final double paidAmount = (invoiceData['paidAmount'] ?? 0).toDouble();
    final double remaining = grandTotal - paidAmount;
    final List<dynamic> payments = invoiceData['payments'] ?? [];
    
    final double rentAmount = (invoiceData['rentAmount'] ?? 0).toDouble();
    final double depositAmount = (invoiceData['depositAmount'] ?? 0).toDouble();
    final Timestamp? rentStart = invoiceData['rentStart'];
    final Timestamp? rentEnd = invoiceData['rentEnd'];

    Color statusColor;
    switch (status) {
      case 'Đã thu xong':
        statusColor = Colors.green;
        break;
      case 'Đang nợ tiền':
        statusColor = Colors.red;
        break;
      case 'Đã bị hủy':
        statusColor = Colors.grey;
        break;
      case 'Chưa thu':
      default:
        statusColor = const Color(0xFFF57C00); // Orange
        break;
    }

    String displayMonthPart = "";
    String displayYearPart = "";
    if (billingMonth.isNotEmpty && billingMonth.contains('/')) {
        final parts = billingMonth.split('/');
        if(parts.isNotEmpty) {
           displayMonthPart = "T.${parts[0]}";
           if(parts.length > 1) {
              displayYearPart = parts[1];
           }
        }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
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
              "Chi tiết hóa đơn",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
            ),
            Text(
              "Vui lòng đóng tiền thuê đúng hạn",
              style: TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        roomName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black87),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          _buildDateBox(
                              "Hóa đơn tháng", 
                              "$displayMonthPart, $displayYearPart"
                          ),
                          _buildDateBox(
                              "Ngày lập phiếu",
                              createdAt != null ? DateFormat('dd/MM/yyyy').format(createdAt.toDate()) : ''
                          ),
                          _buildDateBox(
                              "Hạn nạp tiền",
                              dueDateTs != null ? DateFormat('dd/MM/yyyy').format(dueDateTs.toDate()) : '',
                              isLast: true
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Lý do thu", style: TextStyle(color: Colors.black87, fontSize: 14)),
                              const SizedBox(height: 4),
                              Text(reason, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8, height: 8,
                                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                              Text(status, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFE0E0E0)),
                    
                    if (rentAmount > 0) ...[
                      _buildBreakdownItem(
                        "Tiền thuê",
                        rentStart != null && rentEnd != null
                            ? "${rentEnd.toDate().difference(rentStart.toDate()).inDays} ngày, giá: ${_formatCurrency(rentAmount)} đ"
                            : "Theo chu kỳ",
                        rentAmount,
                      ),
                      const Divider(height: 1, color: Color(0xFFE0E0E0)),
                    ],
                    
                    if (depositAmount > 0) ...[
                      _buildBreakdownItem(
                        "Thu tiền cọc",
                        "",
                        depositAmount,
                      ),
                      const Divider(height: 1, color: Color(0xFFE0E0E0)),
                    ],
                    
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text("Tổng cộng kỳ này", style: TextStyle(color: Colors.black87, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text("${_formatCurrency(grandTotal)} đ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Bottom Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6), // Slightly darker gray for the bottom bar
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Số lần trả", style: TextStyle(color: Colors.black54, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text("${payments.length} lần, ${_formatCurrency(paidAmount)} đ", 
                            style: const TextStyle(color: Color(0xFF00A651), fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text("Số tiền còn lại", style: TextStyle(color: Colors.black54, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text("${_formatCurrency(remaining)} đ", 
                            style: const TextStyle(color: Color(0xFFF57C00), fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A651), // Green
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      if (remaining > 0) {
                         Navigator.push(
                           context,
                           MaterialPageRoute(
                             builder: (context) => TenantInvoicePaymentPage(
                               houseId: houseId,
                               invoiceId: invoiceId,
                               invoiceData: invoiceData,
                               remainingAmount: remaining,
                             ),
                           ),
                         );
                      } else {
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text('Hóa đơn này đã được thanh toán xong!')),
                         );
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text("\$ ", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text("Thanh toán hóa đơn", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    )
                  ),
                ),
                const SizedBox(height: 8), // Padding equivalent for bottom safe area
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDateBox(String title, String value, {bool isLast = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            right: !isLast ? BorderSide(color: Colors.grey.shade300) : BorderSide.none,
          ),
        ),
        child: Column(
          children: [
            Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black87, fontSize: 14)),
            const SizedBox(height: 4),
            Text(value, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownItem(String title, String subtitle, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.black87, fontSize: 14)),
              const Text("Thành tiền", style: TextStyle(color: Colors.black87, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(subtitle, style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.bold)),
              ),
              Text("${_formatCurrency(amount)} đ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }
}

