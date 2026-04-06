import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_room_page.dart';
import 'room_detail_page.dart';
import 'package:provider/provider.dart';
import 'contract_provider.dart';
import 'create_contract_page.dart';
import 'service_selection_page.dart';
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
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
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

  void _showRoomActionModal(String roomId, Map<String, dynamic> roomData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.deepOrange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.black87, fontSize: 14),
                          children: [
                            TextSpan(text: '${roomData['roomName']}: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: 'Trạng thái "${roomData['status'] ?? 'Đang trống'}"'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.remove_red_eye_outlined, color: Colors.black87),
                title: const Text('Xem chi tiết phòng', style: TextStyle(fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RoomDetailPage(houseId: widget.houseId, roomId: roomId, houseData: widget.houseData, initialRoomData: roomData),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: Colors.black87),
                title: const Text('Chỉnh sửa thông tin cơ bản', style: TextStyle(fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddRoomPage(houseId: widget.houseId, houseData: widget.houseData, roomId: roomId, initialRoomData: roomData),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.assignment_outlined, color: Colors.black87),
                title: const Text('Lập hợp đồng mới', style: TextStyle(fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => ChangeNotifierProvider(
                        create: (_) => ContractProvider(),
                        child: CreateContractPage(
                          houseId: widget.houseId,
                          roomId: roomId,
                          houseData: widget.houseData,
                          roomData: roomData,
                        ),
                      ),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        var tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero).chain(CurveTween(curve: Curves.easeInOut));
                        return SlideTransition(position: animation.drive(tween), child: child);
                      },
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.anchor, color: Colors.black87),
                title: const Text('Cọc giữ chỗ', style: TextStyle(fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.settings_outlined, color: Colors.black87),
                title: const Text('Thiết lập dịch vụ', style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: const Text('Dịch vụ điện, nước... của phòng'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ServiceSelectionPage(
                        houseId: widget.houseId,
                        roomId: roomId,
                        initialSelectedServices: List<Map<String, dynamic>>.from(roomData['services'] ?? []),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoomCard(String roomId, Map<String, dynamic> roomData) {
    final name = roomData['roomName'] ?? 'Phòng';
    final priceInfo = _formatCurrency((roomData['price'] as num?)?.toDouble() ?? 0);

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
              decoration: const BoxDecoration(
                color: Colors.deepOrange,
                borderRadius: BorderRadius.horizontal(left: Radius.circular(8)),
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
                                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.deepOrange, shape: BoxShape.circle)),
                                  const SizedBox(width: 6),
                                  const Text("Đang trống", style: TextStyle(fontSize: 12)),
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
}
