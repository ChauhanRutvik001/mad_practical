import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/firebase_service.dart';
import '../services/local_storage_service.dart';
import '../services/sync_service.dart';

class TaskProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final SyncService _syncService = SyncService();

  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _error;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  TaskProvider() {
    loadTasks();
  }

  Future<void> loadTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_syncService.isOnline) {
        // Try to sync tasks first
        _tasks = await _syncService.syncTasks();
      } else {
        // Offline mode - get tasks from local storage
        _tasks = await LocalStorageService.getTasks();
      }
    } catch (e) {
      _error = 'Error loading tasks: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a new task
  Future<bool> addTask(Task task) async {
    _isLoading = true;
    notifyListeners();

    try {
      String? taskId;

      if (_syncService.isOnline) {
        // Save to Firebase
        taskId = await _firebaseService.saveTask(task);
      } else {
        // Create a local ID
        taskId = 'local_${DateTime.now().millisecondsSinceEpoch}';
      }

      // If successful, add to local list
      if (taskId != null) {
        final newTask =
            task.copyWith(id: taskId, isSynced: _syncService.isOnline);
        _tasks.insert(0, newTask);

        // Save tasks to local storage too
        await LocalStorageService.saveTasks(_tasks);

        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error adding task: $e';
      print(_error);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update an existing task
  Future<bool> updateTask(Task task) async {
    _isLoading = true;
    notifyListeners();

    try {
      bool success = false;

      if (_syncService.isOnline) {
        // Update in Firebase
        success = await _firebaseService.updateTask(task);
      } else {
        // Mark as not synced yet
        success = true;
      }

      if (success) {
        // Update in local list
        final index = _tasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _tasks[index] = task.copyWith(isSynced: _syncService.isOnline);

          // Save tasks to local storage
          await LocalStorageService.saveTasks(_tasks);
        }
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = 'Error updating task: $e';
      print(_error);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete a task
  Future<bool> deleteTask(String taskId) async {
    _isLoading = true;
    notifyListeners();

    try {
      bool success = false;

      if (_syncService.isOnline) {
        // Delete from Firebase
        success = await _firebaseService.deleteTask(taskId);
      } else {
        // Mark as successful locally
        success = true;
      }

      if (success) {
        // Remove from local list
        _tasks.removeWhere((task) => task.id == taskId);

        // Save updated list to local storage
        await LocalStorageService.saveTasks(_tasks);
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = 'Error deleting task: $e';
      print(_error);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Toggle completion status of a task
  Future<bool> toggleTaskCompletion(Task task) async {
    final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
    return await updateTask(updatedTask);
  }

  // Process a voice command
  Future<bool> processVoiceCommand(Map<String, dynamic> commandData) async {
    final action = commandData['action'] as String;
    bool success = false;

    try {
      switch (action) {
        case 'add':
          final task = Task(
            title: commandData['title'] ?? 'Untitled Task',
            description: commandData['description'] ?? '',
            dueDate: commandData['dueDate'],
            priority: commandData['priority'] ?? 2,
            voiceCommandSource: commandData['rawCommand'],
          );
          success = await addTask(task);
          break;

        case 'complete':
          final title = commandData['title'] ?? '';
          final taskToComplete = _tasks.firstWhere(
            (task) => task.title.toLowerCase().contains(title.toLowerCase()),
            orElse: () => Task(title: ''),
          );

          if (taskToComplete.id.isNotEmpty) {
            success = await toggleTaskCompletion(taskToComplete);
          }
          break;

        case 'delete':
          final title = commandData['title'] ?? '';
          final taskToDelete = _tasks.firstWhere(
            (task) => task.title.toLowerCase().contains(title.toLowerCase()),
            orElse: () => Task(title: ''),
          );

          if (taskToDelete.id.isNotEmpty) {
            success = await deleteTask(taskToDelete.id);
          }
          break;

        case 'update':
          final title = commandData['title'] ?? '';
          final taskToUpdate = _tasks.firstWhere(
            (task) => task.title.toLowerCase().contains(title.toLowerCase()),
            orElse: () => Task(title: ''),
          );

          if (taskToUpdate.id.isNotEmpty) {
            final updatedTask = taskToUpdate.copyWith(
              title: commandData['description'].isNotEmpty
                  ? commandData['description']
                  : taskToUpdate.title,
              dueDate: commandData['dueDate'] ?? taskToUpdate.dueDate,
              priority: commandData['priority'] ?? taskToUpdate.priority,
            );
            success = await updateTask(updatedTask);
          }
          break;
      }

      return success;
    } catch (e) {
      _error = 'Error processing voice command: $e';
      print(_error);
      notifyListeners();
      return false;
    }
  }
}
