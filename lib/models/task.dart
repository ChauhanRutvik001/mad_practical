class Task {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? dueDate;
  final String? voiceCommandSource;
  final bool isSynced;
  final int priority; // 1: high, 2: medium, 3: low

  Task({
    required this.title,
    this.id = '',
    this.description = '',
    this.isCompleted = false,
    DateTime? createdAt,
    this.dueDate,
    this.voiceCommandSource,
    this.isSynced = true,
    this.priority = 2, // default priority: medium
  }) : createdAt = createdAt ?? DateTime.now();

  // Create a copy of this task with modified fields
  Task copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? dueDate,
    String? voiceCommandSource,
    bool? isSynced,
    int? priority,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      voiceCommandSource: voiceCommandSource ?? this.voiceCommandSource,
      isSynced: isSynced ?? this.isSynced,
      priority: priority ?? this.priority,
    );
  }

  // Convert Task to a Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'voiceCommandSource': voiceCommandSource,
      'isSynced': isSynced,
      'priority': priority,
    };
  }

  // Create a Task from a Firebase Map
  factory Task.fromMap(Map<String, dynamic> map, [String? documentId]) {
    return Task(
      id: documentId ?? map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      voiceCommandSource: map['voiceCommandSource'],
      isSynced: map['isSynced'] ?? true,
      priority: map['priority'] ?? 2,
    );
  }

  // Create a Task from a local storage Map
  factory Task.fromLocalMap(Map<String, dynamic> map) {
    return Task.fromMap(map);
  }
}
