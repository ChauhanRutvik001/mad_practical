import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class LocalStorageService {
  // Keys for SharedPreferences
  static const String _tasksKey = 'tasks';
  static const String _deletionQueueKey = 'deletion_queue';

  // Singleton pattern
  static final LocalStorageService _instance = LocalStorageService._internal();

  factory LocalStorageService() {
    return _instance;
  }

  LocalStorageService._internal();

  // Save a task locally
  Future<Task> saveTask(Task task) async {
    final prefs = await SharedPreferences.getInstance();
    final tasks = await getTasks();

    // Generate a local ID if the task doesn't have one
    final taskToSave = task.id.isEmpty
        ? task.copyWith(id: 'local_${DateTime.now().millisecondsSinceEpoch}')
        : task;

    // Add the new task (or replace existing one with same ID)
    final taskIndex = tasks.indexWhere((t) => t.id == taskToSave.id);
    if (taskIndex >= 0) {
      tasks[taskIndex] = taskToSave;
    } else {
      tasks.add(taskToSave);
    }

    // Save the updated list
    await _saveTasks(tasks);
    return taskToSave;
  }

  // Update an existing task
  Future<Task> updateTask(Task task) async {
    final tasks = await getTasks();

    // Find and update the task
    final taskIndex = tasks.indexWhere((t) => t.id == task.id);
    if (taskIndex >= 0) {
      tasks[taskIndex] = task;
      await _saveTasks(tasks);
      return task;
    } else {
      // If task doesn't exist locally, save it as new
      return saveTask(task);
    }
  }

  // Delete a task
  Future<bool> deleteTask(String taskId) async {
    final tasks = await getTasks();
    final initialLength = tasks.length;

    tasks.removeWhere((task) => task.id == taskId);

    if (tasks.length < initialLength) {
      await _saveTasks(tasks);
      return true;
    }
    return false;
  }

  // Get a specific task by ID
  Future<Task?> getTask(String taskId) async {
    final tasks = await getTasks();
    try {
      return tasks.firstWhere((task) => task.id == taskId);
    } catch (e) {
      return null;
    }
  }

  // Get all local tasks
  Future<List<Task>> getTasks() async {
    final prefs = await SharedPreferences.getInstance();

    // Get the JSON string containing tasks
    final tasksJsonString = prefs.getString(_tasksKey);
    if (tasksJsonString == null || tasksJsonString.isEmpty) {
      return [];
    }

    try {
      // Parse the JSON
      final List<dynamic> tasksList = json.decode(tasksJsonString);
      final tasks = tasksList.map((taskMap) {
        // Include id in the map for local storage
        Map<String, dynamic> fullMap = Map<String, dynamic>.from(taskMap);

        // Make sure the ID field exists and is not empty
        if (taskMap['id'] != null && taskMap['id'].toString().isNotEmpty) {
          return Task.fromMap(fullMap);
        } else {
          // If no ID or empty ID, generate a new local ID
          String taskId =
              'local_${DateTime.now().millisecondsSinceEpoch}_${taskMap.hashCode}';
          fullMap['id'] = taskId;
          return Task.fromMap(fullMap);
        }
      }).toList();

      // Deduplicate tasks if needed
      return _deduplicateTasks(tasks);
    } catch (e) {
      print('Error parsing tasks from storage: $e');
      return [];
    }
  }

  // Helper to remove duplicate tasks from a list
  List<Task> _deduplicateTasks(List<Task> tasks) {
    // Use a map to track unique tasks based on title + createdAt
    final Map<String, Task> uniqueTasks = {};

    // Sort by ID first (preserving Firebase IDs over local ones)
    tasks.sort((a, b) {
      if (a.id.startsWith('local_') && !b.id.startsWith('local_')) {
        return 1; // b comes first
      } else if (!a.id.startsWith('local_') && b.id.startsWith('local_')) {
        return -1; // a comes first
      } else {
        return 0; // preserve original order
      }
    });

    // Then deduplicate based on title+createdAt
    for (final task in tasks) {
      // Create a unique key for each task based on title and creation time
      final uniqueKey = '${task.title}|${task.createdAt.toIso8601String()}';

      // Only keep the first task with this key (which will be the non-local ID due to sorting)
      if (!uniqueTasks.containsKey(uniqueKey)) {
        uniqueTasks[uniqueKey] = task;
      }
    }

    return uniqueTasks.values.toList();
  }

  // Clean up duplicate tasks in storage and return the cleaned list
  Future<List<Task>> cleanupDuplicateTasks() async {
    final tasks = await getTasks();
    final deduplicatedTasks = _deduplicateTasks(tasks);

    // Only save if the number of tasks changed
    if (deduplicatedTasks.length != tasks.length) {
      await _saveTasks(deduplicatedTasks);
      print(
          'Cleaned up ${tasks.length - deduplicatedTasks.length} duplicate tasks');
    }

    return deduplicatedTasks;
  }

  // Get all unsynced tasks
  Future<List<Task>> getUnsyncedTasks() async {
    final tasks = await getTasks();
    return tasks.where((task) => !task.isSynced).toList();
  }

  // Save the full task list
  Future<void> _saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();

    // Convert tasks to JSON
    final tasksMaps = tasks.map((task) {
      // Make sure to include the ID in the map
      Map<String, dynamic> taskMap = task.toMap();
      taskMap['id'] = task.id; // Add ID to ensure it's preserved
      return taskMap;
    }).toList();

    final tasksJsonString = json.encode(tasksMaps);

    // Save to SharedPreferences
    await prefs.setString(_tasksKey, tasksJsonString);
  }

  // Add a task ID to the deletion queue
  Future<void> addToDeletionQueue(String taskId) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = await getDeletionQueue();

    if (!queue.contains(taskId)) {
      queue.add(taskId);
      await prefs.setStringList(_deletionQueueKey, queue);
    }
  }

  // Remove a task ID from the deletion queue
  Future<void> removeFromDeletionQueue(String taskId) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = await getDeletionQueue();

    if (queue.contains(taskId)) {
      queue.remove(taskId);
      await prefs.setStringList(_deletionQueueKey, queue);
    }
  }

  // Get the deletion queue
  Future<List<String>> getDeletionQueue() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_deletionQueueKey) ?? [];
  }

  // Clear all local task data
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tasksKey);
    await prefs.remove(_deletionQueueKey);
  }
}
