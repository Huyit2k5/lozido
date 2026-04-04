import 'package:flutter/material.dart';

class EmptyRoomsPage extends StatefulWidget {
  final Map<String, dynamic> houseData;

  const EmptyRoomsPage({super.key, required this.houseData});

  @override
  State<EmptyRoomsPage> createState() => _EmptyRoomsPageState();
}

class _EmptyRoomsPageState extends State<EmptyRoomsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _floorCount;
  late int _totalRooms;

  @override
  void initState() {
    super.initState();
    _floorCount = int.tryParse(widget.houseData['floorCount']?.toString() ?? '1') ?? 1;
    _totalRooms = widget.houseData['roomCount'] ?? 0;
    
    // Tầng trệt = 1 tầng, các tầng còn lại = _floorCount 
    // Chúng ta hiển thị Tất cả, Tầng trệt, Tầng 1, Tầng 2...
    _tabController = TabController(length: _floorCount + 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Tab> tabs = [const Tab(text: "Tất cả")];
    if (_floorCount > 0) tabs.add(const Tab(text: "Tầng trệt"));
    for (int i = 1; i < _floorCount; i++) {
       tabs.add(Tab(text: "Tầng $i"));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Thống kê phòng đang trống", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: Align(
              alignment: Alignment.centerLeft,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: const Color(0xFF00A651),
                indicatorWeight: 3,
                labelColor: const Color(0xFF00A651),
                unselectedLabelColor: Colors.black87,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                tabs: tabs,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Banner Cảnh báo (Thống kê danh sách phòng hiện tại Đang trống)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED), // màu nền cam nhạt
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Color(0xFFF97316), shape: BoxShape.circle),
                  child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(
                    text: const TextSpan(
                      text: "Thống kê danh sách phòng hiện tại ",
                      style: TextStyle(color: Colors.black87, fontSize: 14),
                      children: [
                        TextSpan(
                          text: "Đang trống",
                          style: TextStyle(color: Color(0xFFF97316), fontWeight: FontWeight.bold),
                        )
                      ]
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(tabs.length, (index) {
                // Hiển thị danh sách dummy chung cho mọi tab
                return _buildRoomList();
              }),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRoomList() {
    return ListView.separated(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
      itemCount: _totalRooms == 0 ? 5 : _totalRooms, // Hiển thị 5 phòng demo nếu properties chưa có phòng
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _buildRoomCard(index + 1);
      },
    );
  }

  Widget _buildRoomCard(int roomNumber) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cột highlight màu cam bên trái
            Container(
              width: 4,
              decoration: const BoxDecoration(
                color: Color(0xFFF97316), // Orange highlight
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header của Card (Icon, Tiêu đề, More icon)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.storefront_rounded, color: Colors.green, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Phòng $roomNumber",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.more_vert, color: Colors.blue, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Trạng thái Container
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.local_offer_outlined, size: 16, color: Colors.black54),
                              SizedBox(width: 6),
                              Text("Trạng thái", style: TextStyle(color: Colors.black54, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildStatusChip("Đang trống", const Color(0xFFF97316)),
                              const SizedBox(width: 12),
                              _buildStatusChip("Chờ kỳ thu tới", Colors.green),
                            ],
                          )
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    Divider(color: Colors.grey.shade200, height: 1),
                    const SizedBox(height: 16),
                    
                    // Footer (Giá thuê & Buttons)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(Icons.attach_money, color: Colors.white, size: 12),
                                ),
                                const SizedBox(width: 6),
                                const Text("Giá thuê", style: TextStyle(color: Colors.black54, fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              "15.000.000 đ",
                              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
                            )
                          ],
                        ),
                        
                        Row(
                          children: [
                            _buildActionPill("Lắp phòng", Colors.lightBlue),
                            const SizedBox(width: 8),
                            _buildActionPill("Đăng tin", Colors.redAccent),
                          ],
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildActionPill(String label, Color dotColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.green.shade400),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
        ],
      ),
    );
  }
}
