import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../auth/login_page.dart';
import 'profile_page.dart';

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
        surfaceTintColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          String userName = "Người dùng";
          if (snapshot.hasData && snapshot.data!.data() != null) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            userName = (data['name'] ?? "Người dùng").toString();
          }

          final displayId = (user?.uid.substring(0, 10) ?? "Unknown").toUpperCase();
          final formattedId = "#$displayId";

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // ── Profile card (top part: avatar + info) ──
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  ),
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1877F2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person, color: Colors.white, size: 36),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Xin chào! $userName",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                "Chúc bạn một ngày làm việc hiệu quả!",
                                style: TextStyle(fontSize: 13, color: Colors.black54),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: const [
                                  Icon(Icons.circle, color: Color(0xFF00A651), size: 10),
                                  SizedBox(width: 4),
                                  Text(
                                    "Đã xác minh",
                                    style: TextStyle(
                                      color: Color(0xFF00A651),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Color(0xFF1877F2)),
                      ],
                    ),
                  ),
                ),

                // ── Mã khách hàng (bottom part of profile) ──
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Column(
                    children: [
                      const Divider(height: 1, color: Color(0xFFEEEEEE)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Mã khách hàng",
                                style: TextStyle(color: Colors.black54, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                formattedId,
                                style: const TextStyle(
                                  color: Color(0xFF00A651),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: formattedId));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đã sao chép mã tài khoản!'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F4F8),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: const [
                                  Text(
                                    "Sao chép",
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(Icons.copy_outlined, size: 17, color: Colors.black54),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // ── Tắt quảng cáo Card ──
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFF4081).withValues(alpha: 0.6), width: 1.2),
                  ),
                  child: Row(
                    children: [
                      // "Ad" box icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFDDEB),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 36,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                "Ad",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "Tắt quảng cáo",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            SizedBox(height: 3),
                            Text(
                              "LOZIDO đang áp dụng quảng cáo để có chi phí duy trì phần mềm. Bạn muốn sử dụng APP không có quảng cáo?",
                              style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, color: Color(0xFFFF4081)),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // ── Settings List ──
                _buildSettingsSection(),

                const SizedBox(height: 16),

                // ── Logout ──
                _buildLogoutAction(),

                const SizedBox(height: 16),

                // ── Social Section ──
                _buildSocialSection(),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildSettingItem(
            icon: Icons.public_outlined,
            title: "Công ty, nhóm - Q.lý thành viên",
            subtitle: "Thêm tài khoản cùng sử dụng phần mềm",
          ),
          _buildDivider(),
          _buildSettingItem(
            icon: Icons.card_giftcard_outlined,
            title: "LOZIDO Plus+",
            badge: _buildBadge("PRO", Colors.orange),
          ),
          _buildDivider(),
          _buildSettingItem(
            icon: Icons.bookmark_border_outlined,
            title: "Cài đặt thương hiệu tòa nhà",
            subtitle: "Cài đặt logo thương hiệu, website...",
          ),
          _buildDivider(),
          _buildSettingItem(
            icon: Icons.person_outline,
            title: "Thông tin đại diện chủ tòa nhà",
            subtitle: "Thông tin dùng làm mẫu hợp đồng, tạm trú cho khách thuê.",
          ),
          _buildDivider(),
          _buildSettingItem(
            icon: Icons.edit_outlined,
            title: "Cài đặt chữ ký số",
            subtitle: "Dùng để thiết lập chữ ký hợp đồng, tạm trú cho khách thuê.",
            badge: _buildBadge("Mới", const Color(0xFF00A651)),
          ),
          _buildDivider(),
          _buildSettingItem(
            icon: Icons.vpn_key_outlined,
            title: "Đổi mật khẩu",
          ),
          _buildDivider(),
          _buildSettingItem(
            icon: Icons.shield_outlined,
            title: "Cài đặt quyền phần mềm",
            subtitle: "Cung cấp quyền giúp phần mềm hoạt động",
          ),
          _buildDivider(),
          _buildSettingItem(
            icon: Icons.settings_outlined,
            title: "Cài đặt thông báo",
          ),
          _buildDivider(),
          _buildSettingItem(
            icon: Icons.chat_bubble_outline,
            title: "Trung tâm trợ giúp",
          ),
          _buildDivider(),
          _buildSettingItem(
            icon: Icons.share_outlined,
            title: "Chia sẻ APP khách thuê",
            subtitle: "Khách kết nối với bạn, nhận hóa đơn tự động & nhiều tiện ích khác",
          ),
          _buildDivider(),
          _buildSettingItem(
            icon: Icons.inventory_2_outlined,
            title: "Đánh giá phần mềm",
            subtitle: "Một đánh giá tốt giúp LOZIDO thêm động lực hoàn thiện",
            subtitleWidget: Row(
              children: List.generate(
                5,
                (i) => const Icon(Icons.star, color: Colors.orange, size: 16),
              ),
            ),
          ),
          _buildDivider(),
          _buildSettingItem(
            icon: Icons.info_outline,
            title: "Thông tin phần mềm",
          ),
          _buildDivider(),
          _buildSettingItem(
            icon: Icons.security_outlined,
            title: "Chính sách bảo mật",
          ),
          _buildDivider(),
          _buildSettingItem(
            icon: Icons.description_outlined,
            title: "Điều khoản sử dụng",
          ),
          _buildDivider(),
          _buildSettingItem(
            icon: Icons.layers_outlined,
            title: "Phiên bản phần mềm",
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "Version: $_appVersion / $_buildNumber",
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const Text(
                  "production",
                  style: TextStyle(fontSize: 11, color: Colors.black38),
                ),
              ],
            ),
          ),
          _buildDivider(),
          _buildSettingItem(
            icon: Icons.phone_android_outlined,
            title: "Hệ điều hành",
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_osInfo, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                Text(_deviceModel, style: const TextStyle(fontSize: 11, color: Colors.black38)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 52, color: Color(0xFFF0F0F0));
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? subtitleWidget,
    Widget? badge,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 22, color: Colors.black54),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        badge,
                      ],
                    ],
                  ),
                  if (subtitleWidget != null) ...[
                    const SizedBox(height: 3),
                    subtitleWidget,
                  ] else if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.black45, height: 1.4),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else
              const Icon(Icons.chevron_right, color: Colors.black38, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildLogoutAction() {
    return Center(
      child: InkWell(
        onTap: _handleLogout,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.logout_rounded, color: Colors.red, size: 22),
              SizedBox(width: 10),
              Text(
                "Đăng xuất tài khoản",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Chúng tôi trên mạng xã hội",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 6),
          const Text(
            "Theo dõi chúng tôi và cộng đồng để có thể thêm kinh nghiệm từ cộng đồng.",
            style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildSocialButton("Youtube", Icons.play_circle_fill, Colors.red)),
              const SizedBox(width: 10),
              Expanded(child: _buildSocialButton("Facebook", Icons.facebook, const Color(0xFF1877F2))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildSocialButton("Tiktok", Icons.music_note_rounded, Colors.black87)),
              const SizedBox(width: 10),
              Expanded(child: _buildSocialButton("ZALO", Icons.chat_bubble_outline, const Color(0xFF0084FF))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(String label, IconData icon, Color color) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.7), width: 1.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
