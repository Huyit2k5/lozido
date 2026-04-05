import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_house_page.dart';
import 'mail_page.dart';
import '../room/room_list_page.dart';
import 'empty_rooms_page.dart';
import '../service/service_management_page.dart';
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String? _selectedHouseId;
  bool _hasPushedToAdd = false;

  // ĐƯỜNG LINK FILE EXCEL MẪU CỦA BẠN SẼ ĐƯỢC CHÈN VÀO ĐÂY (Google Drive, Dropbox, Server riêng, v.v.)
  // Ví dụ: https://storage.googleapis.com/your-bucket/mau_lozido_v1.xlsx
  final String _sampleExcelLink = "https://drive.google.com/uc?export=download&id=1Ujo6y-soKobWUjp0l6qZCljGy7RbDU2F";

  // Hàm xử lý việc tải/mở Web Browser để Download File Excel
  Future<void> _downloadExcel() async {
    final Uri url = Uri.parse(_sampleExcelLink);
    try {
      if (await canLaunchUrl(url)) {
        // Mở URL bằng trình duyệt ngoài của hệ thống để bắt đầu quá trình tải file
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở đường dẫn tải file Excel')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Đang yêu cầu đăng nhập...")));
    }

    return DefaultTabController(
      length: 2,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('houses')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF00A651))));
        }

        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text("Lỗi tải dữ liệu. Vui lòng thử lại sau!")));
        }

        final docs = snapshot.data?.docs ?? [];

        // Trường hợp 1: Chưa có nhà -> hiển thị Empty State và tự động chuyển trang 1 lần
        if (docs.isEmpty) {
          if (!_hasPushedToAdd) {
            _hasPushedToAdd = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddHousePage()),
              );
            });
          }
          return _buildEmptyState();
        }

        // Trường hợp 2: Đã có nhà
        // Mặc định chọn nhà đầu tiên trong danh sách nếu chưa có chọn lựa
        if (_selectedHouseId == null || !docs.any((d) => d.id == _selectedHouseId)) {
          // Tránh setState ngay trong builder, dùng addPostFrameCallback
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectedHouseId = docs.first.id;
              });
            }
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF00A651))));
        }

        final selectedDoc = docs.firstWhere((d) => d.id == _selectedHouseId);
        final houseData = selectedDoc.data() as Map<String, dynamic>;

        return _buildDashboard(docs, selectedDoc, houseData);
      },
    ));
  }

  Widget _buildEmptyState() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 1. Fake Status Bar (Mô phỏng 100% như yêu cầu ảnh chụp)
          _buildFakeStatusBar(),

          // 2. Nội dung chính kéo cuộn
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // Hình ảnh vector Toà nhà thành phố
                  _buildCityIllustration(),
                  const SizedBox(height: 25),

                  // Tiêu đề & Mô tả
                  const Text(
                    "Đầu tiên hãy tạo nhà để quản lý",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Bạn có thể quản lý không giới hạn số tòa nhà & số phòng/giường/căn hộ.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 25),

                  // 3. Khu vực hướng dẫn chính (Nền xanh lá nhạt)
                  _buildInstructionContainer(),
                  const SizedBox(height: 25),

                  // 4. Các nút hành động
                  _buildActionButtons(),
                  const SizedBox(height: 35),

                  // Footer nhỏ phía dưới
                  _buildFooterSection(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(List<QueryDocumentSnapshot> docs, QueryDocumentSnapshot selectedDoc, Map<String, dynamic> houseData) {
    // Ưu tiên houseName (hoặc propertyName) thay vì Hello World
    final propertyName = (houseData['houseName'] ?? houseData['propertyName'] ?? "Hello World").toString(); 
    
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5), // Nền xám nhạt
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header xanh lá mượt mà
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF00A651),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.home_outlined, color: Colors.black87, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Đang quản lý Nhà trọ", style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 2),
                          GestureDetector(
                            onTap: () => _showHouseSwitcher(docs, selectedDoc.id),
                            child: Row(
                              children: [
                                Text(
                                  propertyName.isEmpty ? "Hello World" : propertyName,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF00A651), size: 20),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.menu_rounded, color: Colors.black87, size: 20),
                      ),
                    ],
                  )
                ],
              ),
            ),
            
            // 2. Tab Switcher
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                  ]
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: TabBar(
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: const BoxDecoration(
                      color: Color(0xFF1877F2), // Màu xanh dương highlight
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.black87,
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.inventory_2_outlined, size: 18),
                            SizedBox(width: 8),
                            Text("Quản lý", style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.show_chart_rounded, size: 18),
                            SizedBox(width: 8),
                            Text("Tổng quan", style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Nội dung cuộn được
            Expanded(
              child: TabBarView(
                children: [
                  SingleChildScrollView(
                    key: const ValueKey('ManagementTab'),
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: _buildManagementTab(selectedDoc.id, houseData),
                  ),
                  SingleChildScrollView(
                    key: const ValueKey('OverviewTab'),
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: _buildOverviewTab(selectedDoc.id, houseData, propertyName),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementTab(String houseId, Map<String, dynamic> houseData) {
    return Column(
      children: [
        // Notification Banner
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF5F5), // Cam/hồng nhẹ
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFE0E0)),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.notifications_active_rounded, color: Colors.orange, size: 28),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Text("1", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("Cho phép điện thoại nhận thông báo!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        SizedBox(height: 6),
                        Text("Phần mềm sẽ không hoạt động đúng nếu bạn không cho phép nhận thông báo", style: TextStyle(color: Colors.black87, fontSize: 13, height: 1.3)),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.settings, color: Colors.black87, size: 18),
                  label: const Text("Cho phép nhận thông báo", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    surfaceTintColor: Colors.white,
                    elevation: 0,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Section: Thao tác thường dùng
        _buildSectionHeader("Thao tác thường dùng", "Thực hiện tác vụ nhanh để quản lý nhà trọ"),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.95,
            children: [
              _buildGridItem(icon: Icons.handshake_outlined, color: Colors.green, title: "Cọc giữ chỗ"),
              _buildGridItem(icon: Icons.post_add_rounded, color: Colors.green, title: "Lập hợp đồng\nmới", badge: "5"),
              _buildGridItem(icon: Icons.find_replace_rounded, color: Colors.green, title: "Thanh lý\n(Trả phòng)"),
              _buildGridItem(icon: Icons.receipt_long_outlined, color: Colors.green, title: "Lập hóa đơn"),
              _buildGridItem(icon: Icons.calculate_outlined, color: Colors.green, title: "Chốt & Lập\nhóa đơn"),
              _buildGridItem(icon: Icons.request_quote_outlined, color: Colors.green, title: "Hóa đơn\ncần thu tiền"),
            ],
          ),
        ),
        
        const SizedBox(height: 24),

        // Section: Menu quản lý nhà trọ
        _buildSectionHeader("Menu quản lý nhà trọ", "Quản lý đối tượng nghiệp vụ trong nhà trọ"),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.95,
            children: [
              _buildGridItem(
                icon: Icons.fact_check_outlined, 
                color: Colors.green, 
                title: "Quản lý\nphòng", 
                badge: "0/5",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RoomListPage(
                        houseId: houseId,
                        houseData: houseData,
                      ),
                    ),
                  );
                },
              ),
              _buildGridItem(icon: Icons.receipt_outlined, color: Colors.green, title: "Quản lý\nhóa đơn"),
              _buildGridItem(
                icon: Icons.edit_document,
                color: Colors.green,
                title: "Quản lý\ndịch vụ",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ServiceManagementPage(
                        houseId: houseId,
                        houseData: houseData,
                      ),
                    ),
                  );
                },
              ),
              _buildGridItem(icon: Icons.analytics_outlined, color: Colors.green, title: "Quản lý\nhợp đồng"),
              _buildGridItem(icon: Icons.support_agent_rounded, color: Colors.green, title: "Quản lý\nkhách thuê"),
              _buildGridItem(icon: Icons.local_mall_outlined, color: Colors.green, title: "Quản lý\ntài sản"),
              _buildGridItem(icon: Icons.local_parking_rounded, color: Colors.green, title: "Danh sách\nxe"),
              _buildGridItem(icon: Icons.handshake_outlined, color: Colors.green, title: "Cài đặt APP\nkhách thuê"),
              _buildGridItem(icon: Icons.settings_applications_outlined, color: Colors.green, title: "Cài đặt\nhóa đơn"),
              _buildGridItem(icon: Icons.home_repair_service_outlined, color: Colors.grey, title: "Cài đặt\nnhà trọ"),
            ],
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildOverviewTab(String houseId, Map<String, dynamic> houseData, String propertyName) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('houses')
          .doc(houseId)
          .collection('rooms')
          .snapshots(),
      builder: (context, snapshot) {
        // Mặc định ban đầu lấy từ houseData nếu stream chưa có data
        int totalRooms = houseData['roomCount'] ?? 0;
        int emptyRooms = totalRooms; // Giả định ban đầu
        int rentedRooms = 0;

        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          totalRooms = docs.length;
          emptyRooms = docs.where((d) => (d.data() as Map<String, dynamic>)['status'] == 'Đang trống').length;
          rentedRooms = docs.where((d) => (d.data() as Map<String, dynamic>)['status'] == 'Đã thuê').length;
        }

        return Column(
          children: [
            // Thống kê hiện trạng Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Thống kê hiện trạng", style: TextStyle(color: Colors.black54, fontSize: 13)),
                      const SizedBox(height: 6),
                      Text(propertyName, style: const TextStyle(color: Color(0xFF00A651), fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text("Tổng số phòng", style: TextStyle(color: Colors.black54, fontSize: 13)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text("$totalRooms", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const Text(" phòng", style: TextStyle(fontSize: 15)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Tình trạng phòng Header
            _buildSectionHeader("Tình trạng phòng", "Tình trạng phòng đang thuê trong hệ thống"),
            
            // Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildOverviewStatCard(icon: Icons.shopping_cart_outlined, iconColor: Colors.red.shade400, iconBgColor: Colors.red.shade50, title: "Số phòng có thể cho thuê", count: emptyRooms, percent: totalRooms > 0 ? "${((emptyRooms / totalRooms) * 100).toInt()}%" : "0%", percentColor: Colors.orange.shade700)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildOverviewStatCard(
                        icon: Icons.inventory_2_outlined,
                        iconColor: Colors.white,
                        iconBgColor: Colors.red.shade400,
                        title: "Số phòng đang trống",
                        count: emptyRooms,
                        percent: totalRooms > 0 ? "${((emptyRooms / totalRooms) * 100).toInt()}%" : "0%",
                        percentColor: Colors.orange.shade700,
                        onTap: () {
                          // Navigator.push(context, MaterialPageRoute(builder: (context) => EmptyRoomsPage(houseId: houseId, houseData: houseData)));
                        },
                      )),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildOverviewStatCard(icon: Icons.inventory_2, iconColor: Colors.white, iconBgColor: Colors.blue.shade600, title: "Số phòng đang thuê", count: rentedRooms, percent: totalRooms > 0 ? "${((rentedRooms / totalRooms) * 100).toInt()}%" : "0%", percentColor: Colors.green.shade600)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildOverviewStatCard(icon: Icons.warning_amber_rounded, iconColor: Colors.black87, iconBgColor: Colors.amber.shade400, title: "Số phòng sắp kết thúc hợp đồng", count: 0, percent: "0%", percentColor: Colors.orange.shade700)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildOverviewStatCard(icon: Icons.assignment_outlined, iconColor: Colors.black87, iconBgColor: Colors.amber.shade400, title: "Số phòng báo kết thúc hợp đồng", count: 0, percent: "0%", percentColor: Colors.orange.shade700)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildOverviewStatCard(icon: Icons.access_time_rounded, iconColor: Colors.white, iconBgColor: Colors.black87, title: "Số phòng quá hạn hợp đồng", count: 0, percent: "0%", percentColor: Colors.orange.shade700)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildOverviewStatCard(icon: Icons.attach_money_rounded, iconColor: Colors.white, iconBgColor: Colors.green.shade500, title: "Số phòng đang nợ", count: 0, percent: "0%", percentColor: Colors.orange.shade700)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildOverviewStatCard(icon: Icons.anchor_rounded, iconColor: Colors.white, iconBgColor: Colors.blueGrey.shade500, title: "Số phòng đang cọc", count: 0, percent: "0%", percentColor: Colors.green.shade600)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        );
      }
    );
  }

  Widget _buildOverviewStatCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required int count,
    required String percent,
    required Color percentColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text("$count", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: percentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(percent, style: TextStyle(color: percentColor, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded, color: Colors.black54, size: 20),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    ));
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 18,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF00A651),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 13)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGridItem({required IconData icon, required Color color, required String title, String? badge, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 38, color: color.withOpacity(0.7)),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
              ),
            ],
          ),
          if (badge != null)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade700,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    ));
  }

  void _showHouseSwitcher(List<QueryDocumentSnapshot> docs, String currentHouseId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Chọn nhà trọ muốn quản lý",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final isSelected = doc.id == currentHouseId;
                    
                    final displayTitle = (data['houseName'] ?? data['propertyName'] ?? "Hello World").toString();
                    
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFE8F5E9) : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.home_work_rounded,
                          color: isSelected ? const Color(0xFF00A651) : Colors.grey,
                        ),
                      ),
                      title: Text(
                        displayTitle.isEmpty ? 'Hello World' : displayTitle,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? const Color(0xFF00A651) : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        data['address'] != null ? (data['address']['summary'] ?? 'Chưa có địa chỉ') : 'Chưa có địa chỉ',
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: isSelected 
                        ? const Icon(Icons.check_circle_rounded, color: Color(0xFF00A651))
                        : null,
                      onTap: () {
                        setState(() {
                          _selectedHouseId = doc.id;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add, color: Colors.blue.shade700),
                ),
                title: Text(
                  "Thêm nhà trọ mới",
                  style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddHousePage()),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // ================= CÁC THÀNH PHẦN UI =================

  // 1. Fake Status Bar
  Widget _buildFakeStatusBar() {
    return Container(
      color: Colors.white, // Khớp với màu nền hệ thống nếu có
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top > 0 ? MediaQuery.of(context).padding.top : 10,
        left: 20,
        right: 20,
        bottom: 10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "15:06",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          Row(
            children: [
              const Icon(Icons.signal_cellular_alt_rounded, size: 16, color: Colors.black87),
              const SizedBox(width: 4),
              const Icon(Icons.wifi_rounded, size: 16, color: Colors.black87),
              const SizedBox(width: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text("52%", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(width: 2),
                  Icon(Icons.battery_5_bar_rounded, size: 18, color: Colors.black87),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }

  // 2. Head Flat Vector Illustration (Vẽ tay ngẫu hứng bằng code mô tả khu đô thị)
  Widget _buildCityIllustration() {
    return SizedBox(
      height: 140,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Đám mây trái
          Positioned(
            top: 20,
            left: 50,
            child: Container(
              width: 40,
              height: 12,
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
            ),
          ),
          // Đám mây phải
          Positioned(
            top: 10,
            right: 80,
            child: Container(
              width: 30,
              height: 10,
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
            ),
          ),
          // Mặt trời
          Positioned(
            top: 5,
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(color: Color(0xFFFFC107), shape: BoxShape.circle),
            ),
          ),
          // Tòa nhà xám đậm (Sau)
          Positioned(
            bottom: 0,
            child: Container(
              width: 70,
              height: 110,
              decoration: const BoxDecoration(color: Color(0xFF455A64)),
              child: _buildWindows(rows: 6, cols: 3),
            ),
          ),
          // Tòa nhà xám nhạt (Trước phải)
          Positioned(
            bottom: 0,
            right: 70,
            child: Container(
              width: 50,
              height: 80,
              decoration: const BoxDecoration(color: Color(0xFF78909C)),
              child: _buildWindows(rows: 4, cols: 2),
            ),
          ),
          // Tòa nhà đỏ đậm (Trái)
          Positioned(
            bottom: 0,
            left: 70,
            child: Container(
              width: 60,
              height: 70,
              decoration: const BoxDecoration(color: Color(0xFFE57373)),
              child: _buildWindows(rows: 3, cols: 2),
            ),
          ),
          // Tòa nhà đỏ tươi (Giữa trước)
          Positioned(
            bottom: 0,
            child: Container(
              width: 60,
              height: 90,
              decoration: const BoxDecoration(color: Color(0xFFEF5350)),
              child: _buildWindows(rows: 5, cols: 2),
            ),
          ),
          // Biển quảng cáo trên nhà xám nhạt
          Positioned(
            bottom: 80,
            right: 80,
            child: Container(
              width: 30,
              height: 10,
              decoration: BoxDecoration(color: const Color(0xFFEF5350), borderRadius: BorderRadius.circular(2)),
            ),
          ),
        ],
      ),
    );
  }

  // Hàm phụ trợ tạo cửa sổ cho vector building
  Widget _buildWindows({required int rows, required int cols}) {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          rows,
          (index) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              cols,
              (index) => Container(
                width: 8,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 3. Hộp hướng dẫn (Container nền xanh lá)
  Widget _buildInstructionContainer() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // Bề mặt nền xanh nhạt
        Container(
          margin: const EdgeInsets.only(top: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F8F1), // Nền xanh lá cực nhạt
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.fromLTRB(16, 40, 16, 16), // Padding trên chừa chỗ cho Icon
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, spreadRadius: 1),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 25),
                // Heading
                const Text(
                  "Bắt đầu tạo nhà từ file excel",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Tạo nhanh hơn từ excel sẵn có của bạn",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 15),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),

                // Bước 1
                _buildListStep(
                  icon: Icons.download_rounded,
                  title: "Tải xuống file excel mẫu",
                  subtitle: "Tải file mẫu từ LOZIDO",
                ),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                
                // Bước 2
                _buildListStep(
                  icon: Icons.edit_note_rounded,
                  title: "Nhập dữ liệu",
                  subtitle: "Nhập hoặc copy dữ của bạn vào file excel mẫu",
                ),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                
                // Bước 3
                _buildListStep(
                  icon: Icons.upload_rounded,
                  title: "Tải lên file đã nhập",
                  subtitle: "Sau khi nhập dữ liệu và kiểm tra bạn tải lên để hoàn thành khởi tạo",
                  isLast: true,
                ),
              ],
            ),
          ),
        ),

        // Icon Excel lồi lên trên rìa
        Positioned(
          top: 0,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F8F1), // Chặn viền cắt vào icon
              shape: BoxShape.circle,
            ),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D32), // Màu xanh Excel đậm
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              alignment: Alignment.center,
              child: const Text(
                "X",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Row item cho List Hướng dẫn
  Widget _buildListStep({required IconData icon, required String title, required String subtitle, bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(top: 15, bottom: isLast ? 20 : 15, left: 16, right: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vòng tròn chứa Icon màu đen đơn sắc
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 14),
          // Khối văn bản
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 4. Khu vực Nút bấm hành động
  Widget _buildActionButtons() {
    return Column(
      children: [
        // Hàng nút Excel (Tải Xuống / Tải Lên)
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: _downloadExcel,
                  icon: const Icon(Icons.arrow_downward_rounded, size: 18, color: Color(0xFF00A651)),

                  label: const Text(
                    "Tải excel xuống",
                    style: TextStyle(color: Color(0xFF00A651), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF00A651)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.arrow_upward_rounded, size: 18, color: Colors.white),
                  label: const Text(
                    "Tải excel lên",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A651),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Divider kèm chữ ở giữa (Khởi tạo nhà...)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            children: [
              const Expanded(child: Divider(color: Colors.black12, thickness: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: const [
                    Text("Khởi tạo nhà theo mẫu / thủ công", style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w600)),
                    SizedBox(width: 4),
                    Icon(Icons.swap_vert_rounded, size: 16, color: Colors.black54),
                  ],
                ),
              ),
              const Expanded(child: Divider(color: Colors.black12, thickness: 1)),
            ],
          ),
        ),

        // Hàng nút Thủ Công (Hướng dẫn / Tạo mới nhà)
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.play_arrow_rounded, size: 20, color: Color(0xFFDC3545)),
                  label: const Text(
                    "Hướng dẫn",
                    style: TextStyle(color: Color(0xFFDC3545), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFDC3545)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddHousePage()),
                    );
                  },
                  icon: const Icon(Icons.home_work_rounded, size: 18, color: Colors.yellow), // Icon nhà (xanh mượn đỡ yellow cho nổi)
                  label: const Text(
                    "Tạo mới nhà",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),

                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1877F2), // Màu xanh dương chuẩn
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 5. Khu vực text mờ dưới cùng (Quản lý trên máy tính)
  Widget _buildFooterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFF00A651), // Điểm nhấn marker màu xanh lá
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              "Quản lý trên MÁY TÍNH",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
            ),
          ],
        ),
        // Ở đây tuỳ ảnh chụp có nội dung gì, thường là đường kẻ mờ hoặc chữ mờ,
        // Dựa vào context thì chỉ cần show tiêu đề.
      ],
    );
  }
}
