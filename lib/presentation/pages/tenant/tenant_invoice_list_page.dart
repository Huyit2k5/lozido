import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'tenant_invoice_detail_page.dart';

class TenantInvoiceListPage extends StatefulWidget {
  final String houseId;
  final String roomId;

  const TenantInvoiceListPage({
    super.key,
    required this.houseId,
    required this.roomId,
  });

  @override
  State<TenantInvoiceListPage> createState() => _TenantInvoiceListPageState();
}

class _TenantInvoiceListPageState extends State<TenantInvoiceListPage> {
  DateTime? _selectedMonth;
  String? _selectedReason; // Lý do thu

  final List<String> _reasons = [
    'Thu tiền',
    'Thu tiền cọc',
    'Thu khác',
  ];

  @override
  Widget build(BuildContext context) {
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
              "Danh sách hóa đơn",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
            ),
            Text(
              "Danh sách hóa đơn phát sinh khi thuê nhà",
              style: TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(height: 1, color: Colors.grey.shade200),
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
      child: Row(
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
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Chọn tháng của hóa...",
                            style: TextStyle(fontSize: 12, color: Colors.black54)),
                        const SizedBox(height: 4),
                        Text(
                          _selectedMonth != null
                              ? DateFormat('MM/yyyy').format(_selectedMonth!)
                              : "Chọn tháng",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
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
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isDense: true,
                  isExpanded: true,
                  hint: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Lý do thu",
                          style: TextStyle(fontSize: 12, color: Colors.black54)),
                      const SizedBox(height: 4),
                      Text(
                        _selectedReason ?? "Chọn giá trị",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                      ),
                    ],
                  ),
                  value: _selectedReason,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black87),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text("Tất cả lý do", style: TextStyle(fontSize: 13))),
                    ..._reasons.map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(r, style: const TextStyle(fontSize: 13)),
                        )),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedReason = val;
                    });
                  },
                ),
              ),
            ),
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
          .where('roomId', isEqualTo: widget.roomId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
           return const Center(child: CircularProgressIndicator(color: Color(0xFF00A651)));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Bên phía chủ nhà chưa tạo hóa đơn nào."));
        }

        var docs = snapshot.data!.docs;

        // Apply local sorts or filters because Firestore composite indexes might not exist
        if (_selectedMonth != null) {
          final monthStr = DateFormat('MM/yyyy').format(_selectedMonth!);
          docs = docs
              .where((doc) =>
                  (doc.data() as Map<String, dynamic>)['billingMonth'] ==
                  monthStr)
              .toList();
        }

        if (_selectedReason != null && _selectedReason!.isNotEmpty) {
          docs = docs.where((doc) {
             final reason = (doc.data() as Map<String, dynamic>)['reason'] ?? 'Thu tiền';
             // Simple contains check since "Thu tiền tháng đầu tiên" contains "Thu tiền"
             return (reason as String).contains(_selectedReason!);
          }).toList();
        }
        
        // Sort by createdAt descending locally
        docs.sort((a, b) {
           final dataA = a.data() as Map<String, dynamic>;
           final dataB = b.data() as Map<String, dynamic>;
           final tsA = dataA['createdAt'] as Timestamp?;
           final tsB = dataB['createdAt'] as Timestamp?;
           if(tsA == null && tsB == null) return 0;
           if(tsA == null) return 1;
           if(tsB == null) return -1;
           return tsB.compareTo(tsA);
        });

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

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
             color: Colors.black.withOpacity(0.04),
             blurRadius: 10,
             offset: const Offset(0, 4)
          ),
        ]
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            print("Tapped invoice: $invoiceId");
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TenantInvoiceDetailPage(
                  houseId: widget.houseId,
                  invoiceId: invoiceId,
                  invoiceData: data,
                ),
              ),
            );
          },
          child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon/Badge THÁNG
                Container(
                  width: 54,
                  height: 54,
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
                          displayMonthPart,
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
                            displayYearPart,
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
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.black87, fontSize: 15),
                          children: [
                            TextSpan(text: roomName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: " ($dateStr)", style: const TextStyle(color: Colors.black54, fontSize: 13)),
                          ]
                        )
                      ),
                      const SizedBox(height: 4),
                      Text("Lý do: $reason",
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
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
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
                          style: TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text("${_formatCurrency(grandTotal)} đ",
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text("Đã trả",
                          style: TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text("${_formatCurrency(paidAmount)} đ",
                          style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w800,
                              fontSize: 14)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text("Còn lại",
                          style: TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text("${_formatCurrency(remaining)} đ",
                          style: TextStyle(
                              color: remaining > 0 ? const Color(0xFFE53935) : Colors.black87, // Red color
                              fontWeight: FontWeight.w800,
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
      ),
    );
  }

  String _formatCurrency(num value) {
    return NumberFormat.decimalPattern('vi_VN').format(value);
  }
}
