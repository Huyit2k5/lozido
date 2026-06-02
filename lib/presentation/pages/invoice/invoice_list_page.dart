import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'invoice_detail_page.dart';
import 'widgets/invoice_payment_sheet.dart';
import 'invoice_image_export_page.dart';

class InvoiceListPage extends StatefulWidget {
  final String houseId;
  final Map<String, dynamic> houseData;

  const InvoiceListPage({
    super.key,
    required this.houseId,
    required this.houseData,
  });

  @override
  State<InvoiceListPage> createState() => _InvoiceListPageState();
}

class _InvoiceListPageState extends State<InvoiceListPage> {
  DateTime? _selectedMonth;
  String? _selectedStatus;

  final List<String> _statuses = [
    'Chưa thu',
    'Chờ xác nhận',
    'Đang nợ tiền',
    'Đã thu xong',
    'Đã bị hủy',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F8),
      appBar: AppBar(
        title: const Text(
          "Tất cả hóa đơn",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 1,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: _buildInvoiceList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.filter_list, size: 20, color: Colors.black87),
                  SizedBox(width: 8),
                  Text("Lọc theo", style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    _selectedMonth = null;
                    _selectedStatus = null;
                  });
                },
                child: Row(
                  children: const [
                    Text("Tìm nâng cao",
                        style: TextStyle(
                            decoration: TextDecoration.underline,
                            color: Colors.black54)),
                    Icon(Icons.arrow_drop_down, size: 20, color: Colors.black54),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedMonth ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedMonth = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Tháng lập hóa đơn",
                                style: TextStyle(
                                    fontSize: 12, color: Colors.black54)),
                            const SizedBox(height: 4),
                            Text(
                              _selectedMonth != null
                                  ? DateFormat('MM/yyyy')
                                      .format(_selectedMonth!)
                                  : "Chọn tháng",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        const Icon(Icons.calendar_month, color: Colors.black87),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isDense: true,
                      isExpanded: true,
                      hint: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("Trạng thái hóa đơn",
                              style: TextStyle(
                                  fontSize: 12, color: Colors.black54)),
                          SizedBox(height: 4),
                          Text("Chọn giá trị",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.black87)),
                        ],
                      ),
                      value: _selectedStatus,
                      icon: const Icon(Icons.keyboard_arrow_down,
                          color: Colors.black87),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text("Tất cả trạng thái", style: TextStyle(fontSize: 13))),
                        ..._statuses.map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s, style: const TextStyle(fontSize: 13)),
                            )),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedStatus = val;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('houses')
          .doc(widget.houseId)
          .collection('invoices')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Chưa có hóa đơn nào thiết lập."));
        }

        var docs = snapshot.data!.docs;

        // Apply filters
        if (_selectedMonth != null) {
          final monthStr = DateFormat('MM/yyyy').format(_selectedMonth!);
          docs = docs
              .where((doc) =>
                  (doc.data() as Map<String, dynamic>)['billingMonth'] ==
                  monthStr)
              .toList();
        }

        if (_selectedStatus != null && _selectedStatus!.isNotEmpty) {
          docs = docs
              .where((doc) =>
                  (doc.data() as Map<String, dynamic>)['status'] ==
                  _selectedStatus)
              .toList();
        }

        if (docs.isEmpty) {
          return const Center(child: Text("Không có hóa đơn phù hợp."));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final id = doc.id;
            return _buildInvoiceCard(id, data);
          },
        );
      },
    );
  }

  Widget _buildInvoiceCard(String invoiceId, Map<String, dynamic> data) {
    final String roomName = data['roomName'] ?? '';
    final String reason = data['reason'] ?? 'Thu tiền';
    final Timestamp? createdAt = data['createdAt'];
    final String dateStr = createdAt != null
        ? DateFormat('dd/MM/yyyy').format(createdAt.toDate())
        : '';
    final String billingMonth = data['billingMonth'] ?? ''; // e.g. "04/2026"
    final double grandTotal = (data['grandTotal'] ?? 0).toDouble();
    final double paidAmount = (data['paidAmount'] ?? 0).toDouble();
    final double remaining = grandTotal - paidAmount;
    final String status = data['status'] ?? 'Chưa thu';
    final String phone = data['zaloUid'] ?? '';

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

    final bool isCancelled = status == 'Đã bị hủy';

    return Container(
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
      child: Opacity(
        opacity: isCancelled ? 0.6 : 1.0,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon/Badge THÁNG
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(color: statusColor.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          color: statusColor,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            "T.${billingMonth.split('/').first}",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              billingMonth.split('/').last,
                              style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Thông tin
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              roomName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(width: 6),
                            Text("($dateStr)",
                                style: const TextStyle(
                                    color: Colors.black54, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(reason,
                            style: const TextStyle(
                                color: Colors.black87, fontSize: 13)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(status,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Nút Chi tiết
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InvoiceDetailPage(
                            houseId: widget.houseId,
                            invoiceId: invoiceId,
                            invoiceData: data,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: const [
                          Text("Chi tiết",
                              style: TextStyle(
                                  color: Colors.blueAccent, fontSize: 13)),
                          Icon(Icons.chevron_right,
                              size: 16, color: Colors.blueAccent),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            // Action Buttons
            IntrinsicHeight(
              child: Row(
                children: [
                  _buildActionButton(
                    icon: Icons.phone,
                    iconColor: Colors.blueAccent,
                    label: "Gọi",
                    onTap: () async {
                      if (phone.isNotEmpty) {
                        final url = Uri.parse('tel:$phone');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      }
                    },
                  ),
                  const VerticalDivider(width: 1, color: Color(0xFFEEEEEE)),
                  _buildActionButton(
                    icon: Icons.attach_money,
                    iconColor: Colors.black87,
                    label: "Thu nhanh",
                    onTap: () {
                      if (!isCancelled && remaining > 0) {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => InvoicePaymentSheet(
                            houseId: widget.houseId,
                            invoiceId: invoiceId,
                            invoiceData: data,
                          ),
                        );
                      }
                    },
                  ),
                  const VerticalDivider(width: 1, color: Color(0xFFEEEEEE)),
                  _buildActionButton(
                    icon: Icons.send_outlined,
                    iconColor: Colors.black87,
                    label: "Gửi h.đơn",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InvoiceImageExportPage(
                            houseId: widget.houseId,
                            invoiceId: invoiceId,
                            invoiceData: data,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            // Footer (Tổng số, Đã trả, Còn lại)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Tổng số",
                            style: TextStyle(fontSize: 11, color: Colors.black54)),
                        const SizedBox(height: 4),
                        Text("${_formatCurrency(grandTotal)} đ",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Text("Đã trả",
                              style: TextStyle(fontSize: 11, color: Colors.green)),
                          const SizedBox(height: 4),
                          Text("${_formatCurrency(paidAmount)} đ",
                              style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text("Còn lại",
                            style: TextStyle(fontSize: 11, color: Colors.black54)),
                        const SizedBox(height: 4),
                        Text("${_formatCurrency(remaining)} đ",
                            style: TextStyle(
                                color: remaining > 0 ? Colors.red : Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCurrency(num value) {
    return NumberFormat('#,###', 'vi_VN').format(value);
  }
}
