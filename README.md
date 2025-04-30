# Voice-Driven To-Do List App

A Flutter-based prototype for a Voice-Driven To-Do List App that allows users to manage their tasks entirely through voice commands.

## Key Features

1. **Voice Command Parsing**:
   - On-device speech-to-text functionality with offline support
   - Natural language processing for understanding user commands

2. **Offline Queueing**:
   - Local storage of tasks and voice commands
   - Commands are synced when connectivity is restored

3. **Real-Time Sync**:
   - Firebase integration for cross-device task synchronization
   - Conflict resolution for simultaneous updates

4. **User Feedback**:
   - Text-to-speech (TTS) responses and confirmations
   - Visual and audio cues for better interaction

5. **Data Persistence**:
   - Robust offline-first architecture
   - State management using Provider

## Getting Started

### Prerequisites

- Flutter SDK (>= 3.0.0)
- Firebase account
- Android/iOS device or emulator with microphone access

### Installation

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Configure your Firebase project:
   - Add `google-services.json` (for Android) and/or `GoogleService-Info.plist` (for iOS)
4. Run the app: `flutter run`

## Usage

- **Adding tasks**: Say "Add a task to [your task]"
- **Completing tasks**: Say "Complete task [task name]"
- **Deleting tasks**: Say "Delete task [task name]"
- **Listing tasks**: Say "Show my tasks" or "List all tasks"

## Project Structure

```
lib/
├── main.dart                # Entry point
├── models/                  # Data models
├── screens/                 # UI screens
├── services/                # Business logic
├── providers/               # State management
├── utils/                   # Utility functions
├── widgets/                 # Reusable components
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.