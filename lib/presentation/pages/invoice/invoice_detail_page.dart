import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'widgets/invoice_payment_sheet.dart';
import 'invoice_image_export_page.dart';

class InvoiceDetailPage extends StatefulWidget {
  final String houseId;
  final String invoiceId;
  final Map<String, dynamic> invoiceData;

  const InvoiceDetailPage({
    super.key,
    required this.houseId,
    required this.invoiceId,
    required this.invoiceData,
  });

  @override
  State<InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends State<InvoiceDetailPage> {
  late Map<String, dynamic> _data;

  @override
  void initState() {
    super.initState();
    _data = widget.invoiceData;
  }

  void _refreshData() {
    FirebaseFirestore.instance
        .collection('houses')
        .doc(widget.houseId)
        .collection('invoices')
        .doc(widget.invoiceId)
        .get()
        .then((doc) {
      if (doc.exists) {
        setState(() {
          _data = doc.data() as Map<String, dynamic>;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final String roomName = _data['roomName'] ?? '';
    final String tenantName = _data['tenantName'] ?? '';
    final String phone = _data['zaloUid'] ?? '';
    final String billingMonth = _data['billingMonth'] ?? '';
    final Timestamp? createdAt = _data['createdAt'];
    final Timestamp? dueDateTs = _data['dueDate'];
    final String reason = _data['reason'] ?? 'Thu tiền';
    final String status = _data['status'] ?? 'Chưa thu';

    final double grandTotal = (_data['grandTotal'] ?? 0).toDouble();
    final double paidAmount = (_data['paidAmount'] ?? 0).toDouble();
    final double remaining = grandTotal - paidAmount;
    final List<dynamic> payments = _data['payments'] ?? [];
    
    final double rentAmount = (_data['rentAmount'] ?? 0).toDouble();
    final double depositAmount = (_data['depositAmount'] ?? 0).toDouble();
    final Timestamp? rentStart = _data['rentStart'];
    final Timestamp? rentEnd = _data['rentEnd'];

    final bool isCancelled = status == 'Đã bị hủy';

    Color statusColor;
    switch (status) {
      case 'Đã thu xong':
        statusColor = Colors.green;
        break;
      case 'Đang nợ tiền':
        statusColor = Colors.red;
        break;
      case 'Chờ xác nhận':
        statusColor = Colors.blue;
        break;
      case 'Đã bị hủy':
        statusColor = Colors.grey;
        break;
      case 'Chưa thu':
      default:
        statusColor = Colors.orange;
        break;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F8),
      appBar: AppBar(
        title: const Text(
          "Chi tiết hóa đơn",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 1,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black87),
            onPressed: () {},
          )
        ],
      ),
      body: Column(
        children: [
          // Top Actions Row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTopAction(
                  icon: Icons.share_rounded,
                  label: "Gửi h.đơn",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InvoiceImageExportPage(
                          houseId: widget.houseId,
                          invoiceId: widget.invoiceId,
                          invoiceData: _data,
                        ),
                      ),
                    );
                  },
                ),
                _buildTopAction(
                  icon: Icons.phone_outlined,
                  label: "Gọi điện",
                  onTap: () async {
                    if (phone.isNotEmpty) {
                      final url = Uri.parse('tel:$phone');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      }
                    }
                  },
                ),
                _buildTopAction(
                  icon: Icons.cancel_outlined,
                  label: "Hủy h.đơn",
                  color: isCancelled ? Colors.grey : Colors.deepOrange,
                  onTap: isCancelled ? null : _cancelInvoice,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // General Info
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(roomName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text("Khách thuê: $tenantName",
                            style: const TextStyle(
                                color: Colors.black54, fontSize: 14)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildDateBox(
                                "Hóa đơn tháng",
                                "T.${billingMonth.split('/').first}, ${billingMonth.split('/').last}"),
                            _buildDateBox(
                                "Ngày lập hóa đơn",
                                createdAt != null
                                    ? DateFormat('dd/MM/yyyy')
                                        .format(createdAt.toDate())
                                    : ''),
                            _buildDateBox(
                                "Hạn nộp tiền",
                                dueDateTs != null
                                    ? DateFormat('dd/MM/yyyy')
                                        .format(dueDateTs.toDate())
                                    : ''),
                          ],
                        ),
                        const Divider(height: 32, color: Color(0xFFEEEEEE)),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Lý do thu",
                                      style: TextStyle(
                                          color: Colors.black54, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(reason,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                        color: statusColor,
                                        shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(status,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            )
                          ],
                        ),
                        const Divider(height: 32, color: Color(0xFFEEEEEE)),
                        // Breakdown
                        if (rentAmount > 0)
                          _buildBreakdownItem(
                            "Tiền thuê nhà",
                            rentStart != null && rentEnd != null
                                ? "Từ ${DateFormat('dd/MM').format(rentStart.toDate())} đến ${DateFormat('dd/MM/yyyy').format(rentEnd.toDate())}"
                                : "",
                            rentAmount,
                          ),
                        if (depositAmount > 0)
                          _buildBreakdownItem(
                            "Tiền cọc cần thu",
                            "Tiền cọc thuê phòng",
                            depositAmount,
                          ),
                        // You can map _data['services'] and _data['adjustments'] similarly if needed...
                        
                        const Divider(height: 32, color: Color(0xFFEEEEEE)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text("Tổng cộng kỳ này",
                                style: TextStyle(
                                    color: Colors.black54, fontSize: 13)),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text("${_formatCurrency(grandTotal)} đ",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  
                  // Payment Info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text("Đã trả",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(
                            paidAmount > 0
                                ? "Đã trả ${_formatCurrency(paidAmount)} đ"
                                : "Chưa trả lần nào, 1 phiếu có thể thu nhiều lần.",
                            style: TextStyle(
                                color: paidAmount > 0 ? Colors.green : Colors.deepOrange,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: remaining == 0 ? Colors.green : Colors.orange),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Số lần thanh toán",
                                style: TextStyle(
                                    color: Colors.black54, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text("${payments.length} lần",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text("Tổng phải thu",
                                style: TextStyle(
                                    color: Colors.black54, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text("${_formatCurrency(remaining)} đ",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
          
          if (!isCancelled && remaining > 0)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.attach_money, color: Colors.white),
                  label: Text(status == 'Chờ xác nhận' ? "Xác nhận & Thu tiền" : "Thu tiền",
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A651),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => InvoicePaymentSheet(
                        houseId: widget.houseId,
                        invoiceId: widget.invoiceId,
                        invoiceData: _data,
                      ),
                    ).then((value) {
                      if (value == true) {
                        _refreshData();
                      }
                    });
                  },
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildTopAction({
    required IconData icon,
    required String label,
    Color color = Colors.black87,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildDateBox(String title, String value) {
    return Expanded(
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          border: Border(
            right: title != "Hạn nộp tiền"
                ? BorderSide(color: Colors.grey.shade200)
                : BorderSide.none,
          ),
        ),
        child: Column(
          children: [
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, fontSize: 11)),
            const Spacer(),
            Text(value,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownItem(String title, String subtitle, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.black54, fontSize: 13)),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Colors.black87, fontSize: 12)),
                ]
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text("Thành tiền",
                  style: TextStyle(color: Colors.black54, fontSize: 13)),
              const SizedBox(height: 4),
              Text("${_formatCurrency(amount)} đ",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  void _cancelInvoice() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận hủy"),
        content: const Text("Bạn có chắc chắn muốn hủy hóa đơn này không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Đóng", style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // close dialog
              await FirebaseFirestore.instance
                  .collection('houses')
                  .doc(widget.houseId)
                  .collection('invoices')
                  .doc(widget.invoiceId)
                  .update({'status': 'Đã bị hủy'});
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Hóa đơn đã bị hủy')),
                );
                _refreshData();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Hủy hóa đơn", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(num value) {
    return NumberFormat('#,###', 'vi_VN').format(value);
  }
}
