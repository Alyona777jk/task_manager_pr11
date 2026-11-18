import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/presentation/auth_provider.dart';
import '../domain/task_model.dart';
import 'task_provider.dart';

/// Екран створення та редагування задачі
class TaskFormScreen extends StatefulWidget {
  final TaskModel? task;

  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late int _selectedUserId;
  late bool _completed;
  bool _isSaving = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final currentUserId = context.read<AuthProvider>().user?.id ?? 1;
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _selectedUserId = widget.task?.userId ?? currentUserId;
    _completed = widget.task?.completed ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final taskProvider = context.read<TaskProvider>();
    final title = _titleController.text.trim();

    String? error;
    if (_isEditing) {
      error = await taskProvider.updateTask(
        widget.task!.copyWith(
          title: title,
          userId: _selectedUserId,
          completed: _completed,
        ),
      );
    } else {
      error = await taskProvider.addTask(
        title: title,
        userId: _selectedUserId,
        completed: _completed,
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Редагувати задачу' : 'Нова задача'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Назва задачі',
                  hintText: 'Наприклад: Підготувати звіт для команди',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'Введіть назву задачі'
                    : null,
              ),
              const SizedBox(height: 16),
              // Прив'язка задачі до учасника команди (User ID 1..10 у JSONPlaceholder)
              DropdownButtonFormField<int>(
                initialValue: _selectedUserId,
                decoration: const InputDecoration(
                  labelText: 'Відповідальний (Team Member ID)',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                items: List.generate(10, (index) => index + 1)
                    .map(
                      (id) => DropdownMenuItem(
                        value: id,
                        child: Text('Учасник команди #$id'),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedUserId = val);
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Статус: Виконано'),
                value: _completed,
                onChanged: (val) => setState(() => _completed = val),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isEditing ? 'Зберегти зміни' : 'Створити задачу'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
