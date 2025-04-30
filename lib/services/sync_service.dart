import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/task.dart';
import '../services/firebase_service.dart';
import '../services/local_storage_service.dart';

class SyncService {
  final FirebaseService _firebaseService = FirebaseService();
  final LocalStorageService _localStorageService = LocalStorageService();
  final Connectivity _connectivity = Connectivity();

  bool _isOnline = false;
  bool _isSyncing = false;

  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Timer? _periodicSyncTimer;

  // Singleton pattern
  static final SyncService _instance = SyncService._internal();

  factory SyncService() {
    return _instance;
  }

  SyncService._internal() {
    _initConnectivity();
    _setupConnectivityListener();
  }

  // Initialize connectivity state
  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      print('Failed to get connectivity status: $e');
      _isOnline = false;
    }
  }

  // Setup listener for connectivity changes
  void _setupConnectivityListener() {
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      _updateConnectionStatus(result);
    });

    // Setup a periodic sync attempt every 5 minutes
    _periodicSyncTimer =
        Timer.periodic(const Duration(minutes: 5), (Timer t) async {
      if (_isOnline && !_isSyncing) {
        await synchronize();
      }
    });
  }

  // Update connectivity status and trigger sync if needed
  void _updateConnectionStatus(ConnectivityResult result) async {
    final wasOffline = !_isOnline;
    _isOnline = result != ConnectivityResult.none;

    // If we just came back online, trigger a sync
    if (wasOffline && _isOnline) {
      print('Network connection restored. Starting sync...');
      await synchronize();
    } else if (!_isOnline) {
      print('Network connection lost. Tasks will be stored locally.');
    }
  }

  // Get the current online status
  bool get isOnline => _isOnline;

  // Get the current syncing status
  bool get isSyncing => _isSyncing;

  // Add a task with proper sync handling
  Future<Task> addTask(Task task) async {
    // Always save to local storage first
    Task localTask = await _localStorageService.saveTask(task);

    // If online, also save to Firebase
    if (_isOnline) {
      try {
        final taskId = await _firebaseService.saveTask(localTask);
        if (taskId != null) {
          // Update the local task with server ID and synced status
          localTask = localTask.copyWith(
            id: taskId,
            isSynced: true,
          );

          // Update the local storage with the synced task
          await _localStorageService.updateTask(localTask);
        }
      } catch (e) {
        print('Error saving task to Firebase: $e');
        // Keep the task in local storage with isSynced = false
      }
    }

    return localTask;
  }

  // Update a task with sync handling
  Future<Task> updateTask(Task task) async {
    // Always update local storage
    Task updatedLocalTask = await _localStorageService.updateTask(task);

    // If online and task was previously synced, update Firebase
    if (_isOnline && task.isSynced) {
      try {
        final success = await _firebaseService.updateTask(updatedLocalTask);
        if (success) {
          updatedLocalTask = updatedLocalTask.copyWith(isSynced: true);
        } else {
          updatedLocalTask = updatedLocalTask.copyWith(isSynced: false);
        }
      } catch (e) {
        print('Error updating task in Firebase: $e');
        updatedLocalTask = updatedLocalTask.copyWith(isSynced: false);
      }
    } else {
      // Mark as not synced if we're offline
      updatedLocalTask = updatedLocalTask.copyWith(isSynced: false);
    }

    // Make sure local storage is up to date with sync status
    await _localStorageService.updateTask(updatedLocalTask);
    return updatedLocalTask;
  }

  // Delete a task with sync handling
  Future<bool> deleteTask(String taskId) async {
    // Check if taskId is empty
    if (taskId.isEmpty) {
      print('Cannot delete task: Empty task ID');
      return false;
    }

    // Always delete from local storage first
    await _localStorageService.deleteTask(taskId);

    // If online, also delete from Firebase
    if (_isOnline) {
      try {
        await _firebaseService.deleteTask(taskId);
        return true;
      } catch (e) {
        print('Error deleting task from Firebase: $e');
        // Add task ID to a deletion queue for later sync
        await _localStorageService.addToDeletionQueue(taskId);
        return false;
      }
    } else {
      // Add to deletion queue for later sync
      await _localStorageService.addToDeletionQueue(taskId);
      return true;
    }
  }

  // Get all tasks with proper merge of local and remote
  Future<List<Task>> getAllTasks() async {
    // Get local tasks first
    List<Task> tasks = await _localStorageService.getTasks();

    // If online, try to sync with remote
    if (_isOnline) {
      try {
        await synchronize();
        // Get updated list after sync
        tasks = await _localStorageService.getTasks();
      } catch (e) {
        print('Error syncing tasks: $e');
      }
    }

    return tasks;
  }

  // Main synchronization method
  Future<void> synchronize() async {
    if (_isSyncing || !_isOnline) return;

    _isSyncing = true;
    print('Starting synchronization...');

    try {
      // Process deletion queue first
      List<String> deletionQueue =
          await _localStorageService.getDeletionQueue();
      for (String taskId in deletionQueue) {
        try {
          await _firebaseService.deleteTask(taskId);
          await _localStorageService.removeFromDeletionQueue(taskId);
        } catch (e) {
          print('Error deleting task $taskId during sync: $e');
        }
      }

      // Get all unsynced local tasks
      List<Task> unsyncedTasks = await _localStorageService.getUnsyncedTasks();

      for (Task task in unsyncedTasks) {
        try {
          if (task.id.isEmpty) {
            // New task that hasn't been synced yet
            final taskId = await _firebaseService.saveTask(task);
            if (taskId != null) {
              Task syncedTask = task.copyWith(id: taskId, isSynced: true);
              await _localStorageService.updateTask(syncedTask);
            }
          } else {
            // Existing task that needs updating
            final success = await _firebaseService.updateTask(task);
            if (success) {
              Task syncedTask = task.copyWith(isSynced: true);
              await _localStorageService.updateTask(syncedTask);
            }
          }
        } catch (e) {
          print('Error syncing task ${task.id}: $e');
        }
      }

      // Get all remote tasks and merge with local
      final remoteTasks = await _firebaseService.getUserTasks();

      // For each remote task, make sure it exists locally
      for (Task remoteTask in remoteTasks) {
        try {
          Task? localTask = await _localStorageService.getTask(remoteTask.id);

          if (localTask == null) {
            // New remote task, add to local storage
            await _localStorageService
                .saveTask(remoteTask.copyWith(isSynced: true));
          } else if (remoteTask.createdAt.isAfter(localTask.createdAt)) {
            // Remote task is newer, update local (conflict resolution)
            await _localStorageService
                .updateTask(remoteTask.copyWith(isSynced: true));
          }
        } catch (e) {
          print('Error processing remote task ${remoteTask.id}: $e');
        }
      }

      print('Synchronization completed');
    } catch (e) {
      print('Error during synchronization: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // Manually trigger a synchronization
  Future<bool> forceSynchronize() async {
    if (!_isOnline) return false;

    try {
      await synchronize();
      return true;
    } catch (e) {
      print('Error forcing synchronization: $e');
      return false;
    }
  }

  // Clean up resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _periodicSyncTimer?.cancel();
  }
}
