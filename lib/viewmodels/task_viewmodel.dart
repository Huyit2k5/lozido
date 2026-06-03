import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/models/task_model.dart';
import '../data/repositories/task_repository.dart';

class TaskViewModel extends ChangeNotifier {
  final TaskRepository _repository;
  
  List<TaskModel> _tasks = [];
  bool _isLoading = true;
  StreamSubscription? _tasksSubscription;

  String? _lastUid;
  bool? _lastIsLandlord;

  TaskViewModel({TaskRepository? repository}) 
      : _repository = repository ?? TaskRepository();

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
    if (_lastUid == uid && _lastIsLandlord == isLandlord && _tasksSubscription != null) {
      return;
    }
    
    _lastUid = uid;
    _lastIsLandlord = isLandlord;
    _isLoading = true;
    notifyListeners();
    
    _tasksSubscription?.cancel();
    debugPrint("Bắt đầu tải tasks từ Repository (isLandlord: $isLandlord, uid: $uid)...");
    
    _tasksSubscription = _repository.getTasksStream(uid: uid, isLandlord: isLandlord).listen((snapshot) {
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
      await _repository.addTask(task);
    } catch (e) {
      debugPrint("Lỗi khi thêm task: $e");
    }
  }

  Future<void> updateTaskStatus(String id, TaskStatus newStatus) async {
    try {
      await _repository.updateTaskStatus(id, newStatus);
    } catch (e) {
      debugPrint("Lỗi khi cập nhật trạng thái: $e");
    }
  }

  Future<void> updateTask(TaskModel updatedTask) async {
    try {
      await _repository.updateTask(updatedTask);
    } catch (e) {
      debugPrint("Lỗi khi cập nhật task: $e");
    }
  }

  Future<void> deleteTask(String id) async {
    final removedTaskIndex = _tasks.indexWhere((t) => t.id == id);
    TaskModel? removedTask;
    if (removedTaskIndex != -1) {
      removedTask = _tasks.removeAt(removedTaskIndex);
      notifyListeners();
    }

    try {
      await _repository.deleteTask(id);
    } catch (e) {
      if (removedTask != null) {
        _tasks.insert(removedTaskIndex, removedTask);
        notifyListeners();
      }
      rethrow;
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
      await _repository.denyTermination(taskId, reason);
    } catch (e) {
      debugPrint("Lỗi khi từ chối kết thúc hợp đồng: $e");
    }
  }
}

