import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

enum VoiceButtonState {
  idle,
  requestingPermission,
  listening,
}

class VoiceInputButton extends StatefulWidget {
  final VoidCallback onPressed;
  final VoiceButtonState buttonState;
  final String? listeningMessage;
  final String? recognizedText;

  const VoiceInputButton({
    Key? key,
    required this.onPressed,
    this.buttonState = VoiceButtonState.idle,
    this.listeningMessage,
    this.recognizedText,
  }) : super(key: key);

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  bool _showTooltip = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppConstants.mediumAnimationDuration,
      vsync: this,
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
        if (widget.buttonState == VoiceButtonState.listening) {
          _animationController.forward();
        }
      }
    });

    // Auto-hide tooltip after 4 seconds on first render
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _showTooltip = true;
        });

        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) {
            setState(() {
              _showTooltip = false;
            });
          }
        });
      }
    });
  }

  @override
  void didUpdateWidget(VoiceInputButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.buttonState == VoiceButtonState.listening &&
        oldWidget.buttonState != VoiceButtonState.listening) {
      _animationController.forward();
    } else if (widget.buttonState != VoiceButtonState.listening &&
        oldWidget.buttonState == VoiceButtonState.listening) {
      _animationController.stop();
      _animationController.reset();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getButtonColor() {
    switch (widget.buttonState) {
      case VoiceButtonState.requestingPermission:
        return Colors.orange;
      case VoiceButtonState.listening:
        return AppConstants.errorColor;
      case VoiceButtonState.idle:
      default:
        return AppConstants.primaryColor;
    }
  }

  Widget _getButtonIcon() {
    switch (widget.buttonState) {
      case VoiceButtonState.requestingPermission:
        return const Icon(
          Icons.mic_off,
          key: ValueKey('requesting_permission'),
          color: Colors.white,
        );
      case VoiceButtonState.listening:
        return const Icon(
          Icons.mic,
          key: ValueKey('listening'),
          color: Colors.white,
        );
      case VoiceButtonState.idle:
      default:
        return const Icon(
          Icons.mic_none,
          key: ValueKey('not_listening'),
          color: Colors.white,
        );
    }
  }

  String _getButtonText() {
    switch (widget.buttonState) {
      case VoiceButtonState.requestingPermission:
        return 'Requesting permission...';
      case VoiceButtonState.listening:
        return widget.listeningMessage ?? 'Listening...';
      case VoiceButtonState.idle:
      default:
        return 'Voice Command';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Tooltip that appears briefly on first load
        if (_showTooltip)
          Positioned(
            bottom: 100,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "Tap to use voice commands",
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),

        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: widget.buttonState == VoiceButtonState.listening
                  ? _pulseAnimation.value
                  : 1.0,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Ripple effect when listening
                  if (widget.buttonState == VoiceButtonState.listening)
                    AnimatedContainer(
                      duration: AppConstants.shortAnimationDuration,
                      width: 85,
                      height: 85,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                    ),

                  // Secondary ripple for better visual cue
                  if (widget.buttonState == VoiceButtonState.listening)
                    AnimatedContainer(
                      duration: AppConstants.shortAnimationDuration,
                      width: 95,
                      height: 95,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),

                  // Permission indicator
                  if (widget.buttonState ==
                      VoiceButtonState.requestingPermission)
                    AnimatedContainer(
                      duration: AppConstants.shortAnimationDuration,
                      width: 85,
                      height: 85,
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                    ),

                  // Main button
                  FloatingActionButton.extended(
                    heroTag: 'voiceButton',
                    onPressed: widget.onPressed,
                    backgroundColor: _getButtonColor(),
                    elevation:
                        widget.buttonState == VoiceButtonState.idle ? 4 : 8,
                    icon: AnimatedSwitcher(
                      duration: AppConstants.shortAnimationDuration,
                      child: _getButtonIcon(),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                        return ScaleTransition(
                          scale: animation,
                          child: child,
                        );
                      },
                    ),
                    label: AnimatedSwitcher(
                      duration: AppConstants.shortAnimationDuration,
                      child: Text(
                        _getButtonText(),
                        key: ValueKey(_getButtonText()),
                        style: const TextStyle(color: Colors.white),
                      ),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
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
        ),
      ],
    );
  }
}
