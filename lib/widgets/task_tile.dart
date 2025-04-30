import 'package:flutter/material.dart';
import '../models/task.dart';
import '../utils/constants.dart';
import 'package:intl/intl.dart';

class TaskTile extends StatefulWidget {
  final Task task;
  final VoidCallback onToggleComplete;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const TaskTile({
    super.key,
    required this.task,
    required this.onToggleComplete,
    required this.onDelete,
    this.onTap,
  });

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppConstants.shortAnimationDuration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    
    if (widget.task.isCompleted) {
      _controller.value = 1.0;
    }
  }
  
  @override
  void didUpdateWidget(TaskTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.task.isCompleted != oldWidget.task.isCompleted) {
      if (widget.task.isCompleted) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Different colors based on priority
    final Color priorityColor = AppConstants.getPriorityColor(widget.task.priority);
    final Color textColor = AppConstants.getPriorityTextColor(widget.task.priority);
    
    return AnimatedOpacity(
      opacity: widget.task.isCompleted ? 0.7 : 1.0,
      duration: AppConstants.shortAnimationDuration,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: widget.task.isCompleted ? 1 : 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: priorityColor,
            width: 1.5,
          ),
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Checkbox for completion status
                    InkWell(
                      onTap: widget.onToggleComplete,
                      borderRadius: BorderRadius.circular(15),
                      child: AnimatedContainer(
                        duration: AppConstants.shortAnimationDuration,
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.task.isCompleted ? AppConstants.successColor : Colors.transparent,
                          border: Border.all(
                            width: 2,
                            color: widget.task.isCompleted ? AppConstants.successColor : Colors.grey,
                          ),
                        ),
                        child: Center(
                          child: AnimatedOpacity(
                            opacity: widget.task.isCompleted ? 1.0 : 0.0,
                            duration: AppConstants.shortAnimationDuration,
                            child: const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Task title and details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedDefaultTextStyle(
                            style: widget.task.isCompleted
                                ? AppConstants.bodyStyle.copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey,
                                  )
                                : AppConstants.bodyStyle.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            duration: AppConstants.shortAnimationDuration,
                            child: Text(widget.task.title),
                          ),
                          if (widget.task.description.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: AnimatedDefaultTextStyle(
                                style: widget.task.isCompleted
                                    ? AppConstants.captionStyle.copyWith(
                                        decoration: TextDecoration.lineThrough,
                                        color: Colors.grey,
                                      )
                                    : AppConstants.captionStyle,
                                duration: AppConstants.shortAnimationDuration,
                                child: Text(widget.task.description),
                              ),
                            ),
                            
                          const SizedBox(height: 8),
                          
                          // Due date and sync status
                          Row(
                            children: [
                              if (widget.task.dueDate != null) ...[
                                Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: _isOverdue() ? AppConstants.errorColor : Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat('MMM d, yyyy').format(widget.task.dueDate!),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _isOverdue() ? AppConstants.errorColor : Colors.grey[600],
                                    fontWeight: _isOverdue() ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              
                              // Sync status indicator
                              Icon(
                                widget.task.isSynced ? Icons.cloud_done : Icons.cloud_off,
                                size: 14,
                                color: widget.task.isSynced ? AppConstants.successColor : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.task.isSynced ? 'Synced' : 'Local only',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: widget.task.isSynced ? AppConstants.successColor : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Priority indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: priorityColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        AppConstants.priorityLabels[widget.task.priority] ?? 'Medium',
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Delete button with ripple effect
                    Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: Colors.grey.shade600,
                        splashRadius: 24,
                        onPressed: () {
                          // Add confirmation dialog
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Task'),
                              content: const Text('Are you sure you want to delete this task?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('CANCEL'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    widget.onDelete();
                                  },
                                  child: const Text('DELETE', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                        tooltip: 'Delete task',
                      ),
                    ),
                  ],
                ),
                
                // Show voice command source if available
                if (widget.task.voiceCommandSource != null && widget.task.voiceCommandSource!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 36, top: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.mic,
                          size: 14,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Created by voice: "${widget.task.voiceCommandSource}"',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[400],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  bool _isOverdue() {
    if (widget.task.dueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(
      widget.task.dueDate!.year,
      widget.task.dueDate!.month,
      widget.task.dueDate!.day,
    );
    return dueDate.isBefore(today) && !widget.task.isCompleted;
  }
}
