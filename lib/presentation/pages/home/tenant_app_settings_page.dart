import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TenantAppSettingsPage extends StatefulWidget {
  final String houseId;
  final Map<String, dynamic> houseData;

  const TenantAppSettingsPage({
    super.key,
    required this.houseId,
    required this.houseData,
  });

  @override
  State<TenantAppSettingsPage> createState() => _TenantAppSettingsPageState();
}

class _TenantAppSettingsPageState extends State<TenantAppSettingsPage> {
  bool _isLoading = false;
  late TextEditingController _passwordController;

  // Settings values
  bool _autoCreateAccount = false;
  bool _allowTenantMeterCheck = false;
  bool _allowTenantUpdateInfo = true;
  bool _allowTenantUpdateVehicle = true;
  bool _allowTenantEndContractOnline = true;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController(text: "lozido123");
    _loadSettings();
  }

  void _loadSettings() {
    final settings = widget.houseData['tenantAppSettings'] as Map<String, dynamic>?;
    if (settings != null) {
      setState(() {
        _autoCreateAccount = settings['autoCreateAccount'] ?? false;
        _passwordController.text = settings['defaultPassword'] ?? "lozido123";
        _allowTenantMeterCheck = settings['allowTenantMeterCheck'] ?? false;
        _allowTenantUpdateInfo = settings['allowTenantUpdateInfo'] ?? true;
        _allowTenantUpdateVehicle = settings['allowTenantUpdateVehicle'] ?? true;
        _allowTenantEndContractOnline = settings['allowTenantEndContractOnline'] ?? true;
      });
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);

    try {
      final settings = {
        'autoCreateAccount': _autoCreateAccount,
        'defaultPassword': _passwordController.text.trim(),
        'allowTenantMeterCheck': _allowTenantMeterCheck,
        'allowTenantUpdateInfo': _allowTenantUpdateInfo,
        'allowTenantUpdateVehicle': _allowTenantUpdateVehicle,
        'allowTenantEndContractOnline': _allowTenantEndContractOnline,
      };

      await FirebaseFirestore.instance
          .collection('houses')
          .doc(widget.houseId)
          .update({
        'tenantAppSettings': settings,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lưu thay đổi thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi lưu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Cài đặt APP khách thuê",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      
                      // Auto Create Account Switch
                      _buildSwitchTile(
                        icon: Icons.person_add_alt_1_outlined,
                        title: "Tự động tạo tài khoản cho khách",
                        subtitle: "Tự động tạo tài khoản cho khách sử dụng APP khi lập hợp đồng bằng SĐT",
                        value: _autoCreateAccount,
                        onChanged: (val) => setState(() => _autoCreateAccount = val),
                      ),
                      
                      const Divider(height: 32),
                      
                      // Default Password Section
                      const Text(
                        "Mật khoản tài khoản cho khách *",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Mật khẩu mặc định dùng tạo tài khoản cho khách",
                        style: TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          hintText: "Nhập mật khẩu",
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.black12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.black12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "* Nhắc nhở khách thay đổi mật khẩu đăng nhập lần đầu tiên!",
                        style: TextStyle(color: Colors.orange, fontSize: 13),
                      ),
                      
                      const Divider(height: 32),
                      
                      // Meter Check Switch
                      _buildSwitchTile(
                        icon: Icons.speed_outlined,
                        title: "Cho phép khách chốt đồng hồ",
                        subtitle: "Khi tới kỳ hóa đơn khách thuê tự chốt điện nước. Giúp bạn tiết kiệm thời gian",
                        value: _allowTenantMeterCheck,
                        onChanged: (val) => setState(() => _allowTenantMeterCheck = val),
                        trailingAction: GestureDetector(
                          onTap: () {},
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.help_outline, size: 16, color: Colors.blue),
                              SizedBox(width: 4),
                              Text(
                                "Tìm hiểu tính năng",
                                style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const Divider(height: 32),

                      // Update Info Switch
                      _buildSwitchTile(
                        icon: Icons.shield_outlined,
                        title: "Cho phép thêm, sửa thông tin khách thuê",
                        subtitle: "Khách có thể tự thêm thành viên, sửa thông tin thành viên",
                        value: _allowTenantUpdateInfo,
                        onChanged: (val) => setState(() => _allowTenantUpdateInfo = val),
                      ),
                      
                      const Divider(height: 32),

                      // Update Vehicle Switch
                      _buildSwitchTile(
                        icon: Icons.motorcycle_outlined,
                        title: "Cho phép thêm, sửa thông tin xe",
                        subtitle: "Khách có thể tự thêm sửa thông tin xe của mình",
                        value: _allowTenantUpdateVehicle,
                        onChanged: (val) => setState(() => _allowTenantUpdateVehicle = val),
                      ),
                      
                      const Divider(height: 32),

                      // End Contract Online Switch
                      _buildSwitchTile(
                        icon: Icons.home_work_outlined,
                        title: "Cho phép báo kết thúc hợp đồng online",
                        subtitle: "Khách có thể báo kết thúc hợp đồng trên APP của mình",
                        value: _allowTenantEndContractOnline,
                        onChanged: (val) => setState(() => _allowTenantEndContractOnline = val),
                      ),
                      
                      const SizedBox(height: 100), // Space for save button
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Save Button Section
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A651),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Lưu thay đổi",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Widget? trailingAction,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.blue.shade300, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF00A651),
            ),
          ],
        ),
        if (trailingAction != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: trailingAction,
          ),
        ],
      ],
    );
  }
}
