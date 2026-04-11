import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tenant_detail_page.dart';
import 'add_tenant_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'tenant_list_page.dart';

class AllTenantsPage extends StatefulWidget {
  final String houseId;
  final Map<String, dynamic> houseData;

  const AllTenantsPage({
    super.key,
    required this.houseId,
    required this.houseData,
  });

  @override
  State<AllTenantsPage> createState() => _AllTenantsPageState();
}

class _AllTenantsPageState extends State<AllTenantsPage> {
  bool _isLoading = true;

  // All rooms list for filter
  List<Map<String, dynamic>> _allRooms = [];
  // All tenants grouped by room
  List<_RoomTenantGroup> _allGroups = [];
  // Filtered groups after applying filter/search
  List<_RoomTenantGroup> _filteredGroups = [];

  // Filter state
  String? _selectedRoomId; // null = all rooms
  String? _selectedFloor; // null = all floors
  String _searchQuery = '';

  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAllTenants();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAllTenants() async {
    setState(() => _isLoading = true);
    try {
      // 1. Load all rooms
      final roomsSnap = await FirebaseFirestore.instance
          .collection('houses')
          .doc(widget.houseId)
          .collection('rooms')
          .orderBy('createdAt', descending: false)
          .get();

      List<Map<String, dynamic>> rooms = [];
      for (var doc in roomsSnap.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        rooms.add(data);
      }

      // 2. Load all active contracts
      final contractsSnap = await FirebaseFirestore.instance
          .collection('houses')
          .doc(widget.houseId)
          .collection('contracts')
          .where('status', isEqualTo: 'Active')
          .get();

      // Map: roomId -> contract data
      Map<String, Map<String, dynamic>> contractByRoom = {};
      Map<String, String> contractIdByRoom = {};
      for (var doc in contractsSnap.docs) {
        final data = doc.data();
        final roomId = data['roomId'] as String?;
        if (roomId != null) {
          contractByRoom[roomId] = data;
          contractIdByRoom[roomId] = doc.id;
        }
      }

      // 3. Build groups
      List<_RoomTenantGroup> groups = [];
      for (var room in rooms) {
        final roomId = room['id'] as String;
        final contract = contractByRoom[roomId];
        final contractId = contractIdByRoom[roomId];

        if (contract == null) continue; // Skip rooms without contract

        List<_TenantInfo> tenants = [];

        // Primary tenant from contract
        tenants.add(_TenantInfo(
          name: contract['tenantName'] ?? 'Chưa xác định',
          phone: contract['phoneNumber'] ?? '',
          useApp: contract['useApp'] ?? false,
          isRepresentative: true,
          hasRegisteredResidence: false,
          hasCompleteDocs: false,
          avatarUrl: contract['avatarUrl'],
          contractId: contractId ?? '',
          tenantSubId: null,
        ));

        // Load additional tenants from sub-collection
        if (contractId != null) {
          final tenantsSnap = await FirebaseFirestore.instance
              .collection('houses')
              .doc(widget.houseId)
              .collection('contracts')
              .doc(contractId)
              .collection('tenants')
              .get();

          for (var tDoc in tenantsSnap.docs) {
            final tData = tDoc.data();
            tenants.add(_TenantInfo(
              name: tData['name'] ?? 'Chưa xác định',
              phone: tData['phone'] ?? '',
              useApp: tData['useApp'] ?? false,
              isRepresentative: tData['isRepresentative'] ?? false,
              hasRegisteredResidence: tData['hasRegisteredResidence'] ?? false,
              hasCompleteDocs: tData['hasCompleteDocs'] ?? false,
              avatarUrl: tData['avatarUrl'],
              contractId: contractId,
              tenantSubId: tDoc.id,
            ));
          }
          
          // Load additional tenants from the new 'tenant' array
          final tenantArray = contract['tenant'] as List<dynamic>? ?? [];
          for (var t in tenantArray) {
            final tData = t as Map<String, dynamic>;
            tenants.add(_TenantInfo(
              name: tData['name'] ?? 'Chưa xác định',
              phone: tData['phone'] ?? '',
              useApp: tData['useApp'] ?? false,
              isRepresentative: tData['isRepresentative'] ?? false,
              hasRegisteredResidence: tData['hasRegisteredResidence'] ?? false,
              hasCompleteDocs: tData['hasCompleteDocs'] ?? false,
              avatarUrl: tData['avatarUrl'],
              contractId: contractId,
              tenantSubId: tData['id'],
            ));
          }
        }

        groups.add(_RoomTenantGroup(
          roomId: roomId,
          roomName: room['roomName'] ?? 'Phòng',
          floor: room['floor']?.toString() ?? 'Tầng trệt',
          tenants: tenants,
          roomData: room,
          contractId: contractId ?? '',
        ));
      }

      if (mounted) {
        setState(() {
          _allRooms = rooms;
          _allGroups = groups;
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      debugPrint("Lỗi tải danh sách khách thuê: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilters() {
    List<_RoomTenantGroup> filtered = List.from(_allGroups);

    // Filter by room
    if (_selectedRoomId != null) {
      filtered = filtered.where((g) => g.roomId == _selectedRoomId).toList();
    }

    // Filter by floor
    if (_selectedFloor != null) {
      filtered = filtered.where((g) => g.floor == _selectedFloor).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((g) {
        return g.tenants.any((t) =>
            t.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            t.phone.contains(_searchQuery));
      }).toList();
    }

    setState(() {
      _filteredGroups = filtered;
    });
  }

  int get _totalTenants {
    int count = 0;
    for (var g in _filteredGroups) {
      count += g.tenants.length;
    }
    return count;
  }

  // Get unique floors from rooms
  List<String> get _uniqueFloors {
    final floors = _allRooms
        .map((r) => r['floor']?.toString() ?? 'Tầng trệt')
        .toSet()
        .toList();
    floors.sort();
    return floors;
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Bộ lọc',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              _selectedRoomId = null;
                              _selectedFloor = null;
                            });
                          },
                          child: const Text(
                            'Đặt lại',
                            style: TextStyle(color: Color(0xFF00A651)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Room filter
                    const Text(
                      'Chọn phòng',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: _selectedRoomId,
                          isExpanded: true,
                          hint: const Text('Tất cả phòng'),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Tất cả phòng'),
                            ),
                            ..._allRooms.map((room) {
                              return DropdownMenuItem<String?>(
                                value: room['id'] as String,
                                child: Text(room['roomName'] ?? 'Phòng'),
                              );
                            }),
                          ],
                          onChanged: (v) {
                            setModalState(() => _selectedRoomId = v);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Floor filter
                    const Text(
                      'Chọn tầng',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: _selectedFloor,
                          isExpanded: true,
                          hint: const Text('Tất cả tầng'),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Tất cả tầng'),
                            ),
                            ..._uniqueFloors.map((floor) {
                              return DropdownMenuItem<String?>(
                                value: floor,
                                child: Text(floor),
                              );
                            }),
                          ],
                          onChanged: (v) {
                            setModalState(() => _selectedFloor = v);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Apply button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _applyFilters();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A651),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Áp dụng',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _callPhone(String phone) async {
    if (phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showTenantOptions(_TenantInfo tenant, _RoomTenantGroup group) {
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tenant.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            group.roomName,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.phone_outlined, color: Colors.black87),
                title: const Text('Gọi điện', style: TextStyle(fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.chevron_right, color: Colors.black38),
                onTap: () {
                  Navigator.pop(context);
                  _callPhone(tenant.phone);
                },
              ),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              ListTile(
                leading: const Icon(Icons.chat_outlined, color: Colors.black87),
                title: const Text('Nhắn tin', style: TextStyle(fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.chevron_right, color: Colors.black38),
                onTap: () => Navigator.pop(context),
              ),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              ListTile(
                leading: const Icon(Icons.people_outline, color: Colors.black87),
                title: const Text('Xem danh sách phòng', style: TextStyle(fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.chevron_right, color: Colors.black38),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TenantListPage(
                        houseId: widget.houseId,
                        roomId: group.roomId,
                        roomData: group.roomData,
                      ),
                    ),
                  );
                },
              ),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: Colors.black87),
                title: const Text('Chỉnh sửa thông tin', style: TextStyle(fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.chevron_right, color: Colors.black38),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00A651)),
            )
          : Column(
              children: [
                // Filter & Search bar
                _buildFilterBar(),

                // Total count
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: Colors.white,
                  child: Text(
                    'Tổng Có ($_totalTenants) khách',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // Tenant list grouped by room
                Expanded(
                  child: _filteredGroups.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          color: const Color(0xFF00A651),
                          onRefresh: _loadAllTenants,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            itemCount: _filteredGroups.length,
                            itemBuilder: (context, index) {
                              return _buildRoomGroup(_filteredGroups[index]);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          // Filter button
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: _showFilterBottomSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedRoomId != null
                                ? (_allRooms.firstWhere(
                                    (r) => r['id'] == _selectedRoomId,
                                    orElse: () => {'roomName': 'Phòng'},
                                  )['roomName'] ?? 'Phòng')
                                : 'Chọn phòng',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _selectedFloor ?? 'Chọn giá trị',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600, size: 20),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Search field
          Expanded(
            flex: 3,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade50,
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (val) {
                  _searchQuery = val;
                  _applyFilters();
                },
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Nhập SĐT/tên tìm kiếm...',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  suffixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                  isDense: true,
                ),
              ),
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
          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Chưa có khách thuê nào',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy lập hợp đồng để thêm khách thuê',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomGroup(_RoomTenantGroup group) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          // Room header
          _buildRoomHeader(group),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          // Tenant cards
          ...group.tenants.map((tenant) => _buildTenantCard(tenant, group)),
        ],
      ),
    );
  }

  Widget _buildRoomHeader(_RoomTenantGroup group) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // Room icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.door_front_door_outlined, color: Color(0xFF00A651), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              group.roomName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
          ),
          // Chat button
          _buildHeaderAction(Icons.chat_bubble_outline, 'Chat', () {}),
          const SizedBox(width: 8),
          // Add tenant button
          _buildHeaderAction(Icons.add, 'Thêm', () {
            if (group.contractId.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddTenantPage(
                    houseId: widget.houseId,
                    contractId: group.contractId,
                    roomName: group.roomName,
                  ),
                ),
              ).then((_) => _loadAllTenants());
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Phòng chưa có hợp đồng')),
              );
            }
          }),
        ],
      ),
    );
  }

  Widget _buildHeaderAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.black54),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTenantCard(_TenantInfo tenant, _RoomTenantGroup group) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TenantDetailPage(
              houseId: widget.houseId,
              contractId: tenant.contractId,
              tenantSubId: tenant.tenantSubId,
              roomName: group.roomName,
            ),
          ),
        ).then((_) => _loadAllTenants());
      },
      child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade200,
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: ClipOval(
              child: tenant.avatarUrl != null && tenant.avatarUrl!.isNotEmpty
                  ? Image.network(
                      tenant.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => _buildDefaultAvatar(tenant.name),
                    )
                  : _buildDefaultAvatar(tenant.name),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  tenant.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                // Phone
                Text(
                  'SĐT: ${tenant.phone.isNotEmpty ? tenant.phone : "Chưa cập nhật"}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 6),
                // App usage status
                Row(
                  children: [
                    if (tenant.useApp) ...[
                      const Icon(Icons.check_circle, size: 14, color: Color(0xFF00A651)),
                      const SizedBox(width: 4),
                      const Text(
                        'Khách sử dụng APP',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF00A651),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ] else ...[
                      Icon(Icons.info_outline, size: 14, color: Colors.orange.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Chưa sử dụng APP',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                // Status tags
                Row(
                  children: [
                    _buildStatusTag(
                      tenant.hasRegisteredResidence
                          ? 'Đã đăng ký tạm trú'
                          : 'Chưa đăng ký tạm trú',
                      tenant.hasRegisteredResidence
                          ? const Color(0xFF00A651)
                          : Colors.red,
                    ),
                    const SizedBox(width: 12),
                    _buildStatusTag(
                      tenant.hasCompleteDocs
                          ? 'Đã đầy đủ giấy tờ'
                          : 'Chưa đầy đủ giấy tờ',
                      tenant.hasCompleteDocs
                          ? const Color(0xFF00A651)
                          : Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action buttons
          Column(
            children: [
              // Call button
              GestureDetector(
                onTap: () => _callPhone(tenant.phone),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00A651),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.phone, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(height: 8),
              // More options
              GestureDetector(
                onTap: () => _showTenantOptions(tenant, group),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.more_vert, color: Colors.grey.shade600, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildStatusTag(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar(String name) {
    final initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
    return Container(
      color: const Color(0xFFE8F5E9),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF00A651),
        ),
      ),
    );
  }
}

// Data models
class _RoomTenantGroup {
  final String roomId;
  final String roomName;
  final String floor;
  final List<_TenantInfo> tenants;
  final Map<String, dynamic> roomData;
  final String contractId;

  _RoomTenantGroup({
    required this.roomId,
    required this.roomName,
    required this.floor,
    required this.tenants,
    required this.roomData,
    required this.contractId,
  });
}

class _TenantInfo {
  final String name;
  final String phone;
  final bool useApp;
  final bool isRepresentative;
  final bool hasRegisteredResidence;
  final bool hasCompleteDocs;
  final String? avatarUrl;
  final String contractId;
  final String? tenantSubId;

  _TenantInfo({
    required this.name,
    required this.phone,
    required this.useApp,
    required this.isRepresentative,
    required this.hasRegisteredResidence,
    required this.hasCompleteDocs,
    this.avatarUrl,
    required this.contractId,
    this.tenantSubId,
  });
}
