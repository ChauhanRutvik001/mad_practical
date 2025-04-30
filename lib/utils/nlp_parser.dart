import '../models/task.dart';
import 'package:intl/intl.dart';

class NLPParser {
  // Parse a voice command and return an action and task details
  static Map<String, dynamic> parseVoiceCommand(String command) {
    final normalizedCommand = command.toLowerCase().trim();

    // Result map to store parsed data
    final result = <String, dynamic>{
      'action': 'add', // Default action
      'rawCommand': command,
    };

    // Detect action type
    if (_containsAnyOf(normalizedCommand, ['add', 'create', 'new', 'make'])) {
      result['action'] = 'add';
    } else if (_containsAnyOf(normalizedCommand,
        ['complete', 'finish', 'done', 'mark as done', 'mark complete'])) {
      result['action'] = 'complete';
    } else if (_containsAnyOf(
        normalizedCommand, ['delete', 'remove', 'trash', 'erase'])) {
      result['action'] = 'delete';
    } else if (_containsAnyOf(
        normalizedCommand, ['list', 'show', 'what', 'display', 'see'])) {
      result['action'] = 'list';
    } else if (_containsAnyOf(
        normalizedCommand, ['update', 'edit', 'change', 'modify'])) {
      result['action'] = 'update';
    } else if (_containsAnyOf(
        normalizedCommand, ['remind', 'reminder', 'remember', 'alert'])) {
      result['action'] = 'remind';
    }

    // Extract task details based on the action
    switch (result['action']) {
      case 'add':
        _parseAddCommand(normalizedCommand, result);
        break;
      case 'complete':
      case 'delete':
        _parseBasicCommand(normalizedCommand, result);
        break;
      case 'update':
        _parseUpdateCommand(normalizedCommand, result);
        break;
      case 'remind':
        _parseRemindCommand(normalizedCommand, result);
        break;
      case 'list':
        // Nothing specific to parse for list action
        break;
    }

    return result;
  }

  // Helper to check if string contains any of the keywords
  static bool _containsAnyOf(String text, List<String> keywords) {
    return keywords.any((keyword) =>
        text.contains(keyword) ||
        text.startsWith(keyword) ||
        text.split(' ').contains(keyword));
  }

  // Parse "add" type commands
  static void _parseAddCommand(String command, Map<String, dynamic> result) {
    String taskText = command;

    // Remove action keywords from the beginning
    final actionWords = ['add', 'create', 'new', 'make'];
    for (final word in actionWords) {
      if (taskText.startsWith(word)) {
        taskText = taskText.replaceFirst(RegExp('^$word\\s+'), '');
        break;
      }
    }

    // Remove "task to" or "a task to" if present
    taskText = taskText
        .replaceFirst(RegExp('task to\\s+', caseSensitive: false), '')
        .replaceFirst(RegExp('a task to\\s+', caseSensitive: false), '')
        .replaceFirst(RegExp('a task\\s+', caseSensitive: false), '');

    // Extract priority if mentioned
    int? priority;
    if (command.contains('high priority') ||
        command.contains('important') ||
        command.contains('urgent')) {
      priority = 1;
      taskText = taskText
          .replaceFirst(RegExp('high priority', caseSensitive: false), '')
          .replaceFirst(RegExp('important', caseSensitive: false), '')
          .replaceFirst(RegExp('urgent', caseSensitive: false), '');
    } else if (command.contains('medium priority')) {
      priority = 2;
      taskText = taskText.replaceFirst(
          RegExp('medium priority', caseSensitive: false), '');
    } else if (command.contains('low priority') ||
        command.contains('not urgent') ||
        command.contains('not important')) {
      priority = 3;
      taskText = taskText
          .replaceFirst(RegExp('low priority', caseSensitive: false), '')
          .replaceFirst(RegExp('not urgent', caseSensitive: false), '')
          .replaceFirst(RegExp('not important', caseSensitive: false), '');
    }

    // Set priority if found
    if (priority != null) {
      result['priority'] = priority;
    }

    // Extract date if mentioned
    final dateInfo = _extractDateFromText(taskText);
    if (dateInfo['date'] != null) {
      result['dueDate'] = dateInfo['date'];
      taskText = dateInfo['text']; // Updated text with date removed
    }

    // Extract description if it contains "with description" or similar
    String? description;
    final descRegex = RegExp('with\\s+(?:description|note|comment)\\s+(.+)',
        caseSensitive: false);
    final descMatch = descRegex.firstMatch(taskText);
    if (descMatch != null) {
      description = descMatch.group(1);
      taskText = taskText.replaceFirst(descRegex, '');
    }

    // Clean up any extra spaces
    taskText = taskText.trim();

    result['title'] = taskText;
    if (description != null) {
      result['description'] = description;
    }
  }

  // Parse basic commands like "complete" or "delete"
  static void _parseBasicCommand(String command, Map<String, dynamic> result) {
    String taskText = command;

    // Remove action keywords
    final actionWords = [
      'complete',
      'finish',
      'done',
      'mark as done',
      'mark complete',
      'delete',
      'remove',
      'trash',
      'erase'
    ];
    for (final word in actionWords) {
      if (taskText.startsWith(word)) {
        taskText = taskText.replaceFirst(RegExp('^$word\\s+'), '');
        break;
      }
    }

    // Remove "task" if present
    taskText =
        taskText.replaceFirst(RegExp('task\\s+', caseSensitive: false), '');

    result['title'] = taskText.trim();
  }

  // Parse update commands
  static void _parseUpdateCommand(String command, Map<String, dynamic> result) {
    // First identify the task to update
    final parts = command.split(RegExp('to\\s+|with\\s+'));
    if (parts.length < 2) {
      result['title'] =
          command.replaceFirst(RegExp('^update\\s+', caseSensitive: false), '');
      return;
    }

    // Extract task name to update
    String taskName = parts[0];
    taskName = taskName
        .replaceFirst(RegExp('^update\\s+', caseSensitive: false), '')
        .replaceFirst(RegExp('task\\s+', caseSensitive: false), '')
        .trim();

    result['title'] = taskName;

    // Extract what to update
    String updateText = parts[1].trim();

    // Check if it's a due date update
    final dateInfo = _extractDateFromText(updateText);
    if (dateInfo['date'] != null) {
      result['dueDate'] = dateInfo['date'];
    }

    // Otherwise, treat it as a description update
    else {
      result['description'] = updateText;
    }
  }

  // Parse reminder commands
  static void _parseRemindCommand(String command, Map<String, dynamic> result) {
    result['action'] = 'add'; // Convert remind to add action

    String taskText = command
        .replaceFirst(
            RegExp('^remind\\s+me\\s+to\\s+', caseSensitive: false), '')
        .trim();

    // Extract date
    final dateInfo = _extractDateFromText(taskText);
    if (dateInfo['date'] != null) {
      result['dueDate'] = dateInfo['date'];
      taskText = dateInfo['text']; // Updated text with date removed
    }

    result['title'] = taskText;
    result['priority'] = 1; // Reminders are treated as high priority
  }

  // Extract date mentions from text
  static Map<String, dynamic> _extractDateFromText(String text) {
    final result = {'date': null, 'text': text};
    final now = DateTime.now();

    // Check for "today", "tomorrow", "next week", etc.
    if (text.contains(' today')) {
      result['date'] = DateTime(now.year, now.month, now.day).toIso8601String();
      result['text'] =
          text.replaceFirst(RegExp('\\s+today', caseSensitive: false), '');
    } else if (text.contains(' tomorrow')) {
      result['date'] = DateTime(now.year, now.month, now.day + 1).toIso8601String();
      result['text'] =
          text.replaceFirst(RegExp('\\s+tomorrow', caseSensitive: false), '');
    } else if (text.contains(' next week')) {
      result['date'] = DateTime(now.year, now.month, now.day + 7).toIso8601String();
      result['text'] =
          text.replaceFirst(RegExp('\\s+next week', caseSensitive: false), '');
    } else if (text.contains(' next month')) {
      result['date'] = DateTime(now.year, now.month + 1, now.day).toIso8601String();
      result['text'] =
          text.replaceFirst(RegExp('\\s+next month', caseSensitive: false), '');
    }

    // Check for day names (Monday, Tuesday, etc.)
    final weekdays = {
      'monday': 1,
      'tuesday': 2,
      'wednesday': 3,
      'thursday': 4,
      'friday': 5,
      'saturday': 6,
      'sunday': 7
    };

    for (final entry in weekdays.entries) {
      final pattern = RegExp('\\s+on\\s+${entry.key}|\\s+${entry.key}',
          caseSensitive: false);
      if (text.contains(pattern)) {
        // Calculate next occurrence of this weekday
        final dayOfWeek = entry.value;
        int daysToAdd = dayOfWeek - now.weekday;
        if (daysToAdd <= 0)
          daysToAdd += 7; // If today or already passed this week

        result['date'] = DateTime(now.year, now.month, now.day + daysToAdd).toIso8601String();
        result['text'] = text.replaceFirst(pattern, '');
        break;
      }
    }

    // Check for "on May 15", "on August 3rd", etc.
    final monthPattern = RegExp(
        '\\s+on\\s+(?:January|February|March|April|May|June|July|August|September|October|November|December)\\s+\\d+(?:st|nd|rd|th)?',
        caseSensitive: false);

    final monthMatch = monthPattern.firstMatch(text);
    if (monthMatch != null) {
      try {
        final dateText = monthMatch
            .group(0)!
            .replaceFirst(RegExp('\\s+on\\s+', caseSensitive: false), '')
            .replaceAll(RegExp('(?:st|nd|rd|th)'), '');

        // Add current year if not specified
        final dateWithYear = '$dateText, ${now.year}';
        final date = DateFormat('MMMM d, y').parse(dateWithYear);

        // If the date has already passed this year, assume next year
        if (date.isBefore(now)) {
          result['date'] = DateTime(now.year + 1, date.month, date.day).toIso8601String();
        } else {
          result['date'] = date.toIso8601String();
        }

        result['text'] = text.replaceFirst(monthPattern, '');
      } catch (e) {
        // If parsing fails, ignore this attempt
        print('Error parsing date: $e');
      }
    }

    return result;
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
