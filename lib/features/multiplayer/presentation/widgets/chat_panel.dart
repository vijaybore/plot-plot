import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/multiplayer_service.dart';
import '../../domain/models/chat_message_model.dart';
import '../providers/multiplayer_provider.dart';

/// Small floating chat bubble button — tap to open the room chat sheet.
/// Only rendered when the current match is online (see game_screen.dart).
class ChatFab extends ConsumerWidget {
  final String localPlayerId;
  final String localPlayerName;
  const ChatFab({super.key, required this.localPlayerId, required this.localPlayerName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ChatPanel(
          localPlayerId: localPlayerId,
          localPlayerName: localPlayerName,
        ),
      ),
      child: Container(
        width: 46, height: 46,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}

class ChatPanel extends ConsumerStatefulWidget {
  final String localPlayerId;
  final String localPlayerName;
  const ChatPanel({super.key, required this.localPlayerId, required this.localPlayerName});

  @override
  ConsumerState<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends ConsumerState<ChatPanel> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();
  bool _showEmoji = false;

  // Compact, commonly-used set — enough for casual game-chat reactions
  // without pulling in a full emoji-picker package/dependency.
  static const _emojis = [
    '😀', '😂', '😅', '😉', '😍', '🤔', '😎', '😭',
    '😡', '🥳', '😱', '🙄', '👍', '👎', '👏', '🙏',
    '💪', '🤝', '🔥', '💰', '🏠', '🎲', '🏆', '💯',
    '❤️', '💔', '⭐', '✅', '❌', '⏳', '🎉', '😴',
  ];

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _insertEmoji(String emoji) {
    final text = _textCtrl.text;
    final selection = _textCtrl.selection;
    final cursor = selection.start >= 0 ? selection.start : text.length;
    final newText = text.replaceRange(cursor, selection.end >= 0 ? selection.end : cursor, emoji);
    _textCtrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursor + emoji.length),
    );
  }

  void _toggleEmojiPicker() {
    setState(() => _showEmoji = !_showEmoji);
    if (_showEmoji) {
      // Emoji panel is taking over the keyboard's screen space —
      // dismiss the system keyboard so both don't fight for room.
      _focusNode.unfocus();
    } else {
      _focusNode.requestFocus();
    }
  }

  void _send() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    final room = ref.read(multiplayerRoomProvider);
    if (room.roomCode == null) return;
    MultiplayerService.instance.sendChatMessage(
      room.roomCode!,
      ChatMessageModel(
        senderId: widget.localPlayerId,
        senderName: widget.localPlayerName,
        text: text,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    _textCtrl.clear();
    // Scroll to bottom shortly after the new message streams in.
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatAsync = ref.watch(chatMessagesProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.appCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('Room Chat',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
            ),
            Expanded(
              child: chatAsync.when(
                data: (messages) => messages.isEmpty
                    ? const Center(child: Text('No messages yet — say hi 👋',
                        style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: messages.length,
                        itemBuilder: (_, i) {
                          final m = messages[i];
                          final mine = m.senderId == widget.localPlayerId;
                          return Align(
                            alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                              decoration: BoxDecoration(
                                color: mine ? AppColors.primary : AppColors.appSurface,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(mine ? 'You' : m.senderName,
                                      style: TextStyle(
                                          color: mine ? Colors.white70 : Colors.white60,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700)),
                                  Text(m.text, style: const TextStyle(color: Colors.white, fontSize: 13)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                    child: Text('Chat unavailable', style: TextStyle(color: Colors.red.shade200))),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(12, 8, 12, _showEmoji ? 8 : MediaQuery.of(context).viewInsets.bottom + 12),
              child: Row(
                children: [
                  // Toggle between the emoji grid and the system text keyboard —
                  // mirrors the standard chat-app pattern (WhatsApp/Telegram),
                  // so text and emoji both work through the same input bar.
                  GestureDetector(
                    onTap: _toggleEmojiPicker,
                    child: Container(
                      width: 42, height: 42,
                      decoration: const BoxDecoration(color: AppColors.appSurface, shape: BoxShape.circle),
                      child: Icon(
                        _showEmoji ? Icons.keyboard_rounded : Icons.emoji_emotions_outlined,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _textCtrl,
                      focusNode: _focusNode,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Message…',
                        filled: true,
                        fillColor: AppColors.appSurface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                      ),
                      onTap: () {
                        // Typing text should close the emoji grid and hand
                        // focus back to the system keyboard.
                        if (_showEmoji) setState(() => _showEmoji = false);
                      },
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      width: 42, height: 42,
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            // Expandable emoji grid — replaces the system keyboard's screen
            // space when open, so the sheet doesn't grow taller than the
            // keyboard would have.
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              child: _showEmoji
                  ? SizedBox(
                      height: 220,
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 8,
                        ),
                        itemCount: _emojis.length,
                        itemBuilder: (_, i) => GestureDetector(
                          onTap: () => _insertEmoji(_emojis[i]),
                          child: Center(
                            child: Text(_emojis[i], style: const TextStyle(fontSize: 22)),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox(height: 0, width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}