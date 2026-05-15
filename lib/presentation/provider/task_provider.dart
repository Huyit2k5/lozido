import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:lozido_app/models/task_model.dart';

class TaskProvider extends ChangeNotifier {
  List<TaskModel> _tasks = [];
  bool _isLoading = true;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _tasksSubscription;

  String? _lastUid;
  bool? _lastIsLandlord;

  List<TaskModel> get tasks => [..._tasks];
  
  int get uncompletedTasksCount => _tasks.where((t) => 
    t.status == TaskStatus.newRequest || 
    t.status == TaskStatus.pendingTermination
  ).length;
  
  List<TaskModel> getTasksByCreator(String uid) {
    return _tasks.where((t) => t.creatorId == uid).toList();
  }

  int getUncompletedCountForCreator(String uid) {
    return _tasks.where((t) => 
      t.creatorId == uid && 
      (t.status == TaskStatus.newRequest || t.status == TaskStatus.pendingTermination)
    ).length;
  }

  bool get isLoading => _isLoading;

  void loadTasks({String? uid, bool isLandlord = true}) {
    // Tránh load lại nếu tham số không thay đổi
    if (_lastUid == uid && _lastIsLandlord == isLandlord && _tasksSubscription != null) {
      return;
    }
    
    _lastUid = uid;
    _lastIsLandlord = isLandlord;
    _isLoading = true;
    notifyListeners();
    
    _tasksSubscription?.cancel();
    debugPrint("Bắt đầu tải tasks từ Firestore (isLandlord: $isLandlord, uid: $uid)...");
    
    Query query = _firestore.collection('tasks');
    
    // Nếu là khách thuê, chỉ tải các task do mình tạo
    if (!isLandlord && uid != null) {
      query = query.where('creatorId', isEqualTo: uid);
    }
    
    _tasksSubscription = query.snapshots().listen((snapshot) {
      debugPrint("Đã nhận được ${snapshot.docs.length} documents từ Firestore");
      
      final List<TaskModel> loadedTasks = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final task = TaskModel.fromJson({...data, 'id': doc.id});
          loadedTasks.add(task);
        } catch (e) {
          debugPrint("Lỗi khi parse document ${doc.id}: $e");
        }
      }
      
      // Sắp xếp: Ưu tiên công việc "Cần làm" (0, 3) lên đầu, "Đã xong" (1, 2, 4, 5) xuống cuối.
      // Trong cùng nhóm thì sắp xếp theo thời gian mới nhất.
      loadedTasks.sort((a, b) {
        bool isADone = a.status == TaskStatus.confirmed || 
                       a.status == TaskStatus.ignored || 
                       a.status == TaskStatus.terminationCompleted || 
                       a.status == TaskStatus.terminationDenied ||
                       a.status == TaskStatus.cancelled;
                       
        bool isBDone = b.status == TaskStatus.confirmed || 
                       b.status == TaskStatus.ignored || 
                       b.status == TaskStatus.terminationCompleted || 
                       b.status == TaskStatus.terminationDenied ||
                       b.status == TaskStatus.cancelled;
        
        if (!isADone && isBDone) return -1;
        if (isADone && !isBDone) return 1;
        
        return b.createdAt.compareTo(a.createdAt);
      });
      
      _tasks = loadedTasks;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      debugPrint("Lỗi khi tải dữ liệu từ Firestore: $e");
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> addTask(TaskModel task) async {
    try {
      debugPrint("Đang ghi task ${task.id} lên Firestore...");
      debugPrint("Data: ${task.toJson()}");
      await _firestore.collection('tasks').doc(task.id).set(task.toJson());
      debugPrint("Ghi task thành công!");
    } catch (e) {
      debugPrint("Lỗi khi thêm task lên Firestore: $e");
    }
  }

  Future<void> updateTaskStatus(String id, TaskStatus newStatus) async {
    try {
      debugPrint("Đang cập nhật trạng thái task $id thành ${newStatus.index}...");
      await _firestore.collection('tasks').doc(id).update({
        'status': newStatus.index,
      });
      debugPrint("Cập nhật trạng thái thành công!");
    } catch (e) {
      debugPrint("Lỗi khi cập nhật trạng thái trên Firestore: $e");
    }
  }

  Future<void> updateTask(TaskModel updatedTask) async {
    try {
      debugPrint("Đang cập nhật toàn bộ task ${updatedTask.id}...");
      await _firestore.collection('tasks').doc(updatedTask.id).set(updatedTask.toJson());
      debugPrint("Cập nhật task thành công!");
    } catch (e) {
      debugPrint("Lỗi khi cập nhật task trên Firestore: $e");
    }
  }

  Future<void> deleteTask(String id) async {
    // Optimistic UI: Xóa tạm thời trong bộ nhớ để người dùng thấy ngay
    final removedTaskIndex = _tasks.indexWhere((t) => t.id == id);
    TaskModel? removedTask;
    if (removedTaskIndex != -1) {
      removedTask = _tasks.removeAt(removedTaskIndex);
      notifyListeners();
    }

    try {
      debugPrint("Đang xóa task $id trên Firestore...");
      await _firestore.collection('tasks').doc(id).delete();
      debugPrint("Xóa task thành công trên Firestore!");
    } catch (e) {
      debugPrint("Lỗi khi xóa task trên Firestore: $e");
      // Nếu lỗi, khôi phục lại task trong bộ nhớ
      if (removedTask != null) {
        _tasks.insert(removedTaskIndex, removedTask);
        notifyListeners();
      }
      rethrow; // Đẩy lỗi ra ngoài để UI xử lý
    }
  }

  Future<void> createNewTask({
    required String title,
    required String description,
    required String taskType,
    required String performer,
    required DateTime deadline,
    DateTime? executionDate,
    required DateTime createdAt,
    String? houseName,
    String? scope,
    TaskPriority priority = TaskPriority.medium,
    List<String> imagePaths = const [],
    TaskStatus status = TaskStatus.newRequest,
    String? contractId,
    String? sender,
    double? contractValue,
    double? deposit,
    String? creatorId,
  }) async {
    debugPrint("Bắt đầu createNewTask: $title");
    final id = const Uuid().v4();
    final newTask = TaskModel(
      id: id,
      title: title,
      description: description,
      taskType: taskType,
      performer: performer,
      createdAt: createdAt,
      deadline: deadline,
      executionDate: executionDate,
      contractEndDate: deadline.add(const Duration(days: 365)),
      houseName: houseName,
      scope: scope,
      priority: priority,
      imagePaths: imagePaths,
      status: status,
      contractId: contractId,
      sender: sender,
      contractValue: contractValue,
      deposit: deposit,
      creatorId: creatorId,
    );
    await addTask(newTask);
  }

  bool hasPendingTermination(String contractId) {
    return _tasks.any((task) => 
      task.contractId == contractId && 
      task.status == TaskStatus.pendingTermination
    );
  }

  TaskModel? getTerminationTask(String contractId) {
    final terminationTasks = _tasks.where((t) => 
      t.contractId == contractId && 
      (t.taskType == "Kết thúc hợp đồng" || t.status == TaskStatus.pendingTermination || t.status == TaskStatus.terminationCompleted || t.status == TaskStatus.terminationDenied)
    ).toList();
    
    if (terminationTasks.isEmpty) return null;
    return terminationTasks.first;
  }

  Future<void> confirmTermination(String taskId) async {
    await updateTaskStatus(taskId, TaskStatus.terminationCompleted);
  }

  Future<void> denyTermination(String taskId, String reason) async {
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        'status': TaskStatus.terminationDenied.index,
        'denialReason': reason,
      });
    } catch (e) {
      debugPrint("Lỗi khi từ chối kết thúc hợp đồng: $e");
    }
  }
}
