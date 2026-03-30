import 'package:flutter/material.dart';

class AddHousePage extends StatefulWidget {
  const AddHousePage({super.key});

  @override
  State<AddHousePage> createState() => _AddHousePageState();
}

class _AddHousePageState extends State<AddHousePage> {
  // Trạng thái (State) quản lý logic màn hình
  int _selectedRentType = 0; // 0: Thuê theo phòng, 1: Thuê theo giường
  bool _isAutoGenerate = true; // Switch trạng thái

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8), // Màu nền xám nhạt để tách biệt các section trắng
      appBar: AppBar(
        title: const Text(
          "Thêm mới nhà cho thuê",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildSection1(),
                  _buildSection2(),
                  _buildSection3(),
                  _buildSection4(),
                  const SizedBox(height: 20), // Khoảng cách tới footer
                ],
              ),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  // ================= CÁC SECTION UI =================

  // SECTION 1: Thông tin nhà cho thuê
  Widget _buildSection1() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            title: "Thông tin nhà cho thuê",
            subtitle: "Thông tin cơ bản tên, loại hình...",
          ),
          const SizedBox(height: 20),

          // Loại hình cho thuê
          _buildSelectionChip(
            label: "Loại hình cho thuê *",
            value: "Nhà trọ",
            onClear: () {},
          ),
          const SizedBox(height: 16),

          // Lựa chọn MH Thuê theo phòng / giường
          Row(
            children: [
              Expanded(
                child: _buildRentTypeCard(
                  title: "Thuê theo phòng",
                  subtitle: "Tính tiền thuê theo phòng",
                  icon: Icons.meeting_room_outlined,
                  isSelected: _selectedRentType == 0,
                  onTap: () => setState(() => _selectedRentType = 0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRentTypeCard(
                  title: "Thuê theo giường",
                  subtitle: "Tính tiền theo giường",
                  icon: Icons.location_city_rounded,
                  isSelected: _selectedRentType == 1,
                  onTap: () => setState(() => _selectedRentType = 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // TextField Tên Nhà trọ
          _buildLabel("Tên Nhà trọ *"),
          const SizedBox(height: 8),
          _buildTextField(
            hintText: "Ví dụ: Nguyễn Thanh",
            suffixTextWidget: _buildSuffixTag("Nhà trọ"),
          ),
        ],
      ),
    );
  }

  // SECTION 2: Cách khởi tạo dữ liệu
  Widget _buildSection2() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            title: "Cách khởi tạo dữ liệu",
            subtitle: "Theo mẫu hoặc từ excel hoặc thủ công",
          ),
          const SizedBox(height: 16),

          // Switch Đang khởi tạo tự động
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Đang khởi tạo tự động theo mẫu",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Hệ thống sẽ tự động tạo phòng mẫu theo tổng số phòng bạn nhập bên dưới.",
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isAutoGenerate,
                onChanged: (val) => setState(() => _isAutoGenerate = val),
                activeColor: const Color(0xFF28a745),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Thiết lập số tầng
          _buildSelectionChip(
            label: "Thiết lập số tầng (Gồm tầng triệt) *",
            value: "Tầng trệt (không có tầng)",
            onClear: () {},
          ),
          const SizedBox(height: 20),

          // Số lượng phòng mẫu
          _buildLabel("Số lượng phòng mẫu *"),
          const SizedBox(height: 8),
          _buildTextField(
            initialValue: "5",
            keyboardType: TextInputType.number,
            suffixTextWidget: _buildSuffixTag("phòng"),
          ),
        ],
      ),
    );
  }

  // SECTION 3: Chi tiết phòng mẫu & Tài chính
  Widget _buildSection3() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Diện tích mẫu *"),
                    const SizedBox(height: 8),
                    _buildTextField(
                      initialValue: "15",
                      keyboardType: TextInputType.number,
                      suffixTextWidget: _buildSuffixTag("m2"),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Giá thuê mẫu *"),
                    const SizedBox(height: 8),
                    _buildTextField(
                      hintText: "Nhập giá",
                      keyboardType: TextInputType.number,
                      suffixTextWidget: _buildSuffixTag("đ/tháng"),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Chú ý màu cam
          const Text(
            "* Chú ý: Đây là giá thuê & diện tích hầu hết các phòng\n* Sau khi thêm nhà bạn vẫn có thể sửa cho từng phòng",
            style: TextStyle(color: Color(0xFFe67e22), fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 20),

          // Dropdown
          _buildLabel("Tối đa người ở / phòng"),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("Chọn giá trị", style: TextStyle(fontWeight: FontWeight.bold)),
                Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // SECTION 4: Cài đặt hóa đơn
  Widget _buildSection4() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            title: "Cài đặt ngày chốt & hạn hóa đơn",
            subtitle: "Tùy chỉnh tính năng sử dụng cho Nhà trọ",
          ),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Ngày lập hóa đơn thu tiền *"),
                    const SizedBox(height: 8),
                    _buildTextField(
                      initialValue: "1",
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Nhập ngày cuối tháng hoặc ngày cố định trong tháng.",
                      style: TextStyle(fontSize: 12, color: Color(0xFFe67e22)),
                    )
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Hạn đóng tiền *"),
                    const SizedBox(height: 8),
                    _buildTextField(
                      initialValue: "5",
                      keyboardType: TextInputType.number,
                      suffixTextWidget: _buildSuffixTag("Ngày"),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Số ngày hết đóng tiền thuê kể từ ngày lập hóa đơn",
                      style: TextStyle(fontSize: 12, color: Color(0xFFe67e22)),
                    )
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Info Box (Thông báo)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFF28a745)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                // Khối vuông xanh lá cây chứa icon chữ i
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF8bc34a), // Màu xanh lá nhạt hơn chút cho khối icon theo ảnh
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(7),
                      bottomLeft: Radius.circular(7),
                    ),
                  ),
                  child: const Icon(Icons.info_outline_rounded, color: Colors.white),
                ),
                // Text thông tin
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: RichText(
                      text: const TextSpan(
                        text: "Thông tin: ",
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                        children: [
                          TextSpan(
                            text: "Khi có khách thuê không đóng tiền đúng hẹn. Phần mềm sẽ nhắc nhở bạn.",
                            style: TextStyle(fontWeight: FontWeight.normal),
                          )
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  // BOTTOM FOOTER CHỨA NÚT ACTION
  Widget _buildFooter() {
    return Container(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Linear Progress Bar ( Thanh tiến trình )
            Row(
              children: [
                Expanded(
                  flex: 1, // Màu xanh
                  child: Container(height: 4, color: const Color(0xFF28a745)),
                ),
                Expanded(
                  flex: 1, // Màu xám
                  child: Container(height: 4, color: Colors.grey.shade300),
                )
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text(
                          "Đóng",
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF28a745),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text(
                          "Tiếp theo",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  // ================= CÁC THÀNH PHẦN WIDGET DÙNG CHUNG =================

  // Header của mỗi section có icon # xanh lá
  Widget _buildHeader({required String title, required String subtitle}) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF28a745),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: const Text(
            "#",
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ],
          ),
        )
      ],
    );
  }

  // Khung viền chọn (Chip) có nút X (cho Loại hình & Tầng)
  Widget _buildSelectionChip({required String label, required String value, required VoidCallback onClear}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.black87, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          GestureDetector(
            onTap: onClear,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, size: 16, color: Colors.black87),
            ),
          )
        ],
      ),
    );
  }

  // Thẻ Thuê theo phòng / giường
  Widget _buildRentTypeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          // Mô phỏng viền dashed bằng viền đặc kèm độ mờ
          border: Border.all(
            color: isSelected ? const Color(0xFF28a745) : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? const Color(0xFF28a745) : Colors.grey.shade500,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Label Form thuần tuý
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
    );
  }

  // TextField chuẩn chung
  Widget _buildTextField({
    String? hintText,
    String? initialValue,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixTextWidget,
  }) {
    return TextFormField(
      initialValue: initialValue,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.black38),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF28a745)),
        ),
        suffixIcon: suffixTextWidget,
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      ),
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
    );
  }

  // Khối đính kèm sau TextField (vd: m2, đ/tháng, phòng)
  Widget _buildSuffixTag(String suffixText) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F3), // Xám xanh cực nhạt
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        suffixText,
        style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.normal),
      ),
    );
  }
}
