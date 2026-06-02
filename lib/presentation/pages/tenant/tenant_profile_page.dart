import 'package:flutter/material.dart';

class TenantProfilePage extends StatelessWidget {
  final Map<String, dynamic> userData;

  const TenantProfilePage({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light background to match design
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Phần Header (Thông tin người dùng)
                _buildUserHeader(),
                const SizedBox(height: 16),

                // Nhóm Cài đặt chính
                _buildMainSettingsGroup(),
                const SizedBox(height: 16),

                // Nhóm Cài đặt Khác & Hệ thống
                _buildSystemSettingsGroup(),
                const SizedBox(height: 16),

                // Mạng Xã Hội
                _buildSocialMediaSection(),
                const SizedBox(height: 16),

                // Kênh Hỗ Trợ
                _buildSupportSection(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 40),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xin chào! ${userData['name'] ?? 'Bạn'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Chúc bạn một ngày học tập, làm việc v...',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.circle, size: 8, color: Colors.black87),
                      SizedBox(width: 4),
                      Text(
                        'Chưa được xác minh',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
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
    );
  }

  Widget _buildMainSettingsGroup() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
             color: Colors.black.withOpacity(0.02),
             blurRadius: 8, offset: const Offset(0, 2)
          )
        ]
      ),
      child: Column(
        children: [
          _buildListTile(
            icon: Icons.receipt_long,
            iconColor: Colors.green.shade400,
            title: 'Thiết lập thuê phòng',
            subtitle: 'Kết nối chủ nhà, thông báo tìm trọ, căn hộ...',
            showDivider: true,
            trailingIcon: Icons.chevron_right,
            trailingColor: Colors.blue,
          ),
          _buildListTile(
            icon: Icons.work_outline,
            iconColor: Colors.orange.shade400,
            title: 'Thiết lập hồ sơ việc',
            subtitle: 'Profile, CV, nhận thông báo tin',
            showDivider: false,
            trailingIcon: Icons.chevron_right,
            trailingColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildSystemSettingsGroup() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
             color: Colors.black.withOpacity(0.02),
             blurRadius: 8, offset: const Offset(0, 2)
          )
        ]
      ),
      child: Column(
        children: [
          _buildListTile(
            icon: Icons.draw_outlined,
            title: 'Cài đặt chữ ký số',
            subtitle: 'Dùng để ký hợp đồng, đăng ký tạm trú',
            showDivider: true,
          ),
          _buildListTile(
            icon: Icons.vpn_key_outlined,
            title: 'Đổi mật khẩu',
            subtitle: 'Đang là mật khẩu mặc định. Đổi mk để bảo mật hơn!',
            subtitleColor: Colors.red,
            showDivider: true,
          ),
          _buildListTile(
            icon: Icons.person_outline,
            title: 'Xác minh số điện thoại',
            subtitle: 'Xác minh tài khoản qua số điện thoại',
            showDivider: true,
          ),
          _buildListTile(
            icon: Icons.shield_outlined,
            title: 'Cài đặt quyền ứng dụng',
            subtitle: 'Cung cấp quyền giúp ứng dụng hoạt động',
            showDivider: true,
          ),
          _buildListTile(
            icon: Icons.info_outline,
            title: 'Thông tin ứng dụng',
            showDivider: true,
          ),
          _buildListTile(
            icon: Icons.security_outlined,
            title: 'Chính sách bảo mật',
            showDivider: true,
          ),
          _buildListTile(
            icon: Icons.menu_book_outlined,
            title: 'Điều khoản sử dụng',
            showDivider: true,
          ),
          _buildListTile(
            icon: Icons.layers_outlined,
            title: 'Phiên bản ứng dụng',
            trailingText: 'Version 1.3.7 / 9\nprod',
            trailingTextAlign: TextAlign.right,
            showDivider: true,
          ),
          _buildListTile(
            icon: Icons.language,
            title: 'Hệ điều hành',
            trailingText: 'Android 33\nOPPO Reno6 Z 5G',
            trailingTextAlign: TextAlign.right,
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSocialMediaSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
             color: Colors.black.withOpacity(0.02),
             blurRadius: 8, offset: const Offset(0, 2)
          )
        ]
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chúng tôi trên mạng xã hội',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Theo dõi chúng tôi và cộng đồng để có thể thêm kinh nghiệm từ cộng đồng.',
            style: TextStyle(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSocialButton(
                  iconPath: Icons.play_arrow,
                  iconColor: Colors.red,
                  label: 'Youtube',
                  labelColor: Colors.red,
                  borderColor: Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSocialButton(
                  iconPath: Icons.facebook,
                  iconColor: Colors.blue.shade700,
                  label: 'Facebook',
                  labelColor: Colors.blue.shade700,
                  borderColor: Colors.blue.shade200,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSocialButton(
                  iconPath: Icons.music_note, // Tiktok placeholder icon
                  iconColor: Colors.black,
                  label: 'Tiktok',
                  labelColor: Colors.black,
                  borderColor: Colors.black,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSocialButton(
                  iconPath: Icons.chat, // Zalo placeholder icon
                  iconColor: Colors.blue,
                  label: 'ZALO',
                  labelColor: Colors.blue,
                  borderColor: Colors.blue.shade200,
                  iconWidget: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Zalo', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                  )
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
             color: Colors.black.withOpacity(0.02),
             blurRadius: 8, offset: const Offset(0, 2)
          )
        ]
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Kênh hỗ trợ của chúng tôi',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      'Chuyên viên luôn sẵn sàng hỗ trợ 24/7',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSupportButton(
            icon: Icons.phone,
            iconColor: Colors.green,
            label: 'Gọi điện trực tiếp (sẵn sàng)',
          ),
          const SizedBox(height: 12),
          _buildSupportButton(
            icon: Icons.chat,
            iconColor: Colors.blue,
            label: 'Chat/Gọi điện qua Zalo (sẵn sàng)',
            isZalo: true,
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    Color iconColor = Colors.black87,
    required String title,
    String? subtitle,
    Color subtitleColor = Colors.black54,
    bool showDivider = false,
    IconData trailingIcon = Icons.chevron_right,
    Color trailingColor = Colors.grey,
    String? trailingText,
    TextAlign trailingTextAlign = TextAlign.left,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailingText != null)
                Text(
                  trailingText,
                  textAlign: trailingTextAlign,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                )
              else
                Icon(trailingIcon, color: trailingColor),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, color: Color(0xFFEEEEEE), indent: 56),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData iconPath,
    required Color iconColor,
    required String label,
    required Color labelColor,
    required Color borderColor,
    Widget? iconWidget,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (iconWidget != null) iconWidget else Icon(iconPath, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportButton({
    required IconData icon,
    required Color iconColor,
    required String label,
    bool isZalo = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          if (isZalo)
             Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Zalo', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              )
          else
            Icon(icon, color: iconColor),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 32), // Balance out the icon width for centering text
        ],
      ),
    );
  }
}
