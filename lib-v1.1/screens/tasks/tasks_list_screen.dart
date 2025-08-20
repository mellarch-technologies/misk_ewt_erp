import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/task_provider.dart';

class TasksListScreen extends StatelessWidget {
  const TasksListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TaskProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Tasks'),
      ),
      body: RefreshIndicator(
        onRefresh: provider.fetchTasks,
        child: provider.isBusy
            ? Center(child: CircularProgressIndicator())
            : provider.tasks.isEmpty
                ? Center(child: Text('No tasks found.'))
                : ListView.builder(
                    itemCount: provider.tasks.length,
                    itemBuilder: (ctx, i) => ListTile(
                      title: Text(provider.tasks[i].title),
                      subtitle: Text(provider.tasks[i].description ?? ''),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          // Delete task logic
                        },
                      ),
                    ),
                  ),
      ),
    );
  }
}
