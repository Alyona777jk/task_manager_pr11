class TaskModel {
  final int id;
  final int userId;
  final String title;
  final bool completed;

  const TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.completed,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      userId: json['userId'] as int? ?? 1,
      title: json['title'] as String? ?? '',
      completed: json['completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'completed': completed,
    };
  }

  TaskModel copyWith({
    int? id,
    int? userId,
    String? title,
    bool? completed,
  }) {
    return TaskModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      completed: completed ?? this.completed,
    );
  }
}
