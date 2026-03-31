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
  String _selectedPropertyType = "Nhà trọ"; // Khởi tạo mặc định

  final List<Map<String, String>> _propertyTypes = [
    {"name": "Nhà trọ", "desc": "Cho thuê theo phòng", "type": "Room"},
    {"name": "Ký túc xá/sleepbox", "desc": "Cho thuê theo giường", "type": "Bed"},
    {"name": "Chung cư mini", "desc": "Cho thuê theo căn hộ", "type": "Room"},
    {"name": "Tòa nhà chung cư", "desc": "Cho thuê hoặc quản lý cư dân theo căn hộ", "type": "Room"},
    {"name": "Nhà nguyên căn", "desc": "Cho thuê theo phòng/nhà", "type": "Room"},
    {"name": "Văn phòng cho thuê", "desc": "Tòa nhà văn phòng, dịch vụ văn phòng", "type": "Room"},
  ];

  String _selectedFloorCount = "Tầng trệt (không có tầng)";
  final List<String> _floorOptions = [
    "Tầng trệt (không có tầng)",
    "2 tầng (Gồm 1 trệt + 1 tầng)",
    "3 tầng (Gồm 1 trệt + 2 tầng)",
    "4 tầng (Gồm 1 trệt + 3 tầng)",
    "5 tầng (Gồm 1 trệt + 4 tầng)",
    "6 tầng (Gồm 1 trệt + 5 tầng)",
    "7 tầng (Gồm 1 trệt + 6 tầng)",
    "8 tầng (Gồm 1 trệt + 7 tầng)",
  ];

  String _selectedMaxOccupants = "Chọn giá trị";
  final List<String> _maxOccupantOptions = [
    "1 người ở",
    "2 người ở",
    "3 người ở",
    "4 người ở",
    "5-6 người ở",
    "7-10 người ở",
    "Không giới hạn",
  ];

  int _currentStep = 0; // State cho bước hiện tại
  String _dienOption = "Tính theo đồng hồ (phổ biến)";
  String _nuocOption = "Tính theo đồng hồ (phổ biến)";
  String _racOption = "Không sử dụng";
  String _internetOption = "Không sử dụng";

  bool _featureAppKhachThue = true;
  bool _featureZaloInvoice = true;
  bool _featureAssetManagement = true;
  bool _featureVehicleManagement = true;
  bool _featurePostListing = true;
  bool _featureContractFiles = true;
  bool _featureBrokerageManagement = true;
  bool _featureTaskManagement = true;
  bool _featureSmsInvoice = false;

  final List<String> _serviceOptions = [
    "Không sử dụng",
    "Tính theo người",
    "Tính theo tháng",
    "Tính theo đồng hồ (phổ biến)",
  ];

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
              child: _currentStep == 0 
                  ? Column(
                      children: [
                        _buildSection1(),
                        _buildSection2(),
                        _buildSection3(),
                        _buildSection4(),
                        const SizedBox(height: 20),
                      ],
                    )
                  : Column(
                      children: [
                        _buildServiceSection(),
                        _buildFeatureSection(),
                        _buildAddressSection(),
                        const SizedBox(height: 20),
                      ],
                    ),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  // ================= LOGIC & MODALS =================

  void _showPropertyTypeModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.all(20), // Cách xa 4 cạnh màn hình
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Modal
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.home_outlined, color: Colors.black87),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "Loại hình cho thuê",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    
                    // Danh sách lựa chọn
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _propertyTypes.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = _propertyTypes[index];
                          final isSelected = _selectedPropertyType == item['name'];
                          
                          return InkWell(
                            onTap: () {
                              // Cập nhật state ở form chính
                              setState(() {
                                _selectedPropertyType = item['name']!;
                                // Nếu chọn Ký túc xá => Thuê theo giường (1), ngược lại theo phòng (0)
                                _selectedRentType = item['type'] == 'Bed' ? 1 : 0;
                              });
                              // Tự động đóng Dialog
                              Navigator.pop(context);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['name']!,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item['desc']!,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(Icons.check_circle, color: Color(0xFF28a745), size: 24),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    // Nút Đóng (trường hợp người dùng muốn huỷ, không chọn gì)
                    SizedBox(
                      width: double.infinity,
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
                          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showFloorSelectionModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.all(20), // Cách xa 4 cạnh
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Modal
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.format_list_bulleted, color: Colors.black87),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "Thiết lập số tầng (Gồm tầng triệt)",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), // Cỡ chữ phù hợp điện thoại
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    
                    // Danh sách lựa chọn
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _floorOptions.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = _floorOptions[index];
                          final isSelected = _selectedFloorCount == item;
                          
                          return InkWell(
                            onTap: () {
                              // Cập nhật giá trị ra form
                              setState(() {
                                _selectedFloorCount = item;
                              });
                              // Đóng modal ngay
                              Navigator.pop(context);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(Icons.check_circle, color: Color(0xFF28a745), size: 24),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    // Nút Đóng
                    SizedBox(
                      width: double.infinity,
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
                          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showMaxOccupantModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.all(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Modal
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.format_list_bulleted, color: Colors.black87),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "Tối đa người ở / phòng",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    
                    // Danh sách lựa chọn
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _maxOccupantOptions.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = _maxOccupantOptions[index];
                          final isSelected = _selectedMaxOccupants == item;
                          
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedMaxOccupants = item;
                              });
                              Navigator.pop(context);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(Icons.check_circle, color: Color(0xFF28a745), size: 24),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    // Nút Đóng
                    SizedBox(
                      width: double.infinity,
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
                          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
            value: _selectedPropertyType,
            onClear: () {},
            onTap: _showPropertyTypeModal,
          ),
          const SizedBox(height: 16),

          // Lựa chọn MH Thuê theo phòng / giường
          // Ghi chú: Đã tắt onTap theo yêu cầu, chỉ hiển thị tự động cập nhật
          Row(
            children: [
              Expanded(
                child: _buildRentTypeCard(
                  title: "Thuê theo phòng",
                  subtitle: "Tính tiền thuê theo phòng",
                  icon: Icons.meeting_room_outlined,
                  isSelected: _selectedRentType == 0,
                  onTap: () {}, // Không cho phép chọn thủ công
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRentTypeCard(
                  title: "Thuê theo giường",
                  subtitle: "Tính tiền theo giường",
                  icon: Icons.location_city_rounded,
                  isSelected: _selectedRentType == 1,
                  onTap: () {}, // Không cho phép chọn thủ công
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // TextField Tên loại hình
          _buildLabel("Tên $_selectedPropertyType *"),
          const SizedBox(height: 8),
          _buildTextField(
            hintText: "Ví dụ: Nguyễn Thanh",
            suffixTextWidget: _buildSuffixTag(_selectedPropertyType),
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
            value: _selectedFloorCount,
            onClear: () {},
            onTap: _showFloorSelectionModal,
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
          GestureDetector(
            onTap: _showMaxOccupantModal,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedMaxOccupants,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      // Nếu vẫn đang hiển thị placeholder ("Chọn giá trị") thì chữ sẽ mờ hơn
                      color: _selectedMaxOccupants == "Chọn giá trị" ? Colors.black54 : Colors.black,
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black),
                ],
              ),
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

  // ================= CÁC SECTION BƯỚC 2 =================

  Widget _buildServiceSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            title: "Cài đặt dịch vụ Nhà trọ",
            subtitle: "Thiết lập các dịch vụ khách thuê sử dụng khi thuê",
          ),
          const SizedBox(height: 16),
          _buildServiceTile("Dịch vụ điện", _dienOption, (val) => _dienOption = val),
          _buildServiceTile("Dịch vụ nước", _nuocOption, (val) => _nuocOption = val),
          _buildServiceTile("Dịch vụ rác", _racOption, (val) => _racOption = val),
          _buildServiceTile("Dịch vụ internet/mạng", _internetOption, (val) => _internetOption = val),
        ],
      ),
    );
  }

  Widget _buildServiceTile(String title, String value, ValueChanged<String> onSelected) {
    return GestureDetector(
      onTap: () => _showServiceOptionModal(title, value, onSelected),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, size: 16, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  void _showServiceOptionModal(String title, String currentValue, ValueChanged<String> onSelected) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.all(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.settings_suggest_outlined, color: Colors.black87),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _serviceOptions.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = _serviceOptions[index];
                          final isSelected = currentValue == item;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                onSelected(item);
                              });
                              Navigator.pop(context);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(Icons.check_circle, color: Color(0xFF28a745), size: 24),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
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
                          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFeatureSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            title: "Cài đặt tính năng",
            subtitle: "Tùy chỉnh tính năng sử dụng cho Nhà trọ",
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildFeatureTile(
                  "APP dành riêng cho khách thuê",
                  "Tạo & kết nối dễ dàng, hoá đơn tự động, thanh toán online, ký hợp đồng online....\n* Hoàn toàn miễn phí",
                  _featureAppKhachThue,
                  (val) => setState(() => _featureAppKhachThue = val),
                ),
                const Divider(height: 1),
                _buildFeatureTile(
                  "Gửi hóa đơn tự động qua ZALO",
                  "Dễ dàng gửi hóa đơn hàng loạt qua ZALO",
                  _featureZaloInvoice,
                  (val) => setState(() => _featureZaloInvoice = val),
                ),
                const Divider(height: 1),
                _buildFeatureTile(
                  "Chức năng quản lý tài sản",
                  "Dùng để quản lý tài sản khi khách thuê sử dụng",
                  _featureAssetManagement,
                  (val) => setState(() => _featureAssetManagement = val),
                ),
                const Divider(height: 1),
                _buildFeatureTile(
                  "Chức năng quản lý xe",
                  "Dùng để quản lý xe của khách thuê",
                  _featureVehicleManagement,
                  (val) => setState(() => _featureVehicleManagement = val),
                ),
                const Divider(height: 1),
                _buildFeatureTile(
                  "Tính năng đăng tin tiếp cận khách thuê",
                  "Đăng tin tìm khách thuê, khách tiềm năng trên hệ thống LOZIDO",
                  _featurePostListing,
                  (val) => setState(() => _featurePostListing = val),
                ),
                const Divider(height: 1),
                _buildFeatureTile(
                  "Hình ảnh, File chứng từ hợp đồng",
                  "Nhằm lưu giữ thông tin CCCD, hình ảnh phòng & hợp đồng giấy",
                  _featureContractFiles,
                  (val) => setState(() => _featureContractFiles = val),
                ),
                const Divider(height: 1),
                _buildFeatureTile(
                  "Quản lý môi giới",
                  "Bạn có làm việc với môi giới? Bạn có thể lưu trữ, chi hoa hồng...",
                  _featureBrokerageManagement,
                  (val) => setState(() => _featureBrokerageManagement = val),
                ),
                const Divider(height: 1),
                _buildFeatureTile(
                  "Quản lý công việc",
                  "Báo cáo sự cố, hệ thống tự động nhắc việc, tạo việc cá nhân, nhân viên",
                  _featureTaskManagement,
                  (val) => setState(() => _featureTaskManagement = val),
                ),
                const Divider(height: 1),
                _buildFeatureTile(
                  "Gửi tin nhắn SMS tự động cho khách thuê",
                  "Khi lập hóa đơn bạn có muốn gửi tin nhắn SMS tiền nhà cho khách thuê hay không?",
                  _featureSmsInvoice,
                  (val) => setState(() => _featureSmsInvoice = val),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFeatureTile(String title, String subtitle, bool isActive, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.extension, color: Colors.blueGrey), // Icon gợi ý
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                const SizedBox(height: 4),
                // Sử dụng text thường, xử lý đoạn có đánh dâu '*' (hoặc style đặc biệt ở app thuê thực tế)
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: isActive,
            onChanged: onChanged,
            activeColor: const Color(0xFF8bc34a),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            title: "Địa chỉ & vị trí",
            subtitle: "Địa chỉ giúp khách tìm đến chính xác để xem nhà cho thuê",
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, color: Colors.black87),
              label: const Text(
                "Thêm địa chỉ & vị trí trên bản đồ",
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
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
                  flex: 1, // Màu xám hoặc xanh
                  child: Container(
                    height: 4, 
                    color: _currentStep == 0 ? Colors.grey.shade300 : const Color(0xFF28a745)
                  ),
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
                        onPressed: () {
                          if (_currentStep == 0) {
                            Navigator.pop(context);
                          } else {
                            setState(() => _currentStep = 0);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          _currentStep == 0 ? "Đóng" : "Quay lại trước",
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_currentStep == 0) {
                            setState(() => _currentStep = 1);
                          } else {
                            // Lưu thông tin logic ở đây
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF28a745),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          _currentStep == 0 ? "Tiếp theo" : "Lưu thông tin",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
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

  // Khung viền chọn (Chip) có nút X, có thể nhấn để mở pop-up (cho Loại hình & Tầng)
  Widget _buildSelectionChip({
    required String label, 
    required String value, 
    required VoidCallback onClear,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white, // Đảm bảo bắt được sự kiện tap nếu người dùng bấm vào vùng trống
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
