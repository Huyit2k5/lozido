import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_room_page.dart';
import 'room_detail_page.dart';
import 'package:provider/provider.dart';
import 'contract_provider.dart';
import 'create_contract_page.dart';
import 'service_selection_page.dart';
import '../deposit/deposit_page.dart';
class RoomListPage extends StatefulWidget {
  final String houseId;
  final Map<String, dynamic> houseData;

  const RoomListPage({super.key, required this.houseId, required this.houseData});

  @override
  State<RoomListPage> createState() => _RoomListPageState();
}

class _RoomListPageState extends State<RoomListPage> {
  Future<void> _addRoom() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddRoomPage(
          houseId: widget.houseId,
          houseData: widget.houseData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Danh sách phòng",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black87),
            onPressed: () {},
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFF), width: 1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.settings, size: 20, color: Colors.black87),
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF00A651),
                            shape: BoxShape.circle,
                          ),
                          child: const Text("0", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFF00A651), width: 3)),
                  ),
                  child: const Text(
                    "Tầng trệt",
                    style: TextStyle(color: Color(0xFF00A651), fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('houses').doc(widget.houseId).collection('rooms').orderBy('createdAt', descending: false).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00A651)));
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Không thể tải danh sách phòng"));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "Chưa có phòng nào.\nBấm '+' để thêm phòng",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              return _buildRoomCard(doc.id, doc.data() as Map<String, dynamic>);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00A651),
        onPressed: _addRoom,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Future<void> _endContract(String roomId) async {
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
        final activeContracts = await FirebaseFirestore.instance
            .collection('houses')
            .doc(widget.houseId)
            .collection('contracts')
            .where('roomId', isEqualTo: roomId)
            .where('status', isEqualTo: 'Active')
            .get();

        if (activeContracts.docs.isNotEmpty) {
          final docId = activeContracts.docs.first.id;
          await FirebaseFirestore.instance
              .collection('houses')
              .doc(widget.houseId)
              .collection('contracts')
              .doc(docId)
              .update({'status': 'Đã kết thúc', 'endedAt': FieldValue.serverTimestamp()});
        }

        await FirebaseFirestore.instance
            .collection('houses')
            .doc(widget.houseId)
            .collection('rooms')
            .doc(roomId)
            .update({'status': 'Đang trống'});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã kết thúc hợp đồng thành công!')));
        }
      } catch (e) {
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
         }
      }
    }
  }

  void _showRoomActionModal(String roomId, Map<String, dynamic> roomData) {
    bool isRented = roomData['status'] == 'Đã thuê';
    String displayStatus = isRented ? 'Đang ở' : (roomData['status'] ?? 'Đang trống');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isRented ? const Color(0xFFF4FAEE) : Colors.orange.shade50,
                    border: Border.all(color: isRented ? const Color(0xFF81C784) : Colors.orange.shade200, width: 0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(isRented ? Icons.info_outline : Icons.warning_amber_rounded, color: isRented ? const Color(0xFF689F38) : Colors.deepOrange, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(color: Colors.black87, fontSize: 13),
                            children: [
                              TextSpan(text: '${roomData['roomName']}: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(text: 'Trạng thái "$displayStatus"'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildModalListTile(
                  icon: Icons.remove_red_eye_outlined,
                  title: 'Xem chi tiết phòng',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => RoomDetailPage(houseId: widget.houseId, roomId: roomId, houseData: widget.houseData, initialRoomData: roomData)));
                  },
                ),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                _buildModalListTile(
                  icon: Icons.edit_outlined,
                  title: 'Chỉnh sửa thông tin cơ bản',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => AddRoomPage(houseId: widget.houseId, houseData: widget.houseData, roomId: roomId, initialRoomData: roomData)));
                  },
                ),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                if (isRented) ...[
                  _buildModalListTile(
                    icon: Icons.settings_outlined,
                    title: 'Thiết lập dịch vụ',
                    subtitle: 'Dịch vụ điện, nước... của phòng',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceSelectionPage(houseId: widget.houseId, roomId: roomId, initialSelectedServices: List<Map<String, dynamic>>.from(roomData['services'] ?? []))));
                    },
                  ),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  _buildModalListTile(
                    icon: Icons.attach_money,
                    title: 'Lập hóa đơn',
                    onTap: () { Navigator.pop(context); },
                  ),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  _buildModalListTile(
                    icon: Icons.people_outline,
                    title: 'Danh sách khách thuê',
                    onTap: () { Navigator.pop(context); },
                  ),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  _buildModalListTile(
                    icon: Icons.person_add_alt_1_outlined,
                    title: 'Thêm khách thuê (thành viên)',
                    onTap: () { Navigator.pop(context); },
                  ),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  _buildModalListTile(
                    icon: Icons.sync_alt,
                    title: 'Chuyển phòng',
                    onTap: () { Navigator.pop(context); },
                  ),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  _buildModalListTile(
                    icon: Icons.remove_red_eye_outlined,
                    title: 'Xem thông tin hợp đồng',
                    onTap: () { Navigator.pop(context); },
                  ),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  _buildModalListTile(
                    icon: Icons.edit_document,
                    title: 'Chỉnh sửa hợp đồng',
                    onTap: () { Navigator.pop(context); },
                  ),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  _buildModalListTile(
                    icon: Icons.exit_to_app,
                    title: 'Kết thúc hợp đồng',
                    isDestructive: true,
                    onTap: () {
                      Navigator.pop(context);
                      _endContract(roomId);
                    },
                  ),
                ] else ...[
                  _buildModalListTile(
                    icon: Icons.assignment_outlined,
                    title: 'Lập hợp đồng mới',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => ChangeNotifierProvider(
                            create: (_) => ContractProvider(),
                            child: CreateContractPage(houseId: widget.houseId, roomId: roomId, houseData: widget.houseData, roomData: roomData),
                          ),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            var tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero).chain(CurveTween(curve: Curves.easeInOut));
                            return SlideTransition(position: animation.drive(tween), child: child);
                          },
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  _buildModalListTile(
                    icon: Icons.anchor,
                    title: 'Cọc giữ chỗ',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => DepositPage(houseId: widget.houseId, roomId: roomId, roomData: roomData, isViewMode: roomData['status'] == 'Đang cọc giữ chỗ')));
                    },
                  ),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  _buildModalListTile(
                    icon: Icons.settings_outlined,
                    title: 'Thiết lập dịch vụ',
                    subtitle: 'Dịch vụ điện, nước... của phòng',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceSelectionPage(houseId: widget.houseId, roomId: roomId, initialSelectedServices: List<Map<String, dynamic>>.from(roomData['services'] ?? []))));
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalListTile({required IconData icon, required String title, String? subtitle, required VoidCallback onTap, bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : Colors.black87),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: isDestructive ? Colors.red : Colors.black87)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
      trailing: Icon(Icons.chevron_right, color: isDestructive ? Colors.red : Colors.black38),
      onTap: onTap,
    );
  }

  Widget _buildRoomCard(String roomId, Map<String, dynamic> roomData) {
    final status = roomData['status'] ?? 'Đang trống';
    if (status == 'Đã thuê') {
      return _buildRentedRoomCard(roomId, roomData);
    }
    
    final name = roomData['roomName'] ?? 'Phòng';
    final priceInfo = _formatCurrency((roomData['price'] as num?)?.toDouble() ?? 0);
    final bool isReserved = status == 'Đang cọc giữ chỗ';
    final Color statusColor = isReserved ? Colors.deepOrange : Colors.green;

    return InkWell(
      onTap: () => _showRoomActionModal(roomId, roomData),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            // Left orange strip
            Container(
              width: 4,
              height: 180, // Match typical card height
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
              ),
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Icon, Name, Options
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.storefront_rounded, color: Colors.green, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                          ),
                        ),
                        InkWell(
                          onTap: () => _showRoomActionModal(roomId, roomData),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.more_vert, color: Colors.blue.shade600, size: 20),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  
                  // Row 2: Status Box
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.sell_outlined, size: 14, color: Colors.black54),
                            SizedBox(width: 4),
                            Text("Trạng thái", style: TextStyle(color: Colors.black87, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Container(width: 8, height: 8, decoration: BoxDecoration(color: isReserved ? Colors.deepOrange : Colors.green, shape: BoxShape.circle)),
                                  const SizedBox(width: 6),
                                  Text(status, style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                                  const SizedBox(width: 6),
                                  const Text("Chờ kỳ thu tới", style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Row 3: Price and Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00A651),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(Icons.attach_money, color: Colors.white, size: 10),
                              ),
                              const SizedBox(width: 4),
                              const Text("Giá thuê", style: TextStyle(color: Colors.black54, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$priceInfo đ",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      if (isReserved)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00A651),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(Icons.attach_money, color: Colors.white, size: 10),
                                ),
                                const SizedBox(width: 4),
                                const Text("Tiền cọc giữ chỗ", style: TextStyle(color: Colors.black54, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${_formatCurrency((roomData['depositAmount'] as num?)?.toDouble() ?? 0)} đ", 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepOrange)
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                          OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: const Color(0xFF00A651).withOpacity(0.5)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                              backgroundColor: const Color(0xFFE8F5E9),
                            ),
                            child: Row(
                              children: [
                                Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.lightBlue, shape: BoxShape.circle)),
                                const SizedBox(width: 6),
                                const Text("Lấp phòng", style: TextStyle(color: Color(0xFF00A651), fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: const Color(0xFF00A651).withOpacity(0.5)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                              backgroundColor: const Color(0xFFE8F5E9),
                            ),
                            child: Row(
                              children: [
                                Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
                                const SizedBox(width: 6),
                                const Text("Đăng tin", style: TextStyle(color: Color(0xFF00A651), fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ));
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

  Widget _buildRentedRoomCard(String roomId, Map<String, dynamic> roomData) {
    final name = roomData['roomName'] ?? 'Phòng';
    final tenantName = roomData['tenantName'] ?? 'Chưa xác định';
    final shortTenant = tenantName.isNotEmpty ? tenantName.substring(0, 1).toUpperCase() : 'H';
    final tenantPhone = roomData['tenantPhone'] ?? 'Chưa có số';
    
    final contractStart = roomData['contractStartDate'] ?? '--/--/----';
    final contractEnd = roomData['contractEndDate'] ?? '--/--/----';
    final useApp = roomData['useApp'] == true;
    final isSigned = roomData['contractSigned'] == true;
    
    final rentPrice = _formatCurrency((roomData['rentPrice'] as num?)?.toDouble() ?? (roomData['price'] as num?)?.toDouble() ?? 0);
    final depositAmount = _formatCurrency((roomData['depositAmount'] as num?)?.toDouble() ?? 0);
    final totalMembers = roomData['totalMembers'] ?? 1;

    return InkWell(
      onTap: () => _showRoomActionModal(roomId, roomData),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: const BoxDecoration(
                color: Color(0xFF00A651), // Green strip
                borderRadius: BorderRadius.horizontal(left: Radius.circular(8)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                          child: const Icon(Icons.storefront_rounded, color: Colors.green, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.phone_outlined, size: 14, color: Colors.black87),
                                  const SizedBox(width: 4),
                                  Text("$shortTenant - $tenantPhone", style: const TextStyle(color: Colors.blueAccent, fontSize: 13, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => _showRoomActionModal(roomId, roomData),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                            child: const Icon(Icons.more_vert, color: Colors.blueAccent, size: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Box Section
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          _buildBoxRow(Icons.calendar_today_outlined, "Hạn h.đồng", "$contractStart - $contractEnd"),
                          const Divider(height: 1, color: Color(0xFFF)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                const Icon(Icons.phone_android_outlined, size: 16, color: Colors.black87),
                                const SizedBox(width: 8),
                                const Text("Sử dụng APP", style: TextStyle(fontSize: 13, color: Colors.black87)),
                                const Spacer(),
                                useApp 
                                  ? Row(children: const [Icon(Icons.check_circle_outline, size: 14, color: Colors.green), SizedBox(width: 4), Text("Đang sử dụng app", style: TextStyle(color: Colors.green, fontSize: 13))])
                                  : Row(children: const [Icon(Icons.info_outline, size: 14, color: Colors.deepOrange), SizedBox(width: 4), Text("Chưa sử dụng app", style: TextStyle(color: Colors.deepOrange, fontSize: 13))]),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFF)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                const Icon(Icons.drive_file_rename_outline, size: 16, color: Colors.black87),
                                const SizedBox(width: 8),
                                const Text("Hợp đồng online", style: TextStyle(fontSize: 13, color: Colors.black87)),
                                const Spacer(),
                                isSigned 
                                  ? Row(children: const [Icon(Icons.check, size: 14, color: Colors.green), SizedBox(width: 4), Text("Đã ký", style: TextStyle(color: Colors.green, fontSize: 13))])
                                  : Row(children: const [Icon(Icons.close, size: 14, color: Colors.deepOrange), SizedBox(width: 4), Text("Khách chưa ký", style: TextStyle(color: Colors.deepOrange, fontSize: 13))]),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFF)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.sell_outlined, size: 16, color: Colors.black87),
                                const SizedBox(width: 8),
                                const Text("Trạng thái", style: TextStyle(fontSize: 13, color: Colors.black87)),
                                const Spacer(),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    _buildStatusTagLine("Đang ở", Colors.green),
                                    const SizedBox(height: 6),
                                    _buildStatusTagLine("Chờ kỳ thu tới", Colors.green),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Footer Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildFooterStat(Icons.attach_money, "Giá thuê", "$rentPrice đ", Colors.green, Colors.black87),
                        _buildFooterStat(Icons.attach_money, "Cọc đã thu", "$depositAmount đ", Colors.green, Colors.black87),
                        _buildFooterStat(Icons.person, "Khách ghi nhận", "1/$totalMembers người", Colors.green, Colors.black87, crossAxisAlignment: CrossAxisAlignment.end),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildBoxRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.black87),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.black87)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStatusTagLine(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 12, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildFooterStat(IconData icon, String label, String value, Color iconColor, Color valueColor, {CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start}) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(color: iconColor, borderRadius: BorderRadius.circular(4)),
              child: Icon(icon, size: 10, color: Colors.white),
            ),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.black54, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: valueColor)),
      ],
    );
  }
}
