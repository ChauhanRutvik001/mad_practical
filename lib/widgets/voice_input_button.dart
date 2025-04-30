import 'package:flutter/material.dart';
import '../utils/constants.dart';

class VoiceInputButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isListening;

  const VoiceInputButton({
    super.key,
    required this.onPressed,
    required this.isListening,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: AppConstants.mediumAnimationDuration,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.2), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 1.0), weight: 1),
    ]).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        if (widget.isListening) {
          _animationController.forward();
        }
      }
    });
  }

  @override
  void didUpdateWidget(VoiceInputButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !oldWidget.isListening) {
      _animationController.forward();
    } else if (!widget.isListening && oldWidget.isListening) {
      _animationController.stop();
      _animationController.reset();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isListening ? _pulseAnimation.value : 1.0,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ripple effect when listening
              if (widget.isListening)
                AnimatedContainer(
                  duration: AppConstants.shortAnimationDuration,
                  width: 85,
                  height: 85,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                ),
              
              // Main button
              FloatingActionButton.extended(
                heroTag: 'voiceButton',
                onPressed: widget.onPressed,
                backgroundColor: widget.isListening 
                  ? AppConstants.errorColor 
                  : AppConstants.primaryColor,
                elevation: widget.isListening ? 8 : 4,
                icon: AnimatedSwitcher(
                  duration: AppConstants.shortAnimationDuration,
                  child: widget.isListening
                    ? const Icon(
                        Icons.mic,
                        key: ValueKey('listening'),
                        color: Colors.white,
                      )
                    : const Icon(
                        Icons.mic_none,
                        key: ValueKey('not_listening'),
                        color: Colors.white,
                      ),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: child,
                    );
                  },
                ),
                label: AnimatedSwitcher(
                  duration: AppConstants.shortAnimationDuration,
                  child: Text(
                    widget.isListening ? 'Listening...' : 'Voice Command',
                    key: ValueKey(widget.isListening ? 'listening_text' : 'command_text'),
                    style: const TextStyle(color: Colors.white),
                  ),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.2, 0.0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
