import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppConstants {
  // Colors
  static const primaryColor = Color(0xFF4A67FF);
  static const secondaryColor = Color(0xFF7D8FFF);
  static const accentColor = Color(0xFFFF7D7D);
  static const backgroundColor = Color(0xFFF5F7FF);
  static const textColor = Color(0xFF2E3A59);
  static const successColor = Color(0xFF4CAF50);
  static const warningColor = Color(0xFFFFA000);
  static const errorColor = Color(0xFFE53935);

  // Animation durations
  static const shortAnimationDuration = Duration(milliseconds: 250);
  static const mediumAnimationDuration = Duration(milliseconds: 500);
  static const longAnimationDuration = Duration(milliseconds: 800);

  // Text styles
  static final headingStyle = GoogleFonts.nunito(
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: textColor,
  );

  static final subheadingStyle = GoogleFonts.nunito(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textColor,
  );

  static final bodyStyle = GoogleFonts.nunito(
    fontSize: 16,
    color: textColor,
  );

  static final captionStyle = GoogleFonts.nunito(
    fontSize: 14,
    color: Colors.grey[600],
  );

  static final smallTextStyle = GoogleFonts.nunito(
    fontSize: 14,
    color: Colors.grey[600],
  );

  // UI constants
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 12.0;
  static const double defaultElevation = 2.0;

  // Priority colors
  static const highPriorityColor = Color(0xFFFF5252);
  static const mediumPriorityColor = Color(0xFFFFB142);
  static const lowPriorityColor = Color(0xFF66BB6A);

  // Priority labels
  static const Map<int, String> priorityLabels = {
    1: 'High',
    2: 'Medium',
    3: 'Low',
  };

  // Priority color helpers
  static Color getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return highPriorityColor.withOpacity(0.2);
      case 2:
        return mediumPriorityColor.withOpacity(0.2);
      case 3:
        return lowPriorityColor.withOpacity(0.2);
      default:
        return Colors.grey.shade100;
    }
  }

  static Color getPriorityTextColor(int priority) {
    switch (priority) {
      case 1:
        return highPriorityColor;
      case 2:
        return mediumPriorityColor;
      case 3:
        return lowPriorityColor;
      default:
        return Colors.grey.shade700;
    }
  }

  // Voice command examples
  static const List<String> voiceCommandExamples = [
    "Add a task to buy groceries tomorrow",
    "Add high priority task to call mom",
    "Mark complete buy groceries",
    "Delete task call mom",
    "Show all tasks",
    "Add a task to finish project with description needs review by Friday",
    "Remind me to take medicine at 8pm",
    "Add a task to pay bills on Friday",
    "Complete task finish report",
    "Add low priority task to water plants"
  ];

  // Feedback messages
  static const Map<String, List<String>> feedbackMessages = {
    'success': [
      "Got it!",
      "Task saved!",
      "All done!",
      "Consider it done!",
      "I've taken care of that for you.",
      "That's been added to your list."
    ],
    'error': [
      "I'm not sure I understood that correctly.",
      "Could you try saying that again?",
      "I didn't quite catch that.",
      "Let's try again with different wording.",
      "I'm having trouble understanding. Could you rephrase that?"
    ],
    'waiting': [
      "I'm listening...",
      "Go ahead, I'm listening.",
      "What would you like to do?",
      "Speak now, I'm ready."
    ]
  };
}
