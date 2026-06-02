import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TenantListPage extends StatefulWidget {
  final String houseId;
  final String roomId;
  final Map<String, dynamic> roomData;

  const TenantListPage({
    super.key,
    required this.houseId,
    required this.roomId,
    required this.roomData,
  });

  @override
  State<TenantListPage> createState() => _TenantListPageState();
}

class _TenantListPageState extends State<TenantListPage> {
  List<Map<String, dynamic>> _tenants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTenants();
  }

  Future<void> _loadTenants() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch active contract for this room
      final contractSnap = await FirebaseFirestore.instance
          .collection('houses')
          .doc(widget.houseId)
          .collection('contracts')
          .where('roomId', isEqualTo: widget.roomId)
          .where('status', isEqualTo: 'Active')
          .get();

      List<Map<String, dynamic>> tenantList = [];

      if (contractSnap.docs.isNotEmpty) {
        final contractData = contractSnap.docs.first.data();
        final contractId = contractSnap.docs.first.id;

        // Primary tenant from the contract
        tenantList.add({
          'id': contractId,
          'name': contractData['tenantName'] ?? 'Chưa xác định',
          'phone': contractData['phoneNumber'] ?? '',
          'address': contractData['address'] ?? 'Chưa ghi nhận',
          'isRepresentative': true,
          'isContact': true,
          'avatarUrl': contractData['avatarUrl'],
        });

        // 2. Fetch additional tenants from sub-collection
        final tenantsSnap = await FirebaseFirestore.instance
            .collection('houses')
            .doc(widget.houseId)
            .collection('contracts')
            .doc(contractId)
            .collection('tenants')
            .get();

        for (var doc in tenantsSnap.docs) {
          final data = doc.data();
          tenantList.add({
            'id': doc.id,
            'name': data['name'] ?? 'Chưa xác định',
            'phone': data['phone'] ?? '',
            'address': data['address'] ?? 'Chưa ghi nhận',
            'isRepresentative': data['isRepresentative'] ?? false,
            'isContact': data['isContact'] ?? false,
            'avatarUrl': data['avatarUrl'],
          });
        }
      }

      if (mounted) {
        setState(() {
          _tenants = tenantList;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Lỗi tải danh sách khách thuê: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showTenantActionModal(Map<String, dynamic> tenant) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4FAEE),
                  border: Border.all(color: const Color(0xFF81C784), width: 0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF689F38), size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tenant['name'] ?? 'Khách thuê',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.phone_outlined, color: Colors.black87),
                title: const Text('Gọi điện', style: TextStyle(fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.chevron_right, color: Colors.black38),
                onTap: () => Navigator.pop(context),
              ),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: Colors.black87),
                title: const Text('Chỉnh sửa thông tin', style: TextStyle(fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.chevron_right, color: Colors.black38),
                onTap: () => Navigator.pop(context),
              ),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Xóa khách thuê', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.red)),
                trailing: const Icon(Icons.chevron_right, color: Colors.red),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteTenant(tenant);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteTenant(Map<String, dynamic> tenant) async {
    if (tenant['isRepresentative'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể xóa người đại diện hợp đồng!')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa "${tenant['name']}" khỏi danh sách khách thuê?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Find the active contract
        final contractSnap = await FirebaseFirestore.instance
            .collection('houses')
            .doc(widget.houseId)
            .collection('contracts')
            .where('roomId', isEqualTo: widget.roomId)
            .where('status', isEqualTo: 'Active')
            .get();

        if (contractSnap.docs.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('houses')
              .doc(widget.houseId)
              .collection('contracts')
              .doc(contractSnap.docs.first.id)
              .collection('tenants')
              .doc(tenant['id'])
              .delete();

          _loadTenants();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã xóa khách thuê thành công!')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e')),
          );
        }
      }
    }
  }

  void _showAddTenantDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00A651).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_add, color: Color(0xFF00A651), size: 20),
              ),
              const SizedBox(width: 10),
              const Text('Thêm khách thuê', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogTextField(nameCtrl, 'Họ và tên', Icons.person_outline),
                const SizedBox(height: 12),
                _buildDialogTextField(phoneCtrl, 'Số điện thoại', Icons.phone_outlined, keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                _buildDialogTextField(addressCtrl, 'Địa chỉ', Icons.location_on_outlined),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập họ và tên')),
                  );
                  return;
                }

                try {
                  final contractSnap = await FirebaseFirestore.instance
                      .collection('houses')
                      .doc(widget.houseId)
                      .collection('contracts')
                      .where('roomId', isEqualTo: widget.roomId)
                      .where('status', isEqualTo: 'Active')
                      .get();

                  if (contractSnap.docs.isNotEmpty) {
                    await FirebaseFirestore.instance
                        .collection('houses')
                        .doc(widget.houseId)
                        .collection('contracts')
                        .doc(contractSnap.docs.first.id)
                        .collection('tenants')
                        .add({
                      'name': nameCtrl.text.trim(),
                      'phone': phoneCtrl.text.trim(),
                      'address': addressCtrl.text.trim().isNotEmpty ? addressCtrl.text.trim() : 'Chưa ghi nhận',
                      'isRepresentative': false,
                      'isContact': false,
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    // Update totalMembers in room
                    final currentMembers = (widget.roomData['totalMembers'] as int?) ?? 1;
                    await FirebaseFirestore.instance
                        .collection('houses')
                        .doc(widget.houseId)
                        .collection('rooms')
                        .doc(widget.roomId)
                        .update({'totalMembers': currentMembers + 1});
                  }

                  if (mounted) {
                    Navigator.pop(context);
                    _loadTenants();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Thêm khách thuê thành công!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A651),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Thêm'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogTextField(TextEditingController ctrl, String label, IconData icon, {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 14, color: Colors.black54),
        prefixIcon: Icon(icon, size: 20, color: Colors.black54),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF00A651)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roomName = widget.roomData['roomName'] ?? 'Phòng';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Danh sách khách thuê',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A651)))
          : _tenants.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có khách thuê nào',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hãy thêm khách thuê cho $roomName',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _tenants.length,
                  itemBuilder: (context, index) {
                    return _buildTenantCard(_tenants[index]);
                  },
                ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Đóng',
                    style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showAddTenantDialog,
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text(
                    'Thêm khách thuê',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A651),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTenantCard(Map<String, dynamic> tenant) {
    final name = tenant['name'] ?? 'Chưa xác định';
    final phone = tenant['phone'] ?? '';
    final address = tenant['address'] ?? 'Chưa ghi nhận';
    final bool isRepresentative = tenant['isRepresentative'] == true;
    final bool isContact = tenant['isContact'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top section: Avatar, Name, Address, Menu
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade200,
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: ClipOval(
                    child: tenant['avatarUrl'] != null && tenant['avatarUrl'].toString().isNotEmpty
                        ? Image.network(
                            tenant['avatarUrl'],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildDefaultAvatar(name),
                          )
                        : _buildDefaultAvatar(name),
                  ),
                ),
                const SizedBox(width: 12),
                // Name and address
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Địa chỉ: $address',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                // Three-dot menu
                InkWell(
                  onTap: () => _showTenantActionModal(tenant),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    child: Icon(Icons.more_vert, color: Colors.grey.shade600, size: 22),
                  ),
                ),
              ],
            ),
          ),

          // Middle section: Tags
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (isContact) ...[
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.blue.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'Người liên hệ',
                        style: TextStyle(fontSize: 13, color: Colors.blue.shade600, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                ],
                if (isRepresentative) ...[
                  Row(
                    children: [
                      const Icon(Icons.check_box, size: 16, color: Color(0xFF00A651)),
                      const SizedBox(width: 4),
                      const Text(
                        'Đại diện hợp đồng',
                        style: TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Bottom section: Phone number bar
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                phone.isNotEmpty ? '#SĐT: $phone' : '#SĐT: Chưa cập nhật',
                style: const TextStyle(
                  color: Color(0xFF00A651),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(String name) {
    final initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
    return Container(
      color: const Color(0xFFE8F5E9),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF00A651)),
      ),
    );
  }
}
