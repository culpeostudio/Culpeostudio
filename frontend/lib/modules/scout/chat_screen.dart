import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import '../../core/app_state.dart';
import './chat_workspace.dart';

export './scout_tab.dart';
export './model_management_dialog.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppState();
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(appState.chatTextScale),
          ),
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerSignal: (pointerSignal) {
              if (pointerSignal is PointerScrollEvent) {
                final hk = HardwareKeyboard.instance;
                final isShift =
                    hk.isShiftPressed ||
                    hk.logicalKeysPressed.contains(
                      LogicalKeyboardKey.shiftLeft,
                    ) ||
                    hk.logicalKeysPressed.contains(
                      LogicalKeyboardKey.shiftRight,
                    );
                if (isShift) {
                  if (pointerSignal.scrollDelta.dy < 0) {
                    appState.increaseChatScale();
                  } else if (pointerSignal.scrollDelta.dy > 0) {
                    appState.decreaseChatScale();
                  }
                }
              }
            },
            child: const Scaffold(
              backgroundColor: Colors.transparent,
              body: ChatWorkspace(),
            ),
          ),
        );
      },
    );
  }
}
