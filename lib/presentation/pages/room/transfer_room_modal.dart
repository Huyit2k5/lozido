import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TransferRoomModal extends StatefulWidget {
  final String houseId;
  final String oldRoomId;
  final Map<String, dynamic> houseData;
  final Map<String, dynamic> oldRoomData;

  const TransferRoomModal({
    super.key,
    required this.houseId,
    required this.oldRoomId,
    required this.houseData,
    required this.oldRoomData,
  });

  @override
  State<TransferRoomModal> createState() => _TransferRoomModalState();
}

class _TransferRoomModalState extends State<TransferRoomModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedFloorIndex = 0;

  int get _totalFloors {
    final floorCountStr = widget.houseData['floorCount']?.toString() ?? "";
    final match = RegExp(r'\d+').firstMatch(floorCountStr);
    if (match != null) {
      return int.parse(match.group(0)!);
    }
    return 1;
  }

  List<String> get _floorNames {
    final count = _totalFloors;
    List<String> names = ["Tất cả"];
    names.add("Tầng trệt");
    if (count > 1) {
      for (int i = 1; i < count; i++) {
        names.add("Tầng $i");
      }
    }
    return names;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _floorNames.length, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedFloorIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    String str = amount.toStringAsFixed(0);
    String result = '';
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count == 3) {
        result = '.$result';
        count = 0;
      }
      result = str[i] + result;
      count++;
    }
    return result;
  }

  Future<void> _confirmTransfer(String newRoomId, Map<String, dynamic> newRoomData) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận', style: TextStyle(fontWeight: FontWeight.bold)),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.5),
            children: [
              const TextSpan(text: 'Bạn chắc chắn muốn di chuyển '),
              TextSpan(text: widget.oldRoomData['roomName'] ?? 'Phòng cũ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              const TextSpan(text: ' tới '),
              TextSpan(text: newRoomData['roomName'] ?? 'Phòng mới', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              const TextSpan(text: '.\n\nCác dữ liệu như hợp đồng, hóa đơn, dịch vụ sẽ được chuyển theo!'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('KHÔNG CHUYỂN', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A651),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('CHUYỂN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _executeTransfer(newRoomId, newRoomData);
    }
  }

  Future<void> _executeTransfer(String newRoomId, Map<String, dynamic> newRoomData) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF00A651))),
    );

    try {
      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      final houseRef = db.collection('houses').doc(widget.houseId);
      final oldRoomRef = houseRef.collection('rooms').doc(widget.oldRoomId);
      final newRoomRef = houseRef.collection('rooms').doc(newRoomId);

      // 1. Update Contracts
      final contracts = await houseRef
          .collection('contracts')
          .where('roomId', isEqualTo: widget.oldRoomId)
          .where('status', isEqualTo: 'Active')
          .get();
      for (var doc in contracts.docs) {
        batch.update(doc.reference, {'roomId': newRoomId, 'roomName': newRoomData['roomName']});
      }

      // 2. Update Invoices
      final invoices = await houseRef
          .collection('invoices')
          .where('roomId', isEqualTo: widget.oldRoomId)
          .get();
      for (var doc in invoices.docs) {
        batch.update(doc.reference, {'roomId': newRoomId, 'roomName': newRoomData['roomName']});
      }

      // 3. Update Tenants (Root collection)
      final tenants = await db
          .collection('tenants')
          .where('houseId', isEqualTo: widget.houseId)
          .where('roomId', isEqualTo: widget.oldRoomId)
          .get();
      for (var doc in tenants.docs) {
        batch.update(doc.reference, {'roomId': newRoomId});
      }

      // 4. Update Global Services appliedRooms
      final services = await houseRef
          .collection('services')
          .where('appliedRooms', arrayContains: widget.oldRoomId)
          .get();
      for (var doc in services.docs) {
        List<dynamic> appliedRooms = List.from(doc.data()['appliedRooms'] ?? []);
        appliedRooms.remove(widget.oldRoomId);
        if (!appliedRooms.contains(newRoomId)) {
          appliedRooms.add(newRoomId);
        }
        batch.update(doc.reference, {'appliedRooms': appliedRooms});
      }

      // 5. Swap Room Data
      // New room gets old room's tenant info and status
      batch.update(newRoomRef, {
        'status': widget.oldRoomData['status'] ?? 'Đã thuê',
        'tenantName': widget.oldRoomData['tenantName'],
        'tenantPhone': widget.oldRoomData['tenantPhone'],
        'contractStartDate': widget.oldRoomData['contractStartDate'],
        'contractEndDate': widget.oldRoomData['contractEndDate'],
        'rentPrice': widget.oldRoomData['rentPrice'],
        'depositAmount': widget.oldRoomData['depositAmount'],
        'totalMembers': widget.oldRoomData['totalMembers'],
        'useApp': widget.oldRoomData['useApp'],
        'contractSigned': widget.oldRoomData['contractSigned'],
        'services': widget.oldRoomData['services'],
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Old room becomes empty
      batch.update(oldRoomRef, {
        'status': 'Đang trống',
        'tenantName': FieldValue.delete(),
        'tenantPhone': FieldValue.delete(),
        'contractStartDate': FieldValue.delete(),
        'contractEndDate': FieldValue.delete(),
        'rentPrice': FieldValue.delete(),
        'depositAmount': FieldValue.delete(),
        'totalMembers': FieldValue.delete(),
        'useApp': FieldValue.delete(),
        'contractSigned': FieldValue.delete(),
        // Usually services stay with the room as defaults, but we might want to clear them or keep them.
        // The request says "clear các trường thông tin khách".
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (mounted) {
        Navigator.pop(context); // Close loading
        Navigator.pop(context); // Close modal
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chuyển phòng thành công!'), backgroundColor: Color(0xFF00A651)),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                  child: const Icon(Icons.list, color: Colors.black87, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text("Danh sách phòng", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text("Chọn phòng để chuyển tới", style: TextStyle(color: Colors.black54, fontSize: 13)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 20, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: const BoxDecoration(color: Color(0xFFF8F9FA)),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: Stack(
                    children: [
                      const Icon(Icons.settings, color: Colors.black87),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: Color(0xFF00A651), shape: BoxShape.circle),
                          child: const Text("3", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicator: BoxDecoration(
                      color: const Color(0xFF00A651).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    indicatorSize: TabBarIndicatorSize.label,
                    labelColor: const Color(0xFF00A651),
                    unselectedLabelColor: Colors.black54,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    tabs: _floorNames.map((name) => Tab(text: name)).toList(),
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('houses')
                  .doc(widget.houseId)
                  .collection('rooms')
                  .where('status', isEqualTo: 'Đang trống')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF00A651)));
                }

                final allDocs = snapshot.data?.docs ?? [];
                // Filter by floor
                List<QueryDocumentSnapshot> displayDocs = [];
                if (_selectedFloorIndex == 0) {
                  displayDocs = allDocs;
                } else {
                  final targetFloor = _selectedFloorIndex - 1;
                  displayDocs = allDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return (data['floor'] ?? 0) == targetFloor;
                  }).toList();
                }

                if (displayDocs.isEmpty) {
                  return const Center(child: Text("Không có phòng trống nào ở tầng này"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: displayDocs.length,
                  itemBuilder: (context, index) {
                    final doc = displayDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildRoomItem(doc.id, data);
                  },
                );
              },
            ),
          ),

          // Bottom Close Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
                label: const Text("Đóng thao tác", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF15A24),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomItem(String roomId, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 4, decoration: const BoxDecoration(color: Color(0xFFF15A24), borderRadius: BorderRadius.horizontal(left: Radius.circular(12)))),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.storefront, color: Colors.green, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(data['roomName'] ?? 'Phòng', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                    ElevatedButton(
                      onPressed: () => _confirmTransfer(roomId, data),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: Row(
                        children: const [
                          Text("Chuyển tới", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          SizedBox(width: 4),
                          Icon(Icons.chevron_right, size: 16, color: Colors.blue),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.sell_outlined, size: 14, color: Colors.black54),
                          SizedBox(width: 6),
                          Text("Trạng thái", style: TextStyle(color: Colors.black54, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStatusTag("Đang trống", Colors.deepOrange),
                          const SizedBox(width: 16),
                          _buildStatusTag("Chưa thể thu tiền", Colors.orange),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStat(Icons.attach_money, "Giá thuê", "${_formatCurrency((data['price'] as num?)?.toDouble() ?? 0)} đ"),
                    const SizedBox(width: 24),
                    _buildStat(Icons.attach_money, "Mức cọc", "${_formatCurrency((data['price'] as num?)?.toDouble() ?? 0)} đ"),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTag(String text, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildStat(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.green),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
