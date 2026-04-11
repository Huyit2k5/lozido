import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ContractDetailPage extends StatelessWidget {
  final Map<String, dynamic> contractData;
  final String roomName;

  const ContractDetailPage({
    super.key,
    required this.contractData,
    required this.roomName,
  });

  String _formatCurrency(double amount) {
    return '${NumberFormat.decimalPattern('vi_VN').format(amount)} đ';
  }

  @override
  Widget build(BuildContext context) {
    final useApp = contractData['useApp'] ?? false;
    final status = contractData['status'] ?? 'Không xác định';
    final isSigned = status == 'Active'; // assuming active means signed
    
    final rentPrice = (contractData['rentPrice'] ?? 0).toDouble();
    final depositAmount = (contractData['depositAmount'] ?? 0).toDouble();
    final collectedDeposit = (contractData['collectedDeposit'] ?? 0).toDouble();
    final remainDeposit = depositAmount - collectedDeposit;

    final billingDate = contractData['billingDate'] ?? '';
    final paymentCycle = contractData['paymentCycle'] ?? 1;
    final totalMembers = contractData['totalMembers'] ?? 1;
    final tenantName = contractData['tenantName'] ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Xem chi tiết hợp đồng",
              style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              "$roomName - #${contractData['id']?.toString().substring(0, 5) ?? '150412'}",
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF00A651),
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 30),
            
            _buildInfoRow('Đơn vị thuê', roomName),
            _buildDivider(),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sử dụng APP khách thuê', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(
                          'Nhận hóa đơn tự động và nhiều tiện ích khác...',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        useApp ? Icons.check_circle_outline : Icons.info_outline,
                        color: useApp ? Colors.green : Colors.deepOrange,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        useApp ? 'Đã cài APP' : 'Khách chưa cài APP',
                        style: TextStyle(color: useApp ? Colors.green : Colors.deepOrange, fontSize: 14),
                      ),
                    ],
                  )
                ],
              ),
            ),
            _buildDivider(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tình trạng ký hợp đồng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Row(
                    children: [
                      Icon(
                        isSigned ? Icons.check : Icons.close,
                        color: isSigned ? Colors.green : Colors.deepOrange,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isSigned ? 'Đã ký hợp đồng' : 'Chưa ký hợp đồng',
                        style: TextStyle(color: isSigned ? Colors.green : Colors.deepOrange, fontSize: 14),
                      ),
                    ],
                  )
                ],
              ),
            ),
            _buildDivider(),

            _buildInfoRow('Tổng số thành viên', '$totalMembers/1 người'),
            _buildDivider(),

            _buildInfoRow('Đại diện cọc', tenantName),
            _buildDivider(),

            _buildInfoRow('Giá trị hợp đồng (Tiền thuê)', _formatCurrency(rentPrice), isBoldValue: true),
            _buildDivider(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mức giá cọc hợp đồng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_formatCurrency(depositAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      if (remainDeposit > 0)
                        Text('(Chưa thu đủ cọc)', style: TextStyle(color: Colors.deepOrange.shade400, fontSize: 13))
                      else if (depositAmount > 0)
                        Text('(Đã thu đủ cọc)', style: TextStyle(color: Colors.green.shade600, fontSize: 13))
                      else
                        Text('(Không có cọc)', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ],
                  )
                ],
              ),
            ),
            _buildDivider(),

            _buildInfoRow(
              'Ngày lập hóa đơn',
              billingDate.isEmpty ? 'Chưa cấu hình' : billingDate,
              valueColor: Colors.deepOrange,
              isBoldValue: true,
            ),
            _buildDivider(),

            _buildInfoRow('Chu kỳ thu tiền', '$paymentCycle tháng / 1 lần'),
            _buildDivider(),

            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text('Đóng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value, {Color? valueColor, bool isBoldValue = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.black87,
              fontWeight: isBoldValue ? FontWeight.bold : FontWeight.normal,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, thickness: 1, color: Colors.grey.shade200);
  }
}
