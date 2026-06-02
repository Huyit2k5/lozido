import 'package:flutter/material.dart';
import 'increase_rent_page.dart';

class HouseSettingsPage extends StatelessWidget {
  final String houseId;
  final Map<String, dynamic> houseData;

  const HouseSettingsPage({
    super.key,
    required this.houseId,
    required this.houseData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Cài đặt nhà cho thuê",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header: Cài đặt cơ bản
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              color: const Color(0xFFEef1f0), // Very light greenish-gray
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("Cài đặt cơ bản", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                          SizedBox(height: 4),
                          Text(
                            "Một số thiết lập cơ bản cho hệ thống cho thuê của bạn",
                            style: TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // List Items Container
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                children: [
                  _buildSettingItem(
                    icon: Icons.account_tree_outlined,
                    title: "Nhóm phòng theo dãy/tầng",
                    subtitle: "Gom phòng theo là tầng, dãy, khu... để quản lý tốt hơn.",
                    onTap: () {},
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.payments_outlined,
                    title: "Tăng giá thuê",
                    subtitle: "Tăng giá thuê cho tất cả phòng hoặc chỉ 1 số phòng",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => IncreaseRentPage(houseId: houseId, houseData: houseData),
                        ),
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.business,
                    title: "Dịch vụ",
                    subtitle: "Tiền điện, nước, tiền rác, tiền wifi hay các tiền phụ thu khác...",
                    onTap: () {},
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.receipt_long_outlined,
                    title: "Cài đặt hóa đơn",
                    subtitle: "Các cài đặt hóa đơn như: Làm tròn, hình thức thanh toán, gửi tự qua ZALO, mã QR...",
                    onTap: () {},
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.account_balance_outlined,
                    title: "Cài đặt tài khoản ngân hàng",
                    subtitle: "Tài khoản cho khách thanh toán tiền thuê, gạch nợ tự động, hiển hiện mã QR trên hóa đơn",
                    badgeText: "PRO",
                    onTap: () {},
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.account_balance_wallet_outlined,
                    title: "Cài đặt thu/chi",
                    subtitle: "Cài danh mục, báo cáo... thu/chi",
                    onTap: () {},
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, color: Color(0xFFF3F4F6), indent: 56);
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    String? badgeText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.black87, size: 26),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      if (badgeText != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            badgeText,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ]
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}
