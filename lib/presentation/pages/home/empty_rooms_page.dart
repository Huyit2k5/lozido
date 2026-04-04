// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../room/room_detail_page.dart';
// import '../room/add_room_page.dart';

// class EmptyRoomsPage extends StatefulWidget {
//   final String houseId;
//   final Map<String, dynamic> houseData;

//   const EmptyRoomsPage({super.key, required this.houseId, required this.houseData});

//   @override
//   State<EmptyRoomsPage> createState() => _EmptyRoomsPageState();
// }

// class _EmptyRoomsPageState extends State<EmptyRoomsPage> with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   late int _floorCount;

//   @override
//   void initState() {
//     super.initState();
//     _floorCount = int.tryParse(widget.houseData['floorCount']?.toString() ?? '1') ?? 1;
//     // Tầng trệt = 1 tầng, các tầng còn lại = _floorCount 
//     _tabController = TabController(length: _floorCount + 1, vsync: this);
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     List<Tab> tabs = [const Tab(text: "Tất cả")];
//     if (_floorCount > 0) tabs.add(const Tab(text: "Tầng trệt"));
//     for (int i = 1; i < _floorCount; i++) {
//        tabs.add(Tab(text: "Tầng $i"));
//     }

//     return Scaffold(
//       backgroundColor: const Color(0xFFF3F4F6),
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         centerTitle: false,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black87),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text("Phòng đang trống", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(48),
//           child: Container(
//             color: Colors.white,
//             child: Align(
//               alignment: Alignment.centerLeft,
//               child: TabBar(
//                 controller: _tabController,
//                 isScrollable: true,
//                 indicatorColor: const Color(0xFF00A651),
//                 indicatorWeight: 3,
//                 labelColor: const Color(0xFF00A651),
//                 unselectedLabelColor: Colors.black87,
//                 labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
//                 unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
//                 tabs: tabs,
//               ),
//             ),
//           ),
//         ),
//       ),
//       body: Column(
//         children: [
//           // Banner Cảnh báo
//           Container(
//             margin: const EdgeInsets.all(16),
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             decoration: BoxDecoration(
//               color: const Color(0xFFFFF7ED),
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(color: Colors.orange.shade200),
//             ),
//             child: Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(4),
//                   decoration: const BoxDecoration(color: Color(0xFFF97316), shape: BoxShape.circle),
//                   child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: RichText(
//                     text: const TextSpan(
//                       text: "Danh sách các phòng hiện tại ",
//                       style: TextStyle(color: Colors.black87, fontSize: 14),
//                       children: [
//                         TextSpan(
//                           text: "Đang trống",
//                           style: TextStyle(color: Color(0xFFF97316), fontWeight: FontWeight.bold),
//                         )
//                       ]
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
          
//           Expanded(
//             child: TabBarView(
//               controller: _tabController,
//               children: List.generate(tabs.length, (index) {
//                 String? filterFloor;
//                 if (index == 1) filterFloor = "Tầng trệt";
//                 if (index > 1) filterFloor = "Tầng ${index - 1}";
                
//                 return _buildRoomList(filterFloor);
//               }),
//             ),
//           )
//         ],
//       ),
//     );
//   }

//   Widget _buildRoomList(String? filterFloor) {
//     Query query = FirebaseFirestore.instance
//         .collection('houses')
//         .doc(widget.houseId)
//         .collection('rooms')
//         .where('status', isEqualTo: 'Đang trống');

//     if (filterFloor != null) {
//       query = query.where('floor', isEqualTo: filterFloor);
//     }

//     return StreamBuilder<QuerySnapshot>(
//       stream: query.snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator(color: Color(0xFF00A651)));
//         }
//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
//                 const SizedBox(height: 16),
//                 Text("Không có phòng trống nào", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
//               ],
//             ),
//           );
//         }

//         final rooms = snapshot.data!.docs;

//         return ListView.separated(
//           padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
//           itemCount: rooms.length,
//           separatorBuilder: (context, index) => const SizedBox(height: 16),
//           itemBuilder: (context, index) {
//             final roomDoc = rooms[index];
//             final roomData = roomDoc.data() as Map<String, dynamic>;
//             return _buildRoomCard(roomDoc.id, roomData);
//           },
//         );
//       },
//     );
//   }

//   Widget _buildRoomCard(String roomId, Map<String, dynamic> data) {
//     final roomName = data['roomName'] ?? "N/A";
//     final price = data['price'] ?? 0;
//     final priceInfo = _formatCurrency(price.toDouble());

//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
//         ],
//       ),
//       child: IntrinsicHeight(
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Container(
//               width: 4,
//               decoration: const BoxDecoration(
//                 color: Color(0xFFF97316),
//                 borderRadius: BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
//               ),
//             ),
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Container(
//                           padding: const EdgeInsets.all(6),
//                           decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
//                           child: const Icon(Icons.storefront_rounded, color: Colors.green, size: 22),
//                         ),
//                         const SizedBox(width: 12),
//                         Text(roomName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//                         const Spacer(),
//                         _buildMoreMenu(roomId, data),
//                       ],
//                     ),
//                     const SizedBox(height: 16),
//                     _buildStatusSection(),
//                     const SizedBox(height: 16),
//                     Divider(color: Colors.grey.shade200, height: 1),
//                     const SizedBox(height: 16),
//                     _buildFooter(priceInfo),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildMoreMenu(String roomId, Map<String, dynamic> data) {
//     return InkWell(
//       onTap: () => _showRoomActionModal(roomId, data),
//       child: Container(
//         padding: const EdgeInsets.all(4),
//         decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
//         child: const Icon(Icons.more_vert, color: Colors.blue, size: 20),
//       ),
//     );
//   }

//   Widget _buildStatusSection() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         border: Border.all(color: Colors.grey.shade200),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: const [
//               Icon(Icons.local_offer_outlined, size: 16, color: Colors.black54),
//               SizedBox(width: 6),
//               Text("Trạng thái", style: TextStyle(color: Colors.black54, fontSize: 13)),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               _buildStatusChip("Đang trống", const Color(0xFFF97316)),
//             ],
//           )
//         ],
//       ),
//     );
//   }

//   Widget _buildFooter(String priceInfo) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       crossAxisAlignment: CrossAxisAlignment.end,
//       children: [
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(2),
//                   decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)),
//                   child: const Icon(Icons.attach_money, color: Colors.white, size: 12),
//                 ),
//                 const SizedBox(width: 6),
//                 const Text("Giá thuê", style: TextStyle(color: Colors.black54, fontSize: 13)),
//               ],
//             ),
//             const SizedBox(height: 6),
//             Text(priceInfo == "0" ? "Chưa cài giá" : "$priceInfo đ", 
//                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
//           ],
//         ),
//         Row(
//           children: [
//             _buildActionPill("Lấp phòng", Colors.lightBlue),
//             const SizedBox(width: 8),
//             _buildActionPill("Đăng tin", Colors.redAccent),
//           ],
//         )
//       ],
//     );
//   }

//   Widget _buildStatusChip(String label, Color color) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//       decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
//           const SizedBox(width: 6),
//           Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
//         ],
//       ),
//     );
//   }

//   Widget _buildActionPill(String label, Color dotColor) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         border: Border.all(color: Colors.green.shade400),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
//           const SizedBox(width: 6),
//           Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
//         ],
//       ),
//     );
//   }

//   void _showRoomActionModal(String roomId, Map<String, dynamic> roomData) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       isScrollControlled: true,
//       builder: (BuildContext context) {
//         return Container(
//           decoration: const BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//           ),
//           padding: const EdgeInsets.symmetric(vertical: 20),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
//               const SizedBox(height: 20),
//               Text("Phòng ${roomData['roomName']}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//               const Divider(height: 30),
//               _buildModalItem(Icons.info_outline, "Xem chi tiết phòng", () {
//                 Navigator.pop(context);
//                 Navigator.push(context, MaterialPageRoute(builder: (context) => RoomDetailPage(houseId: widget.houseId, roomId: roomId)));
//               }),
//               _buildModalItem(Icons.edit_outlined, "Sửa thông tin phòng", () {
//                 Navigator.pop(context);
//                 Navigator.push(context, MaterialPageRoute(builder: (context) => AddRoomPage(houseId: widget.houseId, houseData: widget.houseData, roomId: roomId, initialRoomData: roomData)));
//               }),
//               _buildModalItem(Icons.description_outlined, "Lập hợp đồng mới", () {}),
//               _buildModalItem(Icons.electrical_services_outlined, "Cài đặt số điện, nước, dịch vụ", () {}),
//               const SizedBox(height: 20),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildModalItem(IconData icon, String title, VoidCallback onTap) {
//     return ListTile(
//       leading: Icon(icon, color: const Color(0xFF00A651)),
//       title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
//       onTap: onTap,
//     );
//   }

//   String _formatCurrency(double amount) {
//     String str = amount.toStringAsFixed(0);
//     String result = '';
//     int count = 0;
//     for (int i = str.length - 1; i >= 0; i--) {
//       if (count == 3) {
//         result = '.$result';
//         count = 0;
//       }
//       result = str[i] + result;
//       count++;
//     }
//     return result;
//   }
// }
