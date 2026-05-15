import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lozido_app/models/task_model.dart';
import 'package:lozido_app/presentation/provider/task_provider.dart';

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _performerController = TextEditingController(text: 'Chưa xác định');
  final _taskTypeController = TextEditingController(text: 'Công việc');

  DateTime? _executionDate = DateTime.now();
  DateTime? _deadline = DateTime.now();
  TaskPriority _priority = TaskPriority.medium;
  String? _selectedHouse;
  String? _selectedScope;
  final List<String> _imagePaths = [];
  bool _isSaving = false;

  final List<String> _houses = ["Nhà 1", "Nhà 2", "Nhà 3", "Nhà 4", "Nhà 5"];
  final List<String> _scopes = ["Phòng 101", "Phòng 102", "Phòng 103"];

  final Color _primaryGreen = const Color(0xFF00A651);
  final Color _bgGrey = const Color(0xFFF2F5F8);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: _bgGrey,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 80,
          leading: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
                  onPressed: () async {
                    if (await _onWillPop()) Navigator.of(context).pop();
                  },
                ),
              ),
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Chỉnh sửa công việc",
                style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                "Việc quản lý nhà cho thuê",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
          centerTitle: false,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 120),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildSection(
                  icon: Icons.tag,
                  title: "Thông tin cơ bản",
                  subtitle: "Ngày thực hiện & ngày kết thúc, mức độ ưu tiên",
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoBox(
                              label: "Ngày thực hiện",
                              value: _executionDate != null ? DateFormat('dd/MM/yyyy').format(_executionDate!) : "Chọn ngày",
                              onTap: () async {
                                final date = await _showMyDatePicker(_executionDate ?? DateTime.now());
                                if (date != null) setState(() => _executionDate = date);
                              },
                              onClear: () => setState(() => _executionDate = null),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInfoBox(
                              label: "Hạn công việc",
                              value: _deadline != null ? DateFormat('dd/MM/yyyy').format(_deadline!) : "Chọn ngày",
                              onTap: () async {
                                final date = await _showMyDatePicker(_deadline ?? DateTime.now());
                                if (date != null) setState(() => _deadline = date);
                              },
                              onClear: () => setState(() => _deadline = null),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoBox(
                        label: "Mức độ ưu tiên *",
                        value: _getPriorityText(_priority),
                        onTap: _showPriorityPicker,
                        onClear: () {},
                      ),
                    ],
                  ),
                ),
                _buildSection(
                  icon: Icons.tag,
                  title: "Phạm vi áp dụng",
                  subtitle: "Việc cá nhân, xử lý phòng, việc nhóm/công ty",
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: const Icon(Icons.home, color: Colors.black, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Phạm vi công việc *", style: TextStyle(fontSize: 12, color: Colors.red)),
                                  const Text("Việc quản lý nhà cho thuê", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdownField(
                              label: "Nhà cho thuê",
                              value: _selectedHouse,
                              items: _houses,
                              onChanged: (val) => setState(() => _selectedHouse = val),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDropdownField(
                              label: "Phòng/giường/căn hộ",
                              value: _selectedScope,
                              items: _scopes,
                              onChanged: (val) => setState(() => _selectedScope = val),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildSection(
                  icon: Icons.tag,
                  title: "Thông tin công việc/sự cố",
                  subtitle: "Mô tả công việc, sự cố rõ ràng",
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Tên việc cần làm hoặc sự cố *", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _titleController,
                              decoration: InputDecoration(
                                hintText: "Tên việc cần làm hoặc sự cố",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F9F4),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.tag, color: _primaryGreen, size: 20),
                                const SizedBox(width: 4),
                                Text("Mẫu việc", style: TextStyle(color: _primaryGreen, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text("Mô tả việc cần làm hoặc sự cố *", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 6,
                        decoration: InputDecoration(
                          hintText: "Mô tả việc cần làm hoặc sự cố",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildSection(
                  icon: Icons.tag,
                  title: "Hình ảnh công việc",
                  subtitle: "Hình ảnh mô tả thêm về công việc",
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Image.network(
                        "https://cdn-icons-png.flaticon.com/512/3342/3342137.png",
                        height: 100,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 100, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      const Text("Tối đa thêm được 5 hình ảnh", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildCircleActionButton(Icons.camera_alt, "Chụp ảnh", () => _pickImage(ImageSource.camera)),
                          const SizedBox(width: 40),
                          _buildCircleActionButton(Icons.add, "Thêm từ thư viện", () => _pickImage(ImageSource.gallery)),
                        ],
                      ),
                      if (_imagePaths.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                          ),
                          itemCount: _imagePaths.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(image: FileImage(File(_imagePaths[index])), fit: BoxFit.cover),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _imagePaths.removeAt(index)),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _buildFooter(),
      ),
    );
  }

  Widget _buildSection({required IconData icon, required String title, required String subtitle, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _primaryGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox({required String label, required String value, required VoidCallback onTap, required VoidCallback onClear}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            GestureDetector(
              onTap: onClear,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 14, color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField({required String label, String? value, required List<String> items, required Function(String?) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          DropdownButton<String>(
            value: value,
            isExpanded: true,
            hint: const Text("Chọn giá trị", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            underline: const SizedBox(),
            onChanged: onChanged,
            items: items.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)))).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.black, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryGreen,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          child: _isSaving
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("+ Thêm công việc", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }

  String _getPriorityText(TaskPriority p) {
    switch (p) {
      case TaskPriority.low: return "Thấp";
      case TaskPriority.medium: return "Trung bình";
      case TaskPriority.high: return "Cao";
    }
  }

  void _showPriorityPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: TaskPriority.values.map((p) => ListTile(
          title: Text(_getPriorityText(p)),
          onTap: () {
            setState(() => _priority = p);
            Navigator.pop(context);
          },
        )).toList(),
      ),
    );
  }

  Future<DateTime?> _showMyDatePicker(DateTime initial) async {
    return await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: _primaryGreen)),
        child: child!,
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) setState(() => _imagePaths.add(pickedFile.path));
  }

  Future<bool> _onWillPop() async {
    if (_titleController.text.isEmpty && _descriptionController.text.isEmpty) return true;
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận"),
        content: const Text("Bạn có muốn huỷ tạo công việc không?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Không")),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text("Có")),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  void _submit() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập tên công việc")));
      return;
    }
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      context.read<TaskProvider>().createNewTask(
        title: _titleController.text,
        description: _descriptionController.text,
        taskType: _taskTypeController.text,
        performer: _performerController.text,
        deadline: _deadline ?? DateTime.now(),
        executionDate: _executionDate,
        createdAt: DateTime.now(),
        houseName: _selectedHouse,
        scope: _selectedScope,
        priority: _priority,
        imagePaths: _imagePaths,
        creatorId: FirebaseAuth.instance.currentUser?.uid,
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Thêm công việc thành công"), backgroundColor: Color(0xFF00A651)));
      Navigator.of(context).pop();
    }
  }
}
