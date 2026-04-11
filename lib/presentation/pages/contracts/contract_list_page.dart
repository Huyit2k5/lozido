import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lozido_app/presentation/widgets/app_dialog.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'contract_detail_page.dart';
import 'contract_pdf_preview_page.dart';
import 'create_contract_page.dart';
import 'contract_provider.dart';

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
  Set<String> _roomsWithContracts = {};

  @override
  void initState() {
    super.initState();
    _fetchRooms();
  }

  Future<void> _endContract(String contractId, String roomId) async {
    final act = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận kết thúc'),
        content: const Text('Bạn có chắc chắn muốn kết thúc hợp đồng cho phòng này không? Hợp đồng sẽ được lưu lại hệ thống với trạng thái đã kết thúc.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Đồng ý', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (act == true) {
      try {
        // 1. Update contract status
        await FirebaseFirestore.instance
            .collection('houses')
            .doc(widget.houseId)
            .collection('contracts')
            .doc(contractId)
            .update({
          'status': 'Đã kết thúc',
          'endedAt': FieldValue.serverTimestamp(),
        });

        // 2. Update room status to "Đang trống"
        await FirebaseFirestore.instance
            .collection('houses')
            .doc(widget.houseId)
            .collection('rooms')
            .doc(roomId)
            .update({'status': 'Đang trống'});

        if (mounted) {
          AppDialog.show(context, title: "Thành công", message: "Đã kết thúc hợp đồng thành công!", type: AppDialogType.success);
        }
      } catch (e) {
        if (mounted) {
          AppDialog.show(context, title: "Lỗi", message: "Lỗi khi kết thúc hợp đồng: $e", type: AppDialogType.error);
        }
      }
    }
  }

  Future<void> _fetchRooms() async {
    try {
      final qs = await FirebaseFirestore.instance
          .collection('houses')
          .doc(widget.houseId)
          .collection('rooms')
          .get();
          
      final Set<String> usedRoomIds = {};
      try {
        final contractsQs = await FirebaseFirestore.instance
            .collection('houses')
            .doc(widget.houseId)
            .collection('contracts')
            .get();

        for (var doc in contractsQs.docs) {
          try {
            final data = doc.data();
            if (data is Map) {
              final rId = data['roomId']?.toString();
              if (rId != null && rId.isNotEmpty) {
                usedRoomIds.add(rId.trim());
              }
            }
          } catch (_) {}
        }
      } catch (e) {
        debugPrint("Lỗi tải contracts để lọc dropdown: $e");
      }

      if (mounted) {
        setState(() {
          _roomsWithContracts = usedRoomIds;
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

  List<dynamic> get _availableFloors {
    final floors = _rooms.map((r) => r['floor']).where((f) => f != null && f.toString().isNotEmpty).toSet().toList();
    floors.sort((a, b) {
      if (a is num && b is num) return a.compareTo(b);
      return a.toString().compareTo(b.toString());
    });
    return floors;
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
                      ..._availableFloors.map((f) => _buildFloorChip(f)),
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
        : (floorValue == 0 || floorValue.toString().toLowerCase() == 'trệt')
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
                ..._rooms.where((room) {
                  final rId = room['id']?.toString().trim();
                  if (rId == null || !_roomsWithContracts.contains(rId)) {
                    return false;
                  }

                  if (_selectedFloor != 'Tất cả' && _selectedFloor != null) {
                    return room['floor']?.toString() == _selectedFloor.toString();
                  }
                  return true;
                }).map((room) {
                  return DropdownMenuItem<String?>(
                    value: room['id'],
                    child: Text(room['roomName'] ?? 'Phòng (không tên)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  );
                }),
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
    // NOTE: Old contracts might not have 'floor' saved in their Firestore document.
    // If a floor is selected, we filter by it. Since we select the room via dropdown, 
    // omitting the floor filter if a precise room is already selected makes it perfectly safe for old contracts!
    if (_selectedFloor != 'Tất cả' && _selectedFloor != null && _selectedRoomId == null) {
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
      if (_selectedRoomId != null) {
        // Lấy tất cả các hợp đồng (cả cũ và mới) nếu đã chọn đích danh một phòng
      } else {
        // Mặc định chỉ lấy các hợp đồng đang hoạt động
        query = query.where('status', whereIn: ['Còn hạn', 'Đang hiệu lực', 'Active']);
      }
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
            data['id'] = docs[index].id;
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

  void _showContractActionModal(Map<String, dynamic> data, String roomName) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final status = data['status'] == 'Active' ? 'Trong thời hạn hợp đồng' : (data['status'] ?? 'Không xác định');
        
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Trạng thái "$status"', style: const TextStyle(color: Colors.black87, fontSize: 14)),
                    ),
                  ],
                ),
              ),

              ListTile(
                leading: const Icon(Icons.visibility_outlined, color: Colors.black87),
                title: const Text('Xem thông tin hợp đồng', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ContractDetailPage(contractData: data, roomName: roomName),
                    ),
                  );
                },
              ),
              const Divider(height: 1),

              if (data['status'] != 'Đã kết thúc') ...[
                ListTile(
                  leading: const Icon(Icons.edit_outlined, color: Colors.black87),
                  title: const Text('Chỉnh sửa hợp đồng', style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(ctx);
                    final roomId = data['roomId'];
                    final room = roomId != null ? _rooms.firstWhere((r) => r['id'] == roomId, orElse: () => <String, dynamic>{}) : <String, dynamic>{};
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider(
                          create: (_) => ContractProvider(),
                          child: CreateContractPage(
                            houseId: widget.houseId,
                            roomId: roomId ?? '',
                            houseData: widget.houseData,
                            roomData: room,
                            contractId: data['id'],
                            initialContractData: data,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
              ],

              ListTile(
                leading: const Icon(Icons.description_outlined, color: Colors.black87),
                title: const Text('Xem văn bản hợp đồng', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Xem mẫu thông tin chi tiết hợp đồng, lưu & in file PDF', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ContractPdfPreviewPage(contractData: data, roomName: roomName),
                    ),
                  );
                },
              ),
              const Divider(height: 1),

              if (data['status'] == 'Active' || data['status'] == 'Còn hạn') ...[
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.red),
                  title: const Text('Kết thúc hợp đồng', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _endContract(data['id'], data['roomId'] ?? '');
                  },
                ),
                const Divider(height: 1),
              ],
              
              const SizedBox(height: 16),
            ],
          ),
        );
      },
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

    final isEnded = status == 'Đã kết thúc';
    final statusColor = isEnded ? Colors.red : const Color(0xFF00A651);

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
                  decoration: BoxDecoration(
                    color: statusColor,
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
                            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(status == 'Active' ? 'Trong thời hạn hợp đồng' : status, style: TextStyle(color: isEnded ? Colors.red : Colors.black54, fontSize: 13, fontWeight: isEnded ? FontWeight.bold : FontWeight.normal)),
                        ],
                      )
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => _showContractActionModal(data, roomName),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.more_vert, size: 20),
                  ),
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
