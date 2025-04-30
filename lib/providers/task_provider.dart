import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/firebase_service.dart';
import '../services/local_storage_service.dart';
import '../services/sync_service.dart';

class TaskProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final SyncService _syncService = SyncService();
  final LocalStorageService _localStorageService = LocalStorageService();

  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _error;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isOnline => _syncService.isOnline;
  bool get isSyncing => _syncService.isSyncing;

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
        _tasks = await _syncService.getAllTasks();
      } else {
        // Offline mode - get tasks from local storage
        _tasks = await _localStorageService.getTasks();
      }
    } catch (e) {
      _error = 'Error loading tasks: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh tasks (sync with remote)
  Future<void> refreshTasks() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_syncService.isOnline) {
        await _syncService.synchronize();
      }

      // Reload tasks from local storage (which should now be updated)
      _tasks = await _localStorageService.getTasks();
    } catch (e) {
      _error = 'Error refreshing tasks: $e';
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
      // Use sync service to handle online/offline saving
      final newTask = await _syncService.addTask(task);

      // Add to local list
      _tasks.insert(0, newTask);

      _isLoading = false;
      notifyListeners();
      return true;
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
      // Use sync service to handle online/offline updating
      final updatedTask = await _syncService.updateTask(task);

      // Update in local list
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = updatedTask;
      }

      _isLoading = false;
      notifyListeners();
      return true;
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
      // Validate task ID
      if (taskId.isEmpty) {
        _error = 'Cannot delete task: Empty task ID';
        print(_error);
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Use sync service to handle online/offline deletion
      final success = await _syncService.deleteTask(taskId);

      if (success) {
        // Remove from local list
        _tasks.removeWhere((task) => task.id == taskId);
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
          // Convert the ISO8601 date string to DateTime if it exists
          DateTime? dueDate;
          if (commandData['dueDate'] != null) {
            if (commandData['dueDate'] is String) {
              dueDate = DateTime.parse(commandData['dueDate']);
            } else {
              dueDate = commandData['dueDate'];
            }
          }

          final task = Task(
            title: commandData['title'] ?? 'Untitled Task',
            description: commandData['description'] ?? '',
            dueDate: dueDate,
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
            // Convert the ISO8601 date string to DateTime if it exists
            DateTime? dueDate = taskToUpdate.dueDate;
            if (commandData['dueDate'] != null) {
              if (commandData['dueDate'] is String) {
                dueDate = DateTime.parse(commandData['dueDate']);
              } else {
                dueDate = commandData['dueDate'];
              }
            }

            final updatedTask = taskToUpdate.copyWith(
              description:
                  commandData['description'] ?? taskToUpdate.description,
              dueDate: dueDate,
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
