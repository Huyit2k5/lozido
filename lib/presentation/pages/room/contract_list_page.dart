import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ContractListPage extends StatefulWidget {
  final String houseId;
  final Map<String, dynamic> houseData;

  const ContractListPage({
    super.key,
    required this.houseId,
    required this.houseData,
  });

  @override
  State<ContractListPage> createState() => _ContractListPageState();
}

class _ContractListPageState extends State<ContractListPage> {
  // Filters
  dynamic _selectedFloor = 'Tất cả'; // 'Tất cả', 0 (Trệt), 1, 2...
  String? _selectedRoomId;
  String? _selectedStatus;

  final List<String> _statusOptions = [
    'Tất cả',
    'Còn hạn',
    'Đã thanh toán',
    'Chưa ký',
    'Sắp hết hạn',
    'Đã kết thúc',
  ];

  List<Map<String, dynamic>> _rooms = [];

  @override
  void initState() {
    super.initState();
    _fetchRooms();
  }

  Future<void> _fetchRooms() async {
    try {
      final qs = await FirebaseFirestore.instance
          .collection('houses')
          .doc(widget.houseId)
          .collection('rooms')
          .get();
      if (mounted) {
        setState(() {
          _rooms = qs.docs.map((d) {
            final data = d.data();
            data['id'] = d.id;
            return data;
          }).toList();
        });
      }
    } catch (e) {
      debugPrint("Error fetching rooms: $e");
    }
  }

  int get _floorCount {
    return int.tryParse(widget.houseData['floorCount']?.toString() ?? '1') ?? 1;
  }

  String _formatCurrency(double amount) {
    if (amount == 0) return '0 đ';
    return '${NumberFormat.decimalPattern('vi_VN').format(amount)}đ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('Danh sách hợp đồng', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: _buildContractList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Row 1: Floor chips
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Icon(Icons.settings, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFloorChip('Tất cả'),
                      _buildFloorChip(0), // Assumed 0 is Tầng trệt
                      for (int i = 1; i <= _floorCount; i++) _buildFloorChip(i),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 2: Room & Status dropdowns
          Row(
            children: [
              Expanded(child: _buildRoomDropdown()),
              const SizedBox(width: 12),
              Expanded(child: _buildStatusDropdown()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloorChip(dynamic floorValue) {
    final isSelected = _selectedFloor == floorValue;
    String label = floorValue == 'Tất cả'
        ? 'Tất cả'
        : floorValue == 0
            ? 'Tầng trệt'
            : 'Tầng $floorValue';

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFloor = floorValue;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00A651) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF00A651) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildRoomDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Chọn phòng', style: TextStyle(fontSize: 11, color: Colors.black54)),
          DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              isExpanded: true,
              isDense: true,
              value: _selectedRoomId,
              hint: const Text('Chọn giá trị', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black)),
              icon: const Icon(Icons.keyboard_arrow_down, size: 20),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Tất cả phòng', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ),
                ..._rooms.map((room) {
                  return DropdownMenuItem<String?>(
                    value: room['id'],
                    child: Text(room['roomName'] ?? 'Phòng (không tên)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  );
                }).toList(),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedRoomId = val;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Trạng thái hợp đồng', style: TextStyle(fontSize: 11, color: Colors.black54)),
          DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              isExpanded: true,
              isDense: true,
              value: _selectedStatus,
              hint: const Text('Chọn giá trị', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black)),
              icon: const Icon(Icons.keyboard_arrow_down, size: 20),
              items: _statusOptions.map((status) {
                return DropdownMenuItem<String?>(
                  value: status == 'Tất cả' ? null : status,
                  child: Text(status, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedStatus = val;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractList() {
    Query query = FirebaseFirestore.instance
        .collection('houses')
        .doc(widget.houseId)
        .collection('contracts');

    // 1. Logic Filter: Floor
    if (_selectedFloor != 'Tất cả' && _selectedFloor != null) {
      query = query.where('floor', isEqualTo: _selectedFloor);
    }

    // 1. Logic Filter: Room
    if (_selectedRoomId != null) {
      query = query.where('roomId', isEqualTo: _selectedRoomId);
    }

    // 1. Logic Filter: Status
    if (_selectedStatus != null && _selectedStatus != 'Tất cả') {
      String dbStatus = _selectedStatus == 'Còn hạn' ? 'Active' : _selectedStatus!;
      query = query.where('status', isEqualTo: dbStatus);
    } else {
      query = query.where('status', whereIn: ['Còn hạn', 'Đang hiệu lực', 'Active']);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF00A651)));
        }

        if (snapshot.hasError) {
          return const Center(child: Text("Đã xảy ra lỗi khi tải dữ liệu."));
        }

        final docs = snapshot.data?.docs ?? [];

        // Trường hợp 2: Không có dữ liệu
        if (docs.isEmpty) {
          return _buildEmptyState();
        }

        // Trường hợp 1: Có dữ liệu
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildContractCard(data);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Thùng giấy trống và ruồi
          Image.asset(
             'assets/images/empty_box.png', 
             width: 150, 
             height: 150,
             errorBuilder: (context, error, stackTrace) => const Icon(Icons.inventory_2_outlined, size: 80, color: Colors.black26),
          ),
          const SizedBox(height: 20),
          const Text(
            "Không có dữ liệu!",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          const Text(
            "Không có hợp đồng nào",
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildContractCard(Map<String, dynamic> data) {
    String roomName = data['roomName'] ?? '';
    if (roomName.isEmpty) {
      final roomId = data['roomId'];
      if (roomId != null && _rooms.isNotEmpty) {
        try {
          final room = _rooms.firstWhere((r) => r['id'] == roomId);
          roomName = room['roomName'] ?? 'Phòng chưa đặt tên';
        } catch (_) {
          roomName = 'Phòng chưa đặt tên';
        }
      } else {
        roomName = 'Phòng chưa đặt tên';
      }
    }
    final status = data['status'] ?? 'Không xác định';
    final rentPrice = (data['rentPrice'] ?? 0).toDouble();
    final deposit = (data['depositAmount'] ?? 0).toDouble();
    final collectedDeposit = (data['collectedDeposit'] ?? 0).toDouble();
    
    final startDate = data['startDate'] ?? '';
    final endDate = data['endDate'] ?? '';
    final createdAtMs = (data['createdAt'] as Timestamp?)?.toDate();
    final createdAtStr = createdAtMs != null ? DateFormat('dd/MM/yyyy').format(createdAtMs) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Room Info & Status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFF00A651),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.assignment_turned_in, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(roomName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, decoration: TextDecoration.underline)),
                          const Text('#54810', style: TextStyle(color: Colors.black54, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: Color(0xFF00A651), shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(status == 'Active' ? 'Trong thời hạn hợp đồng' : status, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                        ],
                      )
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.more_vert, size: 20),
                )
              ],
            ),
            const SizedBox(height: 12),
            
            // Warnings
            Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: Colors.deepOrange),
                const SizedBox(width: 4),
                const Text('Chưa sử dụng app', style: TextStyle(color: Colors.deepOrange, fontSize: 12)),
                const SizedBox(width: 16),
                const Icon(Icons.close, size: 14, color: Colors.deepOrange),
                const SizedBox(width: 4),
                const Text('Chưa ký hợp đồng', style: TextStyle(color: Colors.deepOrange, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 16),

            // Prices
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.request_quote, size: 14, color: Color(0xFF00A651)),
                            SizedBox(width: 4),
                            Text('Giá thuê', style: TextStyle(fontSize: 12, color: Colors.black87)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(_formatCurrency(rentPrice), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.request_quote, size: 14, color: Colors.blue),
                            SizedBox(width: 4),
                            Text('Mức cọc', style: TextStyle(fontSize: 12, color: Colors.black87)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(_formatCurrency(deposit), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.request_quote, size: 14, color: Colors.orange),
                            SizedBox(width: 4),
                            Text('Đã thu cọc', style: TextStyle(fontSize: 12, color: Colors.black87)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(collectedDeposit > 0 ? _formatCurrency(collectedDeposit) : 'Chưa thu', style: TextStyle(fontWeight: collectedDeposit > 0 ? FontWeight.bold : FontWeight.normal, fontSize: 13, color: collectedDeposit > 0 ? Colors.black87 : Colors.orange)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Dates
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Ngày lập', style: TextStyle(fontSize: 12, color: Colors.black54)),
                        const SizedBox(height: 4),
                        Text(createdAtStr.isEmpty ? '--' : createdAtStr, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 30, color: Colors.grey.shade200),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Ngày vào ở', style: TextStyle(fontSize: 12, color: Colors.black54)),
                        const SizedBox(height: 4),
                        Text(startDate.isEmpty ? '--' : startDate, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 30, color: Colors.grey.shade200),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Hạn kết thúc', style: TextStyle(fontSize: 12, color: Colors.black54)),
                        const SizedBox(height: 4),
                        Text(endDate.isEmpty ? '--' : endDate, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                      ],
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
