import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/task_model.dart';

class TaskRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getTasksStream({String? uid, bool isLandlord = true}) {
    Query query = _firestore.collection('tasks');
    
    // Nếu là khách thuê, chỉ tải các task do mình tạo
    if (!isLandlord && uid != null) {
      query = query.where('creatorId', isEqualTo: uid);
    }
    
    return query.snapshots();
  }

  Future<void> addTask(TaskModel task) async {
    await _firestore.collection('tasks').doc(task.id).set(task.toJson());
  }

  Future<void> updateTaskStatus(String id, TaskStatus newStatus) async {
    await _firestore.collection('tasks').doc(id).update({
      'status': newStatus.index,
    });
  }

  Future<void> updateTask(TaskModel updatedTask) async {
    await _firestore.collection('tasks').doc(updatedTask.id).set(updatedTask.toJson());
  }

  Future<void> deleteTask(String id) async {
    await _firestore.collection('tasks').doc(id).delete();
  }

  Future<void> denyTermination(String taskId, String reason) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'status': TaskStatus.terminationDenied.index,
      'denialReason': reason,
    });
  }
}
