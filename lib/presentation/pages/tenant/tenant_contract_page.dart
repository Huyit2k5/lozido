import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TenantContractPage extends StatelessWidget {
  final Map<String, dynamic> contractData;
  final String contractId;

  const TenantContractPage({
    super.key,
    required this.contractData,
    required this.contractId,
  });

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    // Parsing dates
    final now = DateTime.now();
    DateTime? start;
    if (contractData['startDate'] is String) {
      try {
        start = DateFormat('dd/MM/yyyy').parse(contractData['startDate']);
      } catch (e) {
        start = null;
      }
    } else if (contractData['startDate'] is Timestamp) {
      start = (contractData['startDate'] as Timestamp).toDate();
    }

    DateTime? end;
    if (contractData['endDate'] is String) {
      try {
        end = DateFormat('dd/MM/yyyy').parse(contractData['endDate']);
      } catch (e) {
        end = null;
      }
    } else if (contractData['endDate'] is Timestamp) {
      end = (contractData['endDate'] as Timestamp).toDate();
    }
    
    DateTime? createdAt;
    if(contractData['createdAt'] is Timestamp) {
      createdAt = (contractData['createdAt'] as Timestamp).toDate();
    } else {
      createdAt = start;
    }

    // Status logic
    bool isActive = true;
    if(end != null && now.isAfter(end)) {
        isActive = false;
    }

    String shortId = contractId.length > 5 ? contractId.substring(0, 5).toUpperCase() : contractId;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('Thông tin hợp đồng', style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                   const SizedBox(height: 24),
                   Text(
                      'Hợp đồng (#$shortId)',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                   ),
                   const SizedBox(height: 8),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                        Container(
                           width: 8, height: 8,
                           decoration: BoxDecoration(
                             color: isActive ? Colors.green : Colors.red,
                             shape: BoxShape.circle
                           ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                           isActive ? 'Trong thời hạn hợp đồng' : 'Đã hết hạn hợp đồng',
                           style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500),
                        )
                     ],
                   ),
                   const SizedBox(height: 16),
                   
                   // Action Buttons
                   Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 16),
                     child: Row(
                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                       children: [
                         _buildActionButton(Icons.print, 'In / Tải PDF', Colors.black87, null),
                         _buildActionButton(Icons.assignment, 'Xem văn bản', const Color(0xFF00A651), null),
                         _buildActionButton(Icons.share, 'Chia sẻ', Colors.blue, null),
                       ],
                     ),
                   ),
                   
                   const SizedBox(height: 16),
                   Container(
                     decoration: const BoxDecoration(
                       color: Colors.white,
                       border: Border(
                         top: BorderSide(color: Color(0xFFEEEEEE)),
                         bottom: BorderSide(color: Color(0xFFEEEEEE)),
                       )
                     ),
                     child: Column(
                       children: [
                         _buildInfoRow('Người ký hợp đồng', contractData['phoneNumber'] ?? 'Chưa cập nhật', valueColor: Colors.blue, valueFontWeight: FontWeight.bold),
                         _buildDivider(),
                         _buildInfoRow('Tổng số thành viên', '${contractData['totalMembers'] ?? 1} \nngười', subtitle: 'Số thành viên đăng ký', richValue: true, valueBoldPart: '${contractData['totalMembers'] ?? 1} '),
                         _buildDivider(),
                         _buildInfoRow('Số tiền cọc', _formatCurrency((contractData['depositAmount'] ?? 0).toDouble()), subtitle: 'Hoàn trả / giảm trừ khi kết thúc h.đồng'),
                         _buildDivider(),
                         _buildInfoRow('Giá trị hợp đồng', _formatCurrency((contractData['rentPrice'] ?? 0).toDouble()), subtitle: 'Tiền thuê nhà'),
                         _buildDivider(),
                         _buildInfoRow('Chu kỳ thu tiền', '${contractData['paymentCycle'] ?? 1} tháng / 1 lần', subtitle: null),
                         _buildDivider(),
                         _buildInfoRow('Ngày đặt cọc', createdAt != null ? DateFormat('dd/MM/yyyy').format(createdAt) : 'N/A', subtitle: 'Là ngày lập hợp đồng'),
                         _buildDivider(),
                         _buildInfoRow('Ngày vào ở', start != null ? DateFormat('dd/MM/yyyy').format(start) : 'N/A', subtitle: 'Ngày chính thức dọn vào ở.'),
                         _buildDivider(),
                         _buildInfoRow('Ngày kết thúc hợp đồng', end != null ? DateFormat('dd/MM/yyyy').format(end) : 'Không thời hạn', subtitle: 'Ngày sẽ chấm dứt hợp đồng'),
                         _buildDivider(),
                         _buildInfoRow('Thời gian ở', 'Mới vào ở', subtitle: null, valueColor: const Color(0xFF00A651)),
                       ],
                     ),
                   ),
                   const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          
          // Bottom Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFEEEEEE)))
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Đóng', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE65100), // Orange
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    icon: const Icon(Icons.calendar_today, size: 18, color: Colors.white),
                    label: const Text('Báo kết thúc h.đồng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String title, Color iconColor, VoidCallback? onTap) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap ?? () {},
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      shape: BoxShape.circle
                    ),
                    child: Icon(icon, color: iconColor),
                  ),
                  const SizedBox(height: 8),
                  Text(title, style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, color: Color(0xFFEEEEEE));
  }

  Widget _buildInfoRow(String title, String value, {String? subtitle, Color? valueColor, FontWeight? valueFontWeight, bool richValue = false, String valueBoldPart = ""}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: subtitle != null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500)),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ]
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: richValue ? 
                   RichText(
                     textAlign: TextAlign.right,
                     text: TextSpan(
                       style: const TextStyle(color: Colors.black87, fontSize: 15),
                       children: [
                         TextSpan(text: valueBoldPart, style: const TextStyle(fontWeight: FontWeight.bold)),
                         TextSpan(text: value.replaceAll(valueBoldPart, '')),
                       ]
                     )
                   ) :
                   Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 15,
                color: valueColor ?? Colors.black87,
                fontWeight: valueFontWeight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
