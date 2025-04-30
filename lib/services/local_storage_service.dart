import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class LocalStorageService {
  static const String _tasksKey = 'local_tasks';
  static const String _pendingCommandsKey = 'pending_commands';

  // Save tasks to local storage
  static Future<bool> saveTasks(List<Task> tasks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final taskMaps = tasks.map((task) {
        final map = task.toMap();
        map['id'] = task.id; // Make sure ID is included
        return map;
      }).toList();

      final tasksJson = json.encode(taskMaps);
      return await prefs.setString(_tasksKey, tasksJson);
    } catch (e) {
      print('Error saving tasks locally: $e');
      return false;
    }
  }

  // Get tasks from local storage
  static Future<List<Task>> getTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = prefs.getString(_tasksKey);

      if (tasksJson == null) {
        return [];
      }

      final tasksList = json.decode(tasksJson) as List;
      return tasksList.map((task) {
        final Map<String, dynamic> taskMap = Map<String, dynamic>.from(task);
        return Task.fromMap(taskMap, taskMap['id'] as String);
      }).toList();
    } catch (e) {
      print('Error retrieving local tasks: $e');
      return [];
    }
  }

  // Queue a pending command for later processing
  static Future<bool> queueCommand(Map<String, dynamic> commandData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingCommandsJson = prefs.getString(_pendingCommandsKey);

      List<Map<String, dynamic>> pendingCommands = [];
      if (pendingCommandsJson != null) {
        final decodedList = json.decode(pendingCommandsJson) as List;
        pendingCommands =
            decodedList.map((item) => Map<String, dynamic>.from(item)).toList();
      }

      // Add timestamp to command
      commandData['queuedAt'] = DateTime.now().toIso8601String();

      // Add to pending commands
      pendingCommands.add(commandData);

      // Save back to prefs
      return await prefs.setString(
          _pendingCommandsKey, json.encode(pendingCommands));
    } catch (e) {
      print('Error queueing command: $e');
      return false;
    }
  }

  // Get pending commands
  static Future<List<Map<String, dynamic>>> getPendingCommands() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingCommandsJson = prefs.getString(_pendingCommandsKey);

      if (pendingCommandsJson == null) {
        return [];
      }

      final decodedList = json.decode(pendingCommandsJson) as List;
      return decodedList
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (e) {
      print('Error retrieving pending commands: $e');
      return [];
    }
  }

  // Clear pending commands
  static Future<bool> clearPendingCommands() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_pendingCommandsKey);
    } catch (e) {
      print('Error clearing pending commands: $e');
      return false;
    }
  }

  // Clear specific pending command
  static Future<bool> removePendingCommand(int index) async {
    try {
      final pendingCommands = await getPendingCommands();
      if (index >= 0 && index < pendingCommands.length) {
        pendingCommands.removeAt(index);

        final prefs = await SharedPreferences.getInstance();
        return await prefs.setString(
            _pendingCommandsKey, json.encode(pendingCommands));
      }
      return false;
    } catch (e) {
      print('Error removing pending command: $e');
      return false;
    }
  }
}
