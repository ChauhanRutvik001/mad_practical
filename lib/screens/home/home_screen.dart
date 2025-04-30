import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../providers/task_provider.dart';
import '../../models/task.dart';
import '../../services/speech_service.dart';
import '../../utils/nlp_parser.dart';
import '../../widgets/task_tile.dart';
import '../../widgets/voice_input_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SpeechService _speechService = SpeechService();
  String _statusMessage = '';
  bool _showCompleted = false;
  
  @override
  void initState() {
    super.initState();
    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    await _speechService.initialize();
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Start listening for voice commands
  void _startListening(BuildContext context) async {
    setState(() {
      _statusMessage = 'Listening...';
    });

    await _speechService.startListening((recognizedWords) async {
      if (recognizedWords.isNotEmpty) {
        setState(() {
          _statusMessage = 'Processing: "$recognizedWords"';
        });
        
        // Parse the voice command
        final parsedCommand = NLPParser.parseVoiceCommand(recognizedWords);
        
        // Process the command using TaskProvider
        final taskProvider = Provider.of<TaskProvider>(context, listen: false);
        final success = await taskProvider.processVoiceCommand(parsedCommand);
        
        // Provide feedback
        if (success) {
          _provideFeedback('Command processed successfully');
        } else {
          _provideFeedback('Sorry, I couldn\'t process that command');
        }
      } else {
        _provideFeedback('Sorry, I didn\'t catch that');
      }
    });
  }
  
  // Provide audio and text feedback
  void _provideFeedback(String message) {
    setState(() {
      _statusMessage = message;
    });
    
    // Provide audio feedback
    _speechService.speak(message);
    
    // Clear status message after a delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _statusMessage = '';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice To-Do List'),
        actions: [
          IconButton(
            icon: Icon(_showCompleted ? Icons.check_box : Icons.check_box_outline_blank),
            onPressed: () {
              setState(() {
                _showCompleted = !_showCompleted;
              });
            },
            tooltip: _showCompleted ? 'Hide completed' : 'Show completed',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final taskProvider = Provider.of<TaskProvider>(context, listen: false);
              taskProvider.loadTasks();
            },
            tooltip: 'Refresh tasks',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status message display
          if (_statusMessage.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.green.shade100,
              width: double.infinity,
              child: Text(
                _statusMessage,
                style: TextStyle(color: Colors.green.shade800),
                textAlign: TextAlign.center,
              ),
            ),
          
          // Task list with provider
          Expanded(
            child: Consumer<TaskProvider>(
              builder: (context, taskProvider, child) {
                if (taskProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (taskProvider.error != null) {
                  return Center(
                    child: Text(
                      'Error: ${taskProvider.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                
                final tasks = _showCompleted
                    ? taskProvider.tasks
                    : taskProvider.tasks.where((task) => !task.isCompleted).toList();
                
                if (tasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'No tasks yet',
                          style: TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Tap the microphone button to add a task',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _provideFeedback(
                              "Try saying: 'Add a task to buy groceries tomorrow'"),
                          icon: const Icon(Icons.help_outline),
                          label: const Text('See Example Commands'),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
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
      floatingActionButton: VoiceInputButton(
        onPressed: () => _startListening(context),
        isListening: _speechService.isListening,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
