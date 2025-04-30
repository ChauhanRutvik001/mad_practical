import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../services/speech_service.dart';
import '../../utils/nlp_parser.dart';
import '../../utils/constants.dart';
import '../../widgets/task_tile.dart';
import '../../widgets/voice_input_button.dart';
import '../../screens/auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final SpeechService _speechService = SpeechService();
  bool _isListening = false;
  String _processingMessage = '';
  bool _isProcessing = false;
  bool _showCommandHelp = false;

  // Animation controller for feedback message
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _initializeSpeechService();

    _animationController = AnimationController(
      duration: AppConstants.mediumAnimationDuration,
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _speechService.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeSpeechService() async {
    await _speechService.initialize();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      setState(() {
        _isListening = false;
      });
      await _speechService.stopListening();
    } else {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);

      final success = await _speechService.startListening((result) {
        _processVoiceCommand(result, taskProvider);
      });

      setState(() {
        _isListening = success;
      });

      if (!success) {
        _provideFeedback(
            "I couldn't start listening. Please check microphone permissions.");
      }
    }
  }

  Future<void> _processVoiceCommand(
      String command, TaskProvider taskProvider) async {
    if (command.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _processingMessage = 'Processing: "$command"';
    });

    // Stop listening while processing
    await _speechService.stopListening();
    setState(() {
      _isListening = false;
    });

    // Parse the command
    final commandData = NLPParser.parseVoiceCommand(command);
    print('Parsed command: $commandData');

    // Process the command and provide feedback
    await taskProvider.processVoiceCommand(commandData);

    // Determine appropriate feedback
    String feedbackMessage;
    switch (commandData['action']) {
      case 'add':
        feedbackMessage = 'Task added: ${commandData['title']}';
        break;
      case 'complete':
        feedbackMessage = 'Task completed: ${commandData['title']}';
        break;
      case 'delete':
        feedbackMessage = 'Task deleted: ${commandData['title']}';
        break;
      case 'list':
        feedbackMessage = 'Here are your tasks';
        break;
      case 'update':
        feedbackMessage = 'Task updated: ${commandData['title']}';
        break;
      default:
        feedbackMessage = 'Command processed';
    }

    // Provide feedback with a slight delay to feel more natural
    await Future.delayed(const Duration(milliseconds: 300));
    _provideFeedback(feedbackMessage);

    setState(() {
      _isProcessing = false;
      _processingMessage = '';
    });
  }

  void _provideFeedback(String message) {
    // Visual feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 70),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: AppConstants.primaryColor,
      ),
    );

    // Audio feedback using TTS
    _speechService.speak(message);
  }

  void _showHelpDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Voice Command Examples',
                style: AppConstants.headingStyle.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final command in AppConstants.voiceCommandExamples)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          leading: const Icon(Icons.mic,
                              color: AppConstants.primaryColor),
                          title: Text(command),
                          onTap: () {
                            Navigator.pop(context);
                            final taskProvider = Provider.of<TaskProvider>(
                                context,
                                listen: false);
                            _processVoiceCommand(command, taskProvider);
                          },
                          trailing: const Icon(Icons.play_arrow),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _logout() async {
    // Show a confirmation dialog
    final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('LOGOUT'),
              ),
            ],
          ),
        ) ??
        false;

    if (shouldLogout) {
      // Clean up any user-specific data
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      await taskProvider.clearAllTasks();

      // Show feedback
      _provideFeedback('Logging out...');

      // Navigate to login screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Voice To-Do List',
          style: AppConstants.subheadingStyle,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final taskProvider =
                  Provider.of<TaskProvider>(context, listen: false);
              taskProvider.refreshTasks();
              _provideFeedback('Tasks refreshed');
            },
            tooltip: 'Refresh tasks',
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
            tooltip: 'Show help',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Connection status indicator
              Consumer<TaskProvider>(
                builder: (context, taskProvider, child) {
                  final isOnline = taskProvider.isOnline;
                  final isSyncing = taskProvider.isSyncing;

                  return AnimatedContainer(
                    duration: AppConstants.shortAnimationDuration,
                    height: 30,
                    color: isOnline ? AppConstants.successColor : Colors.grey,
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isOnline ? Icons.cloud_done : Icons.cloud_off,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isOnline
                                ? isSyncing
                                    ? 'Syncing...'
                                    : 'Connected - All changes will sync'
                                : 'Offline - Changes saved locally',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Processing indicator
              AnimatedContainer(
                duration: AppConstants.shortAnimationDuration,
                height: _isProcessing ? 40 : 0,
                color: AppConstants.warningColor.withOpacity(0.2),
                child: _isProcessing
                    ? Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppConstants.warningColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _processingMessage,
                                style: TextStyle(
                                  color: AppConstants.warningColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )
                    : null,
              ),

              // Task list
              Expanded(
                child: Consumer<TaskProvider>(
                  builder: (context, taskProvider, child) {
                    final tasks = taskProvider.tasks;

                    if (tasks.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Replace the missing image with an icon
                            const Icon(Icons.checklist,
                                size: 100, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              'No tasks yet',
                              style: AppConstants.subheadingStyle,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Tap the microphone button to add a task',
                              style:
                                  TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _showHelpDialog,
                              icon: const Icon(Icons.help_outline),
                              label: const Text('See Example Commands'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstants.primaryColor,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return TaskTile(
                          task: task,
                          onToggleComplete: () {
                            taskProvider.toggleTaskCompletion(task);
                          },
                          onDelete: () {
                            taskProvider.deleteTask(task.id);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          // Processing animation overlay
          if (_isProcessing)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.black.withOpacity(0.1),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Processing...',
                            style: AppConstants.bodyStyle
                                .copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: VoiceInputButton(
        onPressed: _toggleListening,
        isListening: _isListening,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
