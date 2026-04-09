import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../../widgets/setting_item_tile.dart';
import '../auth/login_page.dart';

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  String _appVersion = "3.0.6";
  String _buildNumber = "6";
  String _osInfo = "Unknown";
  String _deviceModel = "Unknown";

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final deviceInfo = DeviceInfoPlugin();

      String os = "Unknown";
      String model = "Unknown";
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        os = "Android ${androidInfo.version.release}";
        model = androidInfo.model;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        os = "iOS ${iosInfo.systemVersion}";
        model = iosInfo.name;
      }

      if (mounted) {
        setState(() {
          _appVersion = packageInfo.version;
          _buildNumber = packageInfo.buildNumber;
          _osInfo = os;
          _deviceModel = model;
        });
      }
    } catch (e) {
      debugPrint("Error loading device info: $e");
    }
  }

  Future<void> _handleLogout() async {
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Đăng xuất"),
            content: const Text("Bạn có chắc chắn muốn đăng xuất tài khoản?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Đăng xuất", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã sao chép mã khách hàng!'), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F8),
      appBar: AppBar(
        title: const Text(
          "Thêm",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('houses')
            .where('userId', isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          String houseName = "Nhan"; // Default as per image if none found
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
            houseName = (data['houseName'] ?? data['propertyName'] ?? "Nhan").toString();
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Profile & Customer ID Card
                _buildProfileCard(user, houseName),

                // Ad Promo Card
                _buildAdPromoCard(),

                // Settings List
                _buildSettingsList(),

                const SizedBox(height: 24),

                // Logout Action
                _buildLogoutAction(),

                const SizedBox(height: 24),

                // Social Media Section
                _buildSocialSection(),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(User? user, String houseName) {
    final displayId = (user?.uid.substring(0, 10) ?? "26OW00012844").toUpperCase();
    final formattedId = "#$displayId";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1877F2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 36),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Xin chào! $houseName",
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Chúc bạn một ngày làm việc hiệu quả!",
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F9F4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFD4EDDA)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.check_circle, color: Color(0xFF28A745), size: 16),
                            SizedBox(width: 6),
                            Text(
                              "Đã xác minh",
                              style: TextStyle(color: Color(0xFF28A745), fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.blue),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Mã khách hàng", style: TextStyle(color: Colors.black54, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      formattedId,
                      style: const TextStyle(color: Color(0xFF28A745), fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _copyToClipboard(formattedId),
                  icon: const Text("Sao chép", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
                  label: const Icon(Icons.copy, size: 18, color: Colors.black87),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5F6F8),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdPromoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF4081).withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFDDEB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.network(
              'https://cdn-icons-png.flaticon.com/512/3112/3112946.png', // Placeholder gift/ad icon
              width: 40,
              height: 40,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.card_giftcard, color: Color(0xFFFF4081), size: 40),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Tắt quảng cáo",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(
                  "LOZIDO đang áp dụng quảng cáo để có chi phí duy trì phần mềm. Bạn muốn sử dụng APP không có quảng cáo?",
                  style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFFFF4081)),
        ],
      ),
    );
  }

  Widget _buildSettingsList() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          _buildItem(Icons.public, "Công ty, nhóm - Q.lý thành viên", "Thêm tài khoản cùng sử dụng phần mềm"),
          const Divider(height: 1, indent: 56),
          _buildItem(Icons.card_giftcard, "LOZIDO Plus+", null, titleBadge: _buildBadge("PRO", Colors.orange)),
          const Divider(height: 1, indent: 56),
          _buildItem(Icons.bookmark_outline, "Cài đặt thương hiệu tòa nhà", "Cài đặt logo thương hiệu, website..."),
          const Divider(height: 1, indent: 56),
          _buildItem(Icons.person_outline, "Thông tin đại diện chủ tòa nhà", "Thông tin dùng làm mẫu hợp đồng, tạm trú cho khách thuê."),
          const Divider(height: 1, indent: 56),
          _buildItem(Icons.edit_outlined, "Cài đặt chữ ký số", "Dùng để thiết lập chữ ký hợp đồng, tạm trú cho khách thuê.", titleBadge: _buildBadge("Mới", Colors.green)),
          const Divider(height: 1, indent: 56),
          _buildItem(Icons.vpn_key_outlined, "Đổi mật khẩu", null),
          const Divider(height: 1, indent: 56),
          _buildItem(Icons.verified_user_outlined, "Cài đặt quyền phần mềm", "Cung cấp quyền giúp phần mềm hoạt động"),
          const Divider(height: 1, indent: 56),
          _buildItem(Icons.settings_outlined, "Cài đặt thông báo", null),
          const Divider(height: 1, indent: 56),
          _buildItem(Icons.chat_bubble_outline, "Trung tâm trợ giúp", null),
          const Divider(height: 1, indent: 56),
          _buildItem(Icons.share_outlined, "Chia sẻ APP khách thuê", "Khách kết nối với bạn, nhận hóa đơn tự động & nhiều tiện ích khác"),
          const Divider(height: 1, indent: 56),
          _buildItem(
            Icons.inventory_2_outlined,
            "Đánh giá phần mềm",
            "Một đánh giá tốt giúp LOZIDO thêm động lực hoàn thiện",
            subtitleWidget: Row(
              children: List.generate(5, (index) => const Icon(Icons.star, color: Colors.orange, size: 16)),
            ),
          ),
          const Divider(height: 1, indent: 56),
          _buildItem(Icons.info_outline, "Thông tin phần mềm", null),
          const Divider(height: 1, indent: 56),
          _buildItem(Icons.security_outlined, "Chính sách bảo mật", null),
          const Divider(height: 1, indent: 56),
          _buildItem(Icons.description_outlined, "Điều khoản sử dụng", null),
          const Divider(height: 1, indent: 56),
          _buildItem(
            Icons.layers_outlined,
            "Phiên bản phần mềm",
            null,
            trailingWidget: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("Version: $_appVersion / $_buildNumber", style: const TextStyle(fontSize: 12, color: Colors.black54)),
                const Text("production", style: TextStyle(fontSize: 10, color: Colors.black38)),
              ],
            ),
          ),
          const Divider(height: 1, indent: 56),
          _buildItem(
            Icons.phone_android_outlined,
            "Hệ điều hành",
            null,
            trailingWidget: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_osInfo, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                Text(_deviceModel, style: const TextStyle(fontSize: 10, color: Colors.black38)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildItem(IconData icon, String title, String? subtitle, {Widget? titleBadge, Widget? subtitleWidget, Widget? trailingWidget}) {
    return SettingItemTile(
      icon: icon,
      title: title,
      titleBadge: titleBadge,
      subtitle: subtitle,
      subtitleWidget: subtitleWidget,
      trailingWidget: trailingWidget,
      onTap: () {},
    );
  }

  Widget _buildLogoutAction() {
    return InkWell(
      onTap: _handleLogout,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.logout_rounded, color: Colors.red, size: 28),
          const SizedBox(width: 12),
          const Text(
            "Đăng xuất tài khoản",
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Chúng tôi trên mạng xã hội",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            "Theo dõi chúng tôi và cộng đồng để có thể thêm kinh nghiệm từ cộng đồng.",
            style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.8,
            children: [
              _buildSocialButton("Youtube", Icons.play_arrow_rounded, Colors.red),
              _buildSocialButton("Facebook", Icons.facebook, Colors.blue),
              _buildSocialButton("Tiktok", Icons.music_note, Colors.black),
              _buildSocialButton("ZALO", Icons.chat_bubble_rounded, Colors.blue.shade600),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(String label, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
