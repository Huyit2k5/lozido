import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lozido_app/presentation/provider/task_provider.dart';
import 'package:lozido_app/models/task_model.dart';

class CreateTaskSheet extends StatefulWidget {
  final TaskModel? taskToEdit;
  final bool isLandlord;

  const CreateTaskSheet({super.key, this.taskToEdit, this.isLandlord = true});

  @override
  State<CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends State<CreateTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _taskTypeController;
  late TextEditingController _performerController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  String? _selectedHouse;

  List<Map<String, dynamic>> _firebaseHouses = [];
  bool _isLoadingHouses = true;

  @override
  void initState() {
    super.initState();
    final task = widget.taskToEdit;
    _titleController = TextEditingController(text: task?.title ?? '');
    _taskTypeController = TextEditingController(text: task?.taskType ?? 'Hợp đồng');
    _performerController = TextEditingController(text: task?.performer ?? '');
    _descriptionController = TextEditingController(text: task?.description ?? '');
    _selectedDate = task?.deadline ?? DateTime.now().add(const Duration(days: 7));
    _selectedHouse = task?.houseName;
    _fetchHouses();
  }

  Future<void> _fetchHouses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoadingHouses = false;
      });
      return;
    }
    try {
      if (widget.isLandlord) {
        final snapshot = await FirebaseFirestore.instance
            .collection('houses')
            .where('userId', isEqualTo: user.uid)
            .get();
        final houses = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['houseName'] ?? data['propertyName'] ?? 'Chưa đặt tên',
          };
        }).toList();
        if (mounted) {
          setState(() {
            _firebaseHouses = houses;
            _isLoadingHouses = false;
          });
        }
      } else {
        // Tenant
        final tenantSnapshot = await FirebaseFirestore.instance
            .collection('tenants')
            .where('uid', isEqualTo: user.uid)
            .limit(1)
            .get();
        if (tenantSnapshot.docs.isNotEmpty) {
          final tenantData = tenantSnapshot.docs.first.data();
          final String? houseId = tenantData['houseId'];
          if (houseId != null && houseId.isNotEmpty) {
            final houseDoc = await FirebaseFirestore.instance
                .collection('houses')
                .doc(houseId)
                .get();
            final houseData = houseDoc.data();
            final houseName = houseData?['houseName'] ?? houseData?['propertyName'] ?? houseData?['name'] ?? 'Nhà trọ';
            final houses = [
              {'id': houseId, 'name': houseName}
            ];
            if (mounted) {
              setState(() {
                _firebaseHouses = houses;
                _selectedHouse = houseName;
                _isLoadingHouses = false;
              });
            }
          } else {
            if (mounted) setState(() => _isLoadingHouses = false);
          }
        } else {
          if (mounted) setState(() => _isLoadingHouses = false);
        }
      }
    } catch (e) {
      debugPrint("Lỗi tải danh sách nhà trọ: $e");
      if (mounted) {
        setState(() {
          _isLoadingHouses = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.taskToEdit != null;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? "Chỉnh sửa công việc" : "Tạo công việc mới",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              
              // Dropdown chọn Nhà
              (() {
                final houseNames = _firebaseHouses.map((h) => h['name'] as String).toList();
                if (_selectedHouse != null && !houseNames.contains(_selectedHouse)) {
                  houseNames.add(_selectedHouse!);
                }
                return _isLoadingHouses
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00A651)),
                          ),
                        ),
                      )
                    : DropdownButtonFormField<String>(
                        value: _selectedHouse,
                        decoration: const InputDecoration(
                          labelText: "Chọn Nhà",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.home_outlined),
                        ),
                        items: houseNames.map((String house) {
                          return DropdownMenuItem<String>(
                            value: house,
                            child: Text(house),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedHouse = value;
                          });
                        },
                        hint: const Text("Chọn căn nhà"),
                      );
              })(),
              const SizedBox(height: 16),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "Tiêu đề công việc",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? "Vui lòng nhập tiêu đề" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: "Mô tả ngắn",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _taskTypeController,
                decoration: const InputDecoration(
                  labelText: "Loại công việc",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? "Vui lòng nhập loại" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _performerController,
                decoration: const InputDecoration(
                  labelText: "Người thực hiện",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? "Vui lòng nhập người thực hiện" : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Hạn công việc"),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                leading: const Icon(Icons.calendar_today),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A651),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    isEdit ? "CẬP NHẬT" : "TẠO MỚI",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (widget.taskToEdit != null) {
        final updatedTask = TaskModel(
          id: widget.taskToEdit!.id,
          title: _titleController.text,
          description: _descriptionController.text,
          taskType: _taskTypeController.text,
          performer: _performerController.text,
          createdAt: widget.taskToEdit!.createdAt,
          deadline: _selectedDate,
          contractEndDate: widget.taskToEdit!.contractEndDate,
          houseName: _selectedHouse,
          status: widget.taskToEdit!.status,
        );
        context.read<TaskProvider>().updateTask(updatedTask);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã cập nhật công việc thành công")),
        );
      } else {
        context.read<TaskProvider>().createNewTask(
              title: _titleController.text,
              description: _descriptionController.text,
              taskType: _taskTypeController.text,
              performer: _performerController.text,
              deadline: _selectedDate,
              createdAt: DateTime.now(),
              houseName: _selectedHouse,
              creatorId: FirebaseAuth.instance.currentUser?.uid,
            );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã tạo công việc mới thành công")),
        );
      }
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _taskTypeController.dispose();
    _performerController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
