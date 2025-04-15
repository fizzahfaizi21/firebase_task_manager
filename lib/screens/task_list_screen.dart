import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({Key? key}) : super(key: key);

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final AuthService _auth = AuthService();
  late DatabaseService db;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _taskController = TextEditingController();
  String? selectedDay;
  String? selectedTimeSlot;
  bool showDailyTasks = false;

  List<String> weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
  List<String> timeSlots = [
    '9am-10am',
    '10am-11am',
    '11am-12pm',
    '12pm-1pm',
    '1pm-2pm',
    '2pm-3pm',
    '3pm-4pm',
    '4pm-5pm'
  ];

  @override
  void initState() {
    super.initState();
    User? user = _auth.currentUser;
    if (user != null) {
      db = DatabaseService(uid: user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Manager'),
        actions: [
          IconButton(
            icon: Icon(showDailyTasks ? Icons.list : Icons.calendar_month),
            onPressed: () {
              setState(() {
                showDailyTasks = !showDailyTasks;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Task input form
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _taskController,
                    decoration: const InputDecoration(
                      labelText: 'Enter task name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) =>
                        val!.isEmpty ? 'Please enter a task name' : null,
                  ),
                  if (showDailyTasks) ...[
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Day of Week',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedDay,
                      onChanged: (value) {
                        setState(() {
                          selectedDay = value;
                        });
                      },
                      items: weekdays.map((day) {
                        return DropdownMenuItem(
                          value: day,
                          child: Text(day),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Time Slot',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedTimeSlot,
                      onChanged: (value) {
                        setState(() {
                          selectedTimeSlot = value;
                        });
                      },
                      items: timeSlots.map((time) {
                        return DropdownMenuItem(
                          value: time,
                          child: Text(time),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Task'),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        // Create and add the task
                        final taskName = _taskController.text.trim();
                        final user = _auth.currentUser;

                        if (user != null) {
                          final task = Task(
                            id: '', // Firestore will generate ID
                            name: taskName,
                            userId: user.uid,
                            dayOfWeek: showDailyTasks ? selectedDay : null,
                            timeSlot: showDailyTasks ? selectedTimeSlot : null,
                          );

                          await db.addTask(task);
                          _taskController.clear();

                          setState(() {
                            if (showDailyTasks) {
                              selectedDay = null;
                              selectedTimeSlot = null;
                            }
                          });
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // Task List or Daily Tasks
          Expanded(
            child:
                showDailyTasks ? _buildDailyTaskView() : _buildMainTaskList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMainTaskList() {
    return StreamBuilder<List<Task>>(
      stream: db.tasks,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No tasks yet. Add some!'));
        }

        List<Task> tasks = snapshot.data!;

        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            Task task = tasks[index];
            return _buildTaskItem(task);
          },
        );
      },
    );
  }

  Widget _buildDailyTaskView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Select Day',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedDay,
                  onChanged: (value) {
                    setState(() {
                      selectedDay = value;
                    });
                  },
                  items: weekdays.map((day) {
                    return DropdownMenuItem(
                      value: day,
                      child: Text(day),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        if (selectedDay != null)
          Expanded(
            child: ListView.builder(
              itemCount: timeSlots.length,
              itemBuilder: (context, index) {
                final timeSlot = timeSlots[index];
                return _buildTimeSlotTasks(selectedDay!, timeSlot);
              },
            ),
          )
        else
          const Expanded(
            child: Center(
              child: Text('Please select a day to view tasks'),
            ),
          ),
      ],
    );
  }

  Widget _buildTimeSlotTasks(String day, String timeSlot) {
    return StreamBuilder<List<Task>>(
      stream: db.getTasksByDayAndTime(day, timeSlot),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ListTile(
            title: Text('Loading...'),
          );
        }

        List<Task> tasks = snapshot.data ?? [];

        return ExpansionTile(
          title: Text('$day, $timeSlot'),
          subtitle: Text('${tasks.length} tasks'),
          children: tasks.map((task) => _buildTaskItem(task)).toList(),
        );
      },
    );
  }

  Widget _buildTaskItem(Task task) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (bool? value) {
            if (value != null) {
              db.updateTask(
                Task(
                  id: task.id,
                  name: task.name,
                  isCompleted: value,
                  userId: task.userId,
                  dayOfWeek: task.dayOfWeek,
                  timeSlot: task.timeSlot,
                ),
              );
            }
          },
        ),
        title: Text(
          task.name,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: task.dayOfWeek != null && task.timeSlot != null
            ? Text('${task.dayOfWeek}, ${task.timeSlot}')
            : null,
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () async {
            await db.deleteTask(task.id);
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }
}
