import 'package:flutter/material.dart';

class AppConstants {
  // App-wide theme colors
  static const Color primaryColor = Color(0xFF4CAF50);
  static const Color accentColor = Color(0xFF8BC34A);
  static const Color errorColor = Color(0xFFE53935);
  static const Color warningColor = Color(0xFFFFB74D);
  static const Color successColor = Color(0xFF66BB6A);
  
  // Text styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );
  
  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  );
  
  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    color: Colors.black87,
  );
  
  static const TextStyle captionStyle = TextStyle(
    fontSize: 14,
    color: Colors.black54,
  );
  
  // Task priorities
  static const Map<int, String> priorityLabels = {
    1: 'High',
    2: 'Medium',
    3: 'Low',
  };
  
  static Color getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return Colors.red.shade100;
      case 2:
        return Colors.amber.shade100;
      case 3:
        return Colors.green.shade100;
      default:
        return Colors.grey.shade100;
    }
  }
  
  static Color getPriorityTextColor(int priority) {
    switch (priority) {
      case 1:
        return Colors.red.shade900;
      case 2:
        return Colors.amber.shade900;
      case 3:
        return Colors.green.shade900;
      default:
        return Colors.grey.shade900;
    }
  }
  
  // Animation durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 300);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 500);
  static const Duration longAnimationDuration = Duration(milliseconds: 800);
  
  // Voice command examples
  static const List<String> voiceCommandExamples = [
    "Add a task to buy groceries",
    "Complete task buy milk",
    "Delete task send email",
    "Show my tasks",
    "Add a high priority task to call mom tomorrow",
  ];
  
  // Feedback messages
  static const Map<String, List<String>> feedbackMessages = {
    'success': [
      "Task added successfully!",
      "Task completed!",
      "Task deleted.",
      "Task updated successfully!"
    ],
    'error': [
      "I couldn't understand that command.",
      "Could you try again?",
      "I didn't catch that. Please try again.",
      "There was an error processing your command."
    ],
    'clarification': [
      "Did you mean to add a task?",
      "Did you want to mark a task as complete?",
      "Did you want to delete a task?",
      "Could you be more specific?"
    ],
  };
}