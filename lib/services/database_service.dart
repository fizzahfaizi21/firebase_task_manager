import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task.dart';

class DatabaseService {
  final String uid;
  final CollectionReference taskCollection =
      FirebaseFirestore.instance.collection('tasks');

  DatabaseService({required this.uid});

  // Create a new task - Fixed return type
  Future<void> addTask(Task task) async {
    await taskCollection.add(task.toMap());
    return;
  }

  // Update a task
  Future<void> updateTask(Task task) async {
    await taskCollection.doc(task.id).update(task.toMap());
    return;
  }

  // Delete a task
  Future<void> deleteTask(String taskId) async {
    // First delete all subtasks
    QuerySnapshot subTasks =
        await taskCollection.where('parentTaskId', isEqualTo: taskId).get();

    WriteBatch batch = FirebaseFirestore.instance.batch();

    // Add subtasks to the batch
    for (var doc in subTasks.docs) {
      batch.delete(doc.reference);
    }

    // Add the main task to the batch
    batch.delete(taskCollection.doc(taskId));

    // Commit the batch
    await batch.commit();
    return;
  }

  // Get user tasks stream
  Stream<List<Task>> get tasks {
    return taskCollection
        .where('userId', isEqualTo: uid)
        .where('parentTaskId', isNull: true)
        .snapshots()
        .map(_taskListFromSnapshot);
  }

  // Get subtasks for a specific task
  Stream<List<Task>> getSubtasks(String parentTaskId) {
    return taskCollection
        .where('userId', isEqualTo: uid)
        .where('parentTaskId', isEqualTo: parentTaskId)
        .snapshots()
        .map(_taskListFromSnapshot);
  }

  // Get tasks for a specific day and time slot
  Stream<List<Task>> getTasksByDayAndTime(String day, String timeSlot) {
    return taskCollection
        .where('userId', isEqualTo: uid)
        .where('dayOfWeek', isEqualTo: day)
        .where('timeSlot', isEqualTo: timeSlot)
        .snapshots()
        .map(_taskListFromSnapshot);
  }

  // Convert snapshot to task list
  List<Task> _taskListFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      return Task.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  }
}
