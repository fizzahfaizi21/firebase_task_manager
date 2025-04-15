class Task {
  String id;
  String name;
  bool isCompleted;
  String userId;
  DateTime? dueDate;
  String? parentTaskId; // For nested tasks
  String? dayOfWeek;
  String? timeSlot;

  Task({
    required this.id,
    required this.name,
    this.isCompleted = false,
    required this.userId,
    this.dueDate,
    this.parentTaskId,
    this.dayOfWeek,
    this.timeSlot,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isCompleted': isCompleted,
      'userId': userId,
      'dueDate': dueDate?.millisecondsSinceEpoch,
      'parentTaskId': parentTaskId,
      'dayOfWeek': dayOfWeek,
      'timeSlot': timeSlot,
    };
  }

  static Task fromMap(Map<String, dynamic> map, String docId) {
    return Task(
      id: docId,
      name: map['name'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      userId: map['userId'] ?? '',
      dueDate: map['dueDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['dueDate'])
          : null,
      parentTaskId: map['parentTaskId'],
      dayOfWeek: map['dayOfWeek'],
      timeSlot: map['timeSlot'],
    );
  }
}
