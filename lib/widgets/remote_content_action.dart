import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Short OK opens the item; hold OK or press Menu to toggle its favorite.
/// Nested buttons keep their own keyboard actions.
class RemoteContentAction extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onToggleFavorite;
  final ValueChanged<bool>? onFocusChange;

  const RemoteContentAction({
    super.key,
    required this.child,
    required this.onTap,
    this.onToggleFavorite,
    this.onFocusChange,
  });

  @override
  State<RemoteContentAction> createState() => _RemoteContentActionState();
}

class _RemoteContentActionState extends State<RemoteContentAction> {
  final _focus = FocusNode();
  Timer? _hold;
  LogicalKeyboardKey? _pressed;
  bool _longPress = false;

  void _cancel() {
    _hold?.cancel();
    _pressed = null;
    _longPress = false;
  }

  @override
  void dispose() {
    _cancel();
    _focus.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!_focus.hasPrimaryFocus || widget.onToggleFavorite == null) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.contextMenu ||
        key == LogicalKeyboardKey.keyF) {
      if (event is KeyDownEvent) widget.onToggleFavorite!();
      return KeyEventResult.handled;
    }
    if (key != LogicalKeyboardKey.select &&
        key != LogicalKeyboardKey.enter &&
        key != LogicalKeyboardKey.space &&
        key != LogicalKeyboardKey.gameButtonA) {
      return KeyEventResult.ignored;
    }
    if (event is KeyDownEvent && _pressed == null) {
      _pressed = key;
      _longPress = false;
      _hold = Timer(const Duration(milliseconds: 650), () {
        if (mounted && _focus.hasPrimaryFocus) {
          _longPress = true;
          widget.onToggleFavorite?.call();
        }
      });
    } else if (event is KeyUpEvent && _pressed == key) {
      final open = !_longPress;
      _cancel();
      if (open) widget.onTap();
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    onKeyEvent: _onKey,
    child: InkWell(
      focusNode: _focus,
      onTap: widget.onTap,
      onLongPress: widget.onToggleFavorite,
      onFocusChange: (focused) {
        if (!focused) _cancel();
        widget.onFocusChange?.call(focused);
      },
      child: widget.child,
    ),
  );
}
