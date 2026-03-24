import 'package:flutter/material.dart';
import 'package:lakbyke_mobile/core/presentation/chatbot_theme.dart';
import 'package:lakbyke_mobile/core/presentation/widgets/chatbot/chatbot_bottom_sheet.dart';
import 'dart:async';
import 'package:flutter/scheduler.dart';

/// Floating Action Button for accessing the chatbot (Kleta).
/// Uses the LakByke chatbot avatar as the FAB icon.
class ChatFAB extends StatefulWidget {
  const ChatFAB({
    super.key,
    this.backgroundColor,
    this.foregroundColor,
  });

  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  State<ChatFAB> createState() => _ChatFABState();
}

class _ChatFABState extends State<ChatFAB> with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  late Offset _position;
  bool _inserted = false;
  bool _hasPosition = false;
  
  // NEW: Flag to track if the FAB should be temporarily hidden (like when the sheet is open)
  bool _isHidden = false;
  
  late AnimationController _animController;
  Animation<Offset>? _animation;

  // Constants for FAB size and margin to keep math clean
  final double _fabSize = 56.0;
  final double _fabMargin = 8.0;

  @override
  void initState() {
    super.initState();
    print('[ChatFAB Debug] Appears: initState called. Setting up animation controller.');
    
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _animController.addListener(() {
      _overlayEntry?.markNeedsBuild();
    });

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_animation != null) {
          _position = _animation!.value;
        }
        _animation = null;
        print('[ChatFAB Debug] Movement: Snap animation completed. Resting at: $_position');
        _overlayEntry?.markNeedsBuild();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!_inserted) {
        _inserted = true;
        _ensureOverlay(context);
      }
    });

    return const SizedBox.shrink();
  }

  void _ensureOverlay(BuildContext context) {
    final mq = MediaQuery.of(context);
    
    if (!_hasPosition) {
      // Dynamic initial placement: Bottom Right corner, respecting safe areas
      _position = Offset(
        mq.size.width - _fabSize - _fabMargin, 
        mq.size.height - mq.padding.bottom - _fabSize - (_fabMargin * 2) - 60 // 60px extra to clear bottom nav bars
      );
      _hasPosition = true;
      print('[ChatFAB Debug] Appears: Initial placement on screen at $_position');
    }

    _overlayEntry = OverlayEntry(builder: (context) {
      // NEW: If the bottom sheet is open, return an empty box to hide the FAB
      if (_isHidden) return const SizedBox.shrink();

      final displayPos = _animation?.value ?? _position;
      return Positioned(
        left: displayPos.dx,
        top: displayPos.dy,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onPanUpdate: (details) {
              final currentMq = MediaQuery.of(context);
              final safePadding = currentMq.padding;
              
              // NEW: Dynamic boundaries that adapt to ANY screen size/notch
              final double minX = _fabMargin;
              final double maxX = currentMq.size.width - _fabSize - _fabMargin;
              final double minY = safePadding.top + _fabMargin; // Respect top notch
              final double maxY = currentMq.size.height - safePadding.bottom - _fabSize - _fabMargin; // Respect bottom edge

              _position = Offset(
                (_position.dx + details.delta.dx).clamp(minX, maxX),
                (_position.dy + details.delta.dy).clamp(minY, maxY),
              );
              
              _hasPosition = true;
              
              if (_animController.isAnimating) {
                _animController.stop();
              }
              _animation = null;
              _overlayEntry?.markNeedsBuild();
            },
            onPanEnd: (_) {
              print('[ChatFAB Debug] Movement: Drag ended at $_position. Calculating snap...');
              _snapToNearest(context);
            },
            onTap: () => _openChat(context),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: () => _openChat(context),
                backgroundColor: widget.backgroundColor ?? Colors.teal,
                tooltip: 'Chat with our chatbot, Kleta',
                shape: const CircleBorder(),
                elevation: 0,
                child: ClipOval(
                  child: Image.asset(
                    ChatbotTheme.botProfileAsset,
                    fit: BoxFit.cover,
                    width: 56,
                    height: 56,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.chat_bubble,
                      color: widget.foregroundColor ?? Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });

    Overlay.of(context, rootOverlay: true)?.insert(_overlayEntry!);
  }

  Future<void> _openChat(BuildContext context) async {
    print('[ChatFAB Debug] Appears: Opening Bottom Sheet.');

    // 1. Hide the FAB instantly
    _isHidden = true;
    _overlayEntry?.markNeedsBuild();

    // 2. Wait for the user to close the bottom sheet
    await ChatbotBottomSheet.show(context);

    print('[ChatFAB Debug] Appears: Bottom Sheet dismissed.');
    
    // 3. Show the FAB again instantly
    _isHidden = false;
    _overlayEntry?.markNeedsBuild();

    if (_overlayEntry == null && mounted) {
      _inserted = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) _ensureOverlay(context);
      });
    }
  }

  void _snapToNearest(BuildContext context) {
    final mq = MediaQuery.of(context);
    final double w = mq.size.width;
    final double h = mq.size.height;
    final safePadding = mq.padding; // Grabs safe areas (notches, system nav)

    // NEW: Fully responsive snap points
    final double leftX = _fabMargin;
    final double rightX = w - _fabSize - _fabMargin;
    
    // Y-Axis respects the phone's physical hardware cutouts
    final double topY = safePadding.top > 0 ? safePadding.top + _fabMargin : _fabMargin + 75; 
    final double bottomY = h - safePadding.bottom - _fabSize - _fabMargin - 75; // Extra 75px clears bottom app bars
    final double centerY = (h / 2) - (_fabSize / 2);

    final candidates = <Offset>[
      Offset(leftX, topY),       // Top-Left
      Offset(rightX, topY),      // Top-Right
      Offset(leftX, bottomY),    // Bottom-Left
      Offset(rightX, bottomY),   // Bottom-Right
      Offset(leftX, centerY),    // Left-Center
      Offset(rightX, centerY),   // Right-Center
    ];

    Offset nearest = candidates.first;
    double best = double.infinity;
    for (final c in candidates) {
      final d = (c - _position).distance;
      if (d < best) {
        best = d;
        nearest = c;
      }
    }

    _animateTo(nearest);
  }

  void _animateTo(Offset target) {
    _animation = Tween<Offset>(begin: _position, end: target).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));
    
    _animController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry?.dispose(); 
    _overlayEntry = null;
    
    _animController.dispose();
    super.dispose();
  }
}