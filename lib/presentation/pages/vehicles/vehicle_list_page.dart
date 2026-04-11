import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'add_vehicle_page.dart';
import 'edit_vehicle_page.dart';

class VehicleListPage extends StatefulWidget {
  final String houseId;
  final Map<String, dynamic> houseData;

  const VehicleListPage({
    super.key,
    required this.houseId,
    required this.houseData,
  });

  @override
  State<VehicleListPage> createState() => _VehicleListPageState();
}

class _VehicleListPageState extends State<VehicleListPage> {
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _deleteVehicle(String vehicleId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa phương tiện này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('houses')
            .doc(widget.houseId)
            .collection('vehicles')
            .doc(vehicleId)
            .delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa phương tiện')),
          );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SafeArea(
        child: Column(
          children: [
            // AppBar custom
            _buildAppBar(),
            // Content
            Expanded(
              child: _buildVehicleStream(),
            ),
            // Search bar at bottom
            _buildSearchBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Icon(Icons.arrow_back, size: 20, color: Colors.black87),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Danh sách phương tiện',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Quản lý phương tiện',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddVehiclePage(
                    houseId: widget.houseId,
                    houseData: widget.houseData,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add, size: 18, color: Color(0xFF00A651)),
            label: const Text(
              'Thêm',
              style: TextStyle(
                color: Color(0xFF00A651),
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF00A651)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('houses')
          .doc(widget.houseId)
          .collection('vehicles')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF00A651)),
          );
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text('Đã xảy ra lỗi khi tải dữ liệu.'),
          );
        }

        final allDocs = snapshot.data?.docs ?? [];

        // Apply search filter
        final docs = allDocs.where((doc) {
          if (_searchQuery.isEmpty) return true;
          final data = doc.data() as Map<String, dynamic>;
          final query = _searchQuery.toLowerCase();
          final vehicleName = (data['vehicleName'] ?? '').toString().toLowerCase();
          final licensePlate = (data['licensePlate'] ?? '').toString().toLowerCase();
          final roomName = (data['roomName'] ?? '').toString().toLowerCase();
          final tenantName = (data['tenantName'] ?? '').toString().toLowerCase();
          return vehicleName.contains(query) ||
              licensePlate.contains(query) ||
              roomName.contains(query) ||
              tenantName.contains(query);
        }).toList();

        if (docs.isEmpty) {
          return _buildEmptyState();
        }

        // Group by roomName
        final Map<String, List<QueryDocumentSnapshot>> grouped = {};
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final roomName = data['roomName'] ?? 'Chưa xác định';
          grouped.putIfAbsent(roomName, () => []);
          grouped[roomName]!.add(doc);
        }

        final totalVehicles = docs.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vehicle count
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                '$totalVehicles Phương tiện',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Grouped list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: grouped.entries.map((entry) {
                  return _buildRoomGroup(entry.key, entry.value);
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRoomGroup(String roomName, List<QueryDocumentSnapshot> vehicles) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Room header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  roomName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddVehiclePage(
                          houseId: widget.houseId,
                          houseData: widget.houseData,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 16, color: Colors.black87),
                  label: const Text(
                    'Thêm',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Vehicle items
          ...vehicles.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _buildVehicleItem(doc.id, data);
          }),
        ],
      ),
    );
  }

  Widget _buildVehicleItem(String vehicleId, Map<String, dynamic> data) {
    final tenantName = data['tenantName'] ?? 'Không rõ';
    final vehicleName = data['vehicleName'] ?? 'Xe';
    final licensePlate = data['licensePlate'] ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.black54, size: 24),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tenantName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  vehicleName,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
                Text(
                  licensePlate,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
          // Edit button
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditVehiclePage(
                    houseId: widget.houseId,
                    vehicleId: vehicleId,
                    vehicleData: data,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.edit_outlined, size: 14, color: Color(0xFF00A651)),
            label: const Text(
              'Sửa',
              style: TextStyle(color: Color(0xFF00A651), fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
            ),
          ),
          const SizedBox(width: 8),
          // Delete button
          OutlinedButton(
            onPressed: () => _deleteVehicle(vehicleId),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.red.shade200),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
            ),
            child: Text(
              'Xóa',
              style: TextStyle(color: Colors.red.shade400, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/empty_box.png',
            width: 150,
            height: 150,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Không có dữ liệu!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Chưa có phương tiện nào được đăng ký',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (val) {
            setState(() {
              _searchQuery = val;
            });
          },
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Nhập phòng/Tên khách/Biển số...',
            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            prefixIcon: null,
            suffixIcon: Icon(Icons.search, color: Colors.grey.shade600),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }
}
