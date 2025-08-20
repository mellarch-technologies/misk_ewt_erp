import 'package:flutter/material.dart';
import '../../models/task_model.dart';

class TaskDetailScreen extends StatelessWidget {
  final Task task;
  const TaskDetailScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Task Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title: ${task.title}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Description: ${task.description ?? "-"}'),
            SizedBox(height: 8),
            Text('Status: ${task.status}'),
            SizedBox(height: 8),
            Text('Due Date: ${task.dueDate?.toDate().toString() ?? "-"}'),
            // Add more fields as needed
          ],
        ),
      ),
    );
  }
}

