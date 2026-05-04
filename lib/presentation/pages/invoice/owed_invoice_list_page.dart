import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lozido_app/core/utils/currency_formatter.dart';
import 'invoice_detail_page.dart';
import 'widgets/invoice_payment_sheet.dart';
import 'invoice_image_export_page.dart';

class OwedInvoiceListPage extends StatefulWidget {
  final String houseId;
  final Map<String, dynamic> houseData;

  const OwedInvoiceListPage({
    super.key,
    required this.houseId,
    required this.houseData,
  });

  @override
  State<OwedInvoiceListPage> createState() => _OwedInvoiceListPageState();
}

class _OwedInvoiceListPageState extends State<OwedInvoiceListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'roomNameAsc'; // Mặc định: Phòng tăng dần

  final Map<String, String> _sortLabels = {
    'roomNameAsc': 'Phòng tăng dần',
    'roomNameDesc': 'Phòng giảm dần',
    'dateAsc': 'Ngày tăng dần',
    'dateDesc': 'Ngày giảm dần',
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F8),
      appBar: AppBar(
        title: const Text(
          "Tất cả hóa đơn cần thu",
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
          _buildSearchSortRow(),
          Expanded(
            child: _buildInvoiceList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSortRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Hàng 1: Sắp xếp + nút X
          Row(
            children: [
              const Text("Sắp xếp theo ",
                  style: TextStyle(fontSize: 14, color: Colors.black87)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sortBy,
                    isDense: true,
                    style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                    icon: const Icon(Icons.arrow_drop_down,
                        color: Colors.blue, size: 20),
                    items: _sortLabels.entries.map((e) {
                      return DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value,
                            style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _sortBy = val);
                    },
                  ),
                ),
              ),
              const Spacer(),
              if (_searchQuery.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 16, color: Colors.black54),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // Hàng 2: Ô tìm kiếm
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: "Nhập tên phòng...",
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon:
                  const Icon(Icons.search, color: Colors.black54, size: 20),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
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
          return const Center(child: Text("Không có hóa đơn nào."));
        }

        var docs = snapshot.data!.docs;

        // Lọc chỉ lấy hóa đơn còn nợ (remaining > 0 && status != 'Đã bị hủy')
        docs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final grandTotal = (data['grandTotal'] ?? 0).toDouble();
          final paidAmount = (data['paidAmount'] ?? 0).toDouble();
          final status = data['status'] ?? '';
          return (grandTotal - paidAmount > 0) && status != 'Đã bị hủy';
        }).toList();

        // Tìm kiếm theo tên phòng
        if (_searchQuery.isNotEmpty) {
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final roomName =
                (data['roomName'] ?? '').toString().toLowerCase();
            return roomName.contains(_searchQuery);
          }).toList();
        }

        // Sắp xếp
        docs.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;
          final nameA = (dataA['roomName'] ?? '').toString();
          final nameB = (dataB['roomName'] ?? '').toString();
          final dateA = (dataA['createdAt'] as Timestamp?)?.toDate() ??
              DateTime(2000);
          final dateB = (dataB['createdAt'] as Timestamp?)?.toDate() ??
              DateTime(2000);

          switch (_sortBy) {
            case 'roomNameAsc':
              return nameA.compareTo(nameB);
            case 'roomNameDesc':
              return nameB.compareTo(nameA);
            case 'dateAsc':
              return dateA.compareTo(dateB);
            case 'dateDesc':
              return dateB.compareTo(dateA);
            default:
              return 0;
          }
        });

        if (docs.isEmpty) {
          return const Center(child: Text("Không tìm thấy hóa đơn phù hợp."));
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
    final String billingMonth = data['billingMonth'] ?? '';
    final double grandTotal = (data['grandTotal'] ?? 0).toDouble();
    final double paidAmount = (data['paidAmount'] ?? 0).toDouble();
    final double remaining = grandTotal - paidAmount;
    final String status = data['status'] ?? 'Chưa thu';
    final String phone = data['zaloUid'] ?? '';
    final bool hasApp = data['hasApp'] == true;
    final bool isSent = data['isSent'] == true;

    // Màu trạng thái
    Color statusColor;
    switch (status) {
      case 'Đang nợ tiền':
        statusColor = Colors.red;
        break;
      case 'Chưa thu':
      default:
        statusColor = Colors.orange;
        break;
    }

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
                          Flexible(
                            child: Text(
                              "$roomName ($dateStr)",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(reason,
                          style: const TextStyle(
                              color: Colors.black87, fontSize: 13)),
                      if (!hasApp) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: Colors.orange.shade700, size: 16),
                            const SizedBox(width: 4),
                            const Text("Khách chưa cài APP",
                                style: TextStyle(
                                    color: Colors.deepOrange,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Badge trạng thái
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
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
                          const SizedBox(width: 8),
                          // Badge gửi phiếu
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isSent
                                      ? Icons.check_circle
                                      : Icons.info_outline,
                                  size: 14,
                                  color:
                                      isSent ? Colors.green : Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isSent ? "Đã gửi phiếu" : "Chưa gửi phiếu",
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: isSent
                                          ? Colors.green
                                          : Colors.orange,
                                      fontWeight: FontWeight.w500),
                                ),
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
                      mainAxisSize: MainAxisSize.min,
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
          // Action Buttons: Gọi, Thu nhanh, Gửi h.đơn, In
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
                    if (remaining > 0) {
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
                const VerticalDivider(width: 1, color: Color(0xFFEEEEEE)),
                _buildActionButton(
                  icon: Icons.print_outlined,
                  iconColor: Colors.black87,
                  label: "In",
                  onTap: () {
                    // TODO: implement print functionality
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
                          style:
                              TextStyle(fontSize: 11, color: Colors.black54)),
                      const SizedBox(height: 4),
                      Text("${formatCurrency(grandTotal)} đ",
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
                            style:
                                TextStyle(fontSize: 11, color: Colors.green)),
                        const SizedBox(height: 4),
                        Text("${formatCurrency(paidAmount)} đ",
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
                          style:
                              TextStyle(fontSize: 11, color: Colors.black54)),
                      const SizedBox(height: 4),
                      Text("${formatCurrency(remaining)} đ",
                          style: TextStyle(
                              color:
                                  remaining > 0 ? Colors.red : Colors.black87,
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
              Flexible(
                child: Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
