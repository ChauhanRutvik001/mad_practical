import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/task.dart';
import 'local_storage_service.dart';
import 'firebase_service.dart';

class SyncService {
  final FirebaseService _firebaseService = FirebaseService();
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isOnline = false;

  // Singleton instance
  static final SyncService _instance = SyncService._internal();

  factory SyncService() {
    return _instance;
  }

  SyncService._internal() {
    // Initial connectivity check
    _checkConnectivity();

    // Listen for connectivity changes
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((result) {
      if (result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi) {
        if (!_isOnline) {
          _isOnline = true;
          syncPendingCommands();
        }
      } else {
        _isOnline = false;
      }
    });
  }

  // Check current connectivity
  Future<void> _checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _isOnline = result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi;
  }

  // Dispose of resources
  void dispose() {
    _connectivitySubscription?.cancel();
  }

  // Get online status
  bool get isOnline => _isOnline;

  // Process a voice command based on connectivity
  Future<bool> processCommand(Map<String, dynamic> commandData) async {
    if (_isOnline) {
      // Process online
      return await _processCommandOnline(commandData);
    } else {
      // Queue for later processing
      return await LocalStorageService.queueCommand(commandData);
    }
  }

  // Process a command online
  Future<bool> _processCommandOnline(Map<String, dynamic> commandData) async {
    final action = commandData['action'] as String;

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

          final taskId = await _firebaseService.saveTask(task);
          return taskId != null;

        case 'complete':
        case 'update':
          // Find existing task in Firebase
          final tasks = await _firebaseService.getUserTasks();
          final title = commandData['title'] ?? '';
          final taskToUpdate = tasks.firstWhere(
            (task) =>
                task.title.toLowerCase().contains(title.toLowerCase()) ||
                title.toLowerCase().contains(task.title.toLowerCase()),
            orElse: () => Task(title: ''),
          );

          if (taskToUpdate.id.isEmpty) return false;

          Task updatedTask;
          if (action == 'complete') {
            updatedTask = taskToUpdate.copyWith(isCompleted: true);
          } else {
            updatedTask = taskToUpdate.copyWith(
              title: commandData['description'].isNotEmpty
                  ? commandData['description']
                  : taskToUpdate.title,
              dueDate: commandData['dueDate'] ?? taskToUpdate.dueDate,
              priority: commandData['priority'] ?? taskToUpdate.priority,
            );
          }

          return await _firebaseService.updateTask(updatedTask);

        case 'delete':
          final tasks = await _firebaseService.getUserTasks();
          final title = commandData['title'] ?? '';
          final taskToDelete = tasks.firstWhere(
            (task) =>
                task.title.toLowerCase().contains(title.toLowerCase()) ||
                title.toLowerCase().contains(task.title.toLowerCase()),
            orElse: () => Task(title: ''),
          );

          if (taskToDelete.id.isEmpty) return false;
          return await _firebaseService.deleteTask(taskToDelete.id);

        default:
          return false;
      }
    } catch (e) {
      print('Error processing command online: $e');
      return false;
    }
  }

  // Sync pending commands when coming back online
  Future<void> syncPendingCommands() async {
    try {
      print('Starting to sync pending commands...');
      final pendingCommands = await LocalStorageService.getPendingCommands();

      if (pendingCommands.isEmpty) {
        print('No pending commands to sync');
        return;
      }

      print('Found ${pendingCommands.length} pending commands to sync');

      // Process each command
      for (int i = 0; i < pendingCommands.length; i++) {
        final commandData = pendingCommands[i];
        final success = await _processCommandOnline(commandData);

        if (success) {
          await LocalStorageService.removePendingCommand(i);
          // Adjust index since we removed an item
          i--;
        }
      }

      print('Sync completed');
    } catch (e) {
      print('Error syncing pending commands: $e');
    }
  }

  // Sync local tasks with server tasks
  Future<List<Task>> syncTasks() async {
    if (!_isOnline) {
      return await LocalStorageService.getTasks();
    }

    try {
      // Get tasks from server
      final serverTasks = await _firebaseService.getUserTasks();

      // Save to local storage
      await LocalStorageService.saveTasks(serverTasks);

      return serverTasks;
    } catch (e) {
      print('Error syncing tasks: $e');
      return await LocalStorageService.getTasks();
    }
  }
}
