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
      return tasksList.map((taskMap) {
        // Include id in the map for local storage
        Map<String, dynamic> fullMap = Map<String, dynamic>.from(taskMap);
        if (taskMap['id'] != null) {
          return Task.fromMap(fullMap);
        } else {
          // Fallback for legacy data format
          String id = fullMap['id'] ?? '';
          return Task.fromMap(fullMap, id);
        }
      }).toList();
    } catch (e) {
      print('Error parsing tasks from storage: $e');
      return [];
    }
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
    final tasksMaps = tasks.map((task) => task.toMap()).toList();
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
