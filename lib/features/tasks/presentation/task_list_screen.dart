import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../../auth/presentation/auth_provider.dart';
import '../domain/task_model.dart';
import 'task_form_screen.dart';
import 'task_provider.dart';

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final authProvider = context.watch<AuthProvider>();
    final tasks = taskProvider.filteredTasks;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Team Tasks'),
            // Статистика в AppBar
            Text(
              'Виконано: ${taskProvider.completedCount} | Активних: ${taskProvider.activeCount}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.indigo.shade700,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Оновити',
            icon: const Icon(Icons.refresh),
            onPressed: () => taskProvider.loadTasks(),
          ),
          IconButton(
            tooltip: 'Вийти (${authProvider.user?.email ?? ""})',
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Індикатор offline режиму
          if (!taskProvider.isOnline) const OfflineBanner(),

          // Пошук по title (Extra)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Пошук задачі за назвою...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: taskProvider.setSearchQuery,
            ),
          ),

          // Фільтрація: All / Active / Completed
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SegmentedButton<TaskFilter>(
              segments: const [
                ButtonSegment(value: TaskFilter.all, label: Text('All')),
                ButtonSegment(value: TaskFilter.active, label: Text('Active')),
                ButtonSegment(
                  value: TaskFilter.completed,
                  label: Text('Completed'),
                ),
              ],
              selected: {taskProvider.filter},
              onSelectionChanged: (set) => taskProvider.setFilter(set.first),
            ),
          ),

          // Список задач
          Expanded(
            child: _buildBody(context, taskProvider, tasks),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TaskFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Задача'),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    TaskProvider provider,
    List<TaskModel> tasks,
  ) {
    if (provider.isLoading && tasks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null && tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(provider.error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: provider.loadTasks,
                child: const Text('Спробувати знову'),
              ),
            ],
          ),
        ),
      );
    }

    if (tasks.isEmpty) {
      return const Center(child: Text('Задач не знайдено'));
    }

    return RefreshIndicator(
      onRefresh: provider.loadTasks,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: tasks.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final task = tasks[index];
          return Card(
            elevation: 1,
            child: ListTile(
              leading: Checkbox(
                value: task.completed,
                onChanged: (_) => provider.toggleTaskStatus(task),
              ),
              title: Text(
                task.title,
                style: TextStyle(
                  decoration:
                      task.completed ? TextDecoration.lineThrough : null,
                  color: task.completed ? Colors.grey : null,
                ),
              ),
              subtitle: Text('Team Member #${task.userId}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskFormScreen(task: task),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 20, color: Colors.redAccent),
                    onPressed: () async {
                      final err = await provider.deleteTask(task.id);
                      if (err != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(err)),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
