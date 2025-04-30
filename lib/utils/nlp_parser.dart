import '../models/task.dart';

class NLPParser {
  // Parse a voice command and return an action and task details
  static Map<String, dynamic> parseVoiceCommand(String command) {
    final normalizedCommand = command.toLowerCase().trim();

    // Detect action type
    String action = 'add'; // Default action

    if (normalizedCommand.startsWith('add') ||
        normalizedCommand.startsWith('create') ||
        normalizedCommand.startsWith('new')) {
      action = 'add';
    } else if (normalizedCommand.startsWith('complete') ||
        normalizedCommand.startsWith('finish') ||
        normalizedCommand.startsWith('done')) {
      action = 'complete';
    } else if (normalizedCommand.startsWith('delete') ||
        normalizedCommand.startsWith('remove')) {
      action = 'delete';
    } else if (normalizedCommand.startsWith('list') ||
        normalizedCommand.startsWith('show') ||
        normalizedCommand.startsWith('what')) {
      action = 'list';
    } else if (normalizedCommand.startsWith('update') ||
        normalizedCommand.startsWith('edit') ||
        normalizedCommand.startsWith('change')) {
      action = 'update';
    }

    // Extract task title and description
    String title = '';
    String description = '';
    DateTime? dueDate;
    int priority = 2; // Default priority: medium

    // Extract title based on action
    if (action == 'add' || action == 'update') {
      // For add: "add a task to buy groceries"
      // For update: "update task buy groceries to buy organic groceries"

      if (action == 'add') {
        final parts = normalizedCommand.split(' ');
        if (parts.length > 2) {
          // Remove the action words
          title = parts.sublist(2).join(' ');

          // Look for "to" or "task" as separation points
          if (title.contains(' to ')) {
            final taskParts = title.split(' to ');
            if (taskParts.length > 1) {
              title = taskParts[1];
            }
          } else if (title.contains(' task ')) {
            final taskParts = title.split(' task ');
            if (taskParts.length > 1) {
              title = taskParts[1];
            }
          }
        }
      } else {
        // For update, the format is more complex
        if (normalizedCommand.contains(' to ')) {
          final parts = normalizedCommand.split(' to ');
          if (parts.length > 1) {
            // The first part contains the task to update
            final firstPart = parts[0];
            if (firstPart.contains(' task ')) {
              title = firstPart.split(' task ')[1].trim();
            }

            // The second part contains the new title
            description = parts[1].trim();
          }
        }
      }
    } else if (action == 'complete' || action == 'delete') {
      // For complete: "complete task buy groceries"
      // For delete: "delete task buy groceries"

      if (normalizedCommand.contains(' task ')) {
        final parts = normalizedCommand.split(' task ');
        if (parts.length > 1) {
          title = parts[1].trim();
        }
      }
    }

    // Extract priority from command
    if (normalizedCommand.contains('high priority') ||
        normalizedCommand.contains('important')) {
      priority = 1;
    } else if (normalizedCommand.contains('low priority')) {
      priority = 3;
    }

    // Extract due date from command (basic implementation)
    if (normalizedCommand.contains('tomorrow')) {
      dueDate = DateTime.now().add(const Duration(days: 1));
    } else if (normalizedCommand.contains('next week')) {
      dueDate = DateTime.now().add(const Duration(days: 7));
    } else if (normalizedCommand.contains('today')) {
      dueDate = DateTime.now();
    }

    return {
      'action': action,
      'title': title,
      'description': description,
      'dueDate': dueDate,
      'priority': priority,
      'rawCommand': command,
    };
  }

  // Find a task that matches a given title (fuzzy match)
  static Task? findMatchingTask(List<Task> tasks, String title) {
    if (title.isEmpty) return null;

    // Simple fuzzy match - can be improved with more sophisticated algorithms
    for (final task in tasks) {
      if (task.title.toLowerCase().contains(title.toLowerCase()) ||
          title.toLowerCase().contains(task.title.toLowerCase())) {
        return task;
      }
    }

    return null;
  }
}
