import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'add_house_page.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

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

      // 5. Thanh điều hướng dưới cùng
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF00A651),
          unselectedItemColor: Colors.grey.shade500,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.home_rounded),
              ),
              label: 'Trang chủ',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.chat_bubble_outline_rounded),
              ),
              label: 'Hộp thư',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.grid_view_rounded),
              ),
              label: 'Thêm +',
            ),
          ],
        ),
      ),
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
