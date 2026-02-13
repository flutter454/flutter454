import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatloop/feature/screens/chat/message_screen_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessageScreen extends StatefulWidget {
  final String chatId;
  final String friendId;
  final String friendName;
  final String friendPhoto;

  const MessageScreen({
    super.key,
    required this.chatId,
    required this.friendId,
    required this.friendName,
    required this.friendPhoto,
  });

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  late final String _currentUserId;
  late final AnimationController _animationController;
  double _dragOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser!.id;
    _animationController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 200),
          lowerBound: -100, // Allow dragging up to 100px left
          upperBound: 0,
          value: 0,
        )..addListener(() {
          setState(() {
            _dragOffset = _animationController.value;
          });
        });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    // Small delay to ensure list rendered
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Helper function to show options
  void _showMessageOptions(BuildContext context, Map<String, dynamic> msg) {
    // We pass context to access Provider
    final provider = Provider.of<MessageScreenProvider>(context, listen: false);
    final String currentUserId = provider.currentUserId;
    final bool isMe = msg['sender_id'] == currentUserId;
    final time = DateTime.parse(msg['created_at']).toLocal();
    final formattedTime = DateFormat('d MMM, h:mm a').format(time);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.pop(context),
          child: Align(
            alignment: Alignment.bottomRight,
            child: GestureDetector(
              onTap: () {}, // Prevent closing when tapping the menu itself
              child: Container(
                width: MediaQuery.of(context).size.width * 0.7,
                margin: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  right: 16,
                  top: kToolbarHeight + 40,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 1. Super React Section
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Column(
                              children: [
                                Text(
                                  'Tap and hold to super react',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildReactionEmoji('❤️'),
                                    _buildReactionEmoji('😂'),
                                    _buildReactionEmoji('😮'),
                                    _buildReactionEmoji('😢'),
                                    _buildReactionEmoji('😡'),
                                    _buildReactionEmoji('👍'),
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.grey[200],
                                      ),
                                      child: const Icon(
                                        Icons.add,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const Divider(height: 1),

                          // 2. Menu Options
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  formattedTime,
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _buildMenuOption(
                                  icon: Icons.reply,
                                  label: 'Reply',
                                  onTap: () {
                                    Navigator.pop(context);
                                    provider.setReplyTo(msg);
                                    _focusNode.requestFocus();
                                  },
                                ),
                                _buildMenuOption(
                                  icon: Icons.emoji_emotions_outlined,
                                  label: 'Add sticker',
                                  onTap: () => Navigator.pop(context),
                                ),
                                _buildMenuOption(
                                  icon: Icons.forward,
                                  label: 'Forward',
                                  onTap: () => Navigator.pop(context),
                                ),
                                _buildMenuOption(
                                  icon: Icons.copy,
                                  label: 'Copy',
                                  onTap: () async {
                                    final text = msg['text'] as String?;
                                    if (text != null && text.isNotEmpty) {
                                      await Clipboard.setData(
                                        ClipboardData(text: text),
                                      );
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Message copied to clipboard',
                                            ),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    } else {
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Cannot copy empty message',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                                _buildMenuOption(
                                  icon: Icons.image_outlined,
                                  label: 'Make AI image',
                                  onTap: () => Navigator.pop(context),
                                ),
                                if (isMe)
                                  _buildMenuOption(
                                    icon: Icons.undo,
                                    label: 'Unsend',
                                    textColor: Colors.red,
                                    iconColor: Colors.red,
                                    onTap: () {
                                      Navigator.pop(context);
                                      provider.unsendMessage(msg['id']);
                                    },
                                  ),
                                _buildMenuOption(
                                  label: 'More',
                                  onTap: () => Navigator.pop(context),
                                  isLast: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReactionEmoji(String emoji) {
    return Text(emoji, style: const TextStyle(fontSize: 28));
  }

  Widget _buildMenuOption({
    IconData? icon,
    required String label,
    required VoidCallback onTap,
    Color textColor = const Color(0xFF1F1F1F),
    Color iconColor = const Color(0xFF1F1F1F),
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 12.0,
        ), // increased vertical padding
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 22, color: iconColor),
              const SizedBox(width: 16),
            ] else
              const SizedBox(
                width: 38,
              ), // Indent for text-only items like "More"

            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: textColor,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _cleanUrl(String? url) {
    if (url == null || url.isEmpty) return 'https://i.pravatar.cc/150';
    if (url.contains(',')) {
      return url.split(',').first.trim();
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MessageScreenProvider()..init(widget.chatId),
      child: Consumer<MessageScreenProvider>(
        builder: (context, provider, child) {
          // Scroll to bottom on initial load completion
          if (!provider.isLoading && provider.messages.isNotEmpty) {
            // We only scroll if we haven't scrolled yet? Or rely on user?
            // Simple logic: If newly loaded, scroll.
            // But 'builder' runs on every update.
            // We can check if controller is attached and we are at the end?
            // Or just scroll on new message addition?
            // For now, let's keep it simple: the provider handles data.
            // We can use a post frame callback to scroll if needed,
            // but forcing scroll on every build is bad if user scrolled up.
            // We rely on the fact that when user sends message, we call _scrollToBottom
            // in the sendMessage method (if it was in widget).
            // Since sendMessage is now in provider, we need to trigger scroll from UI.
            // provider.sendMessage is async. We can await it.
          }

          return Scaffold(
            appBar: AppBar(
              title: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: CachedNetworkImageProvider(
                      _cleanUrl(widget.friendPhoto),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(widget.friendName),
                ],
              ),
            ),
            body: Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      // Only allow dragging left (negative values)
                      double newVal = _dragOffset + details.delta.dx;
                      newVal = newVal.clamp(-100.0, 0.0);
                      // setState to update local animation value
                      // We must use setState here because _dragOffset is local UI state for animation
                      setState(() {
                        _animationController.value = newVal;
                        _dragOffset = newVal;
                      });
                    },
                    onHorizontalDragEnd: (details) {
                      // Snap back to 0
                      _animationController.animateTo(
                        0,
                        curve: Curves.easeOut,
                        duration: const Duration(milliseconds: 200),
                      );
                      setState(() {
                        _dragOffset = 0;
                      });
                    },
                    child: Builder(
                      builder: (context) {
                        if (provider.isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (provider.error != null) {
                          return Center(
                            child: Text('Error: ${provider.error}'),
                          );
                        }
                        final allMessages = provider.messages;
                        if (allMessages.isEmpty) {
                          return const Center(
                            child: Text('No messages yet. Say hi! 👋'),
                          );
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          itemCount: allMessages.length,
                          itemBuilder: (context, index) {
                            final msg = allMessages[index];
                            final isMe =
                                msg['sender_id'] == provider.currentUserId;
                            final time = DateTime.parse(
                              msg['created_at'],
                            ).toLocal();
                            final isOptimistic = msg['is_optimistic'] == true;

                            // Grouping Logic
                            final nextMsg = (index + 1 < allMessages.length)
                                ? allMessages[index + 1]
                                : null;
                            final bool isLastInGroup =
                                !isMe &&
                                (nextMsg == null ||
                                    nextMsg['sender_id'] != msg['sender_id']);
                            final double marginBottom =
                                (nextMsg != null &&
                                    nextMsg['sender_id'] == msg['sender_id'])
                                ? 2
                                : 10;

                            return AnimatedBuilder(
                              animation: _animationController,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(_dragOffset, 0),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    alignment: Alignment.centerRight,
                                    children: [
                                      // The Timestamp (Hidden off-screen to the right)
                                      Positioned(
                                        right: -70,
                                        top: 0,
                                        bottom: 0,
                                        child: Center(
                                          child: SizedBox(
                                            width: 60,
                                            child: Text(
                                              DateFormat('h:mm a').format(time),
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // The Message Bubble
                                      Padding(
                                        padding: EdgeInsets.only(
                                          bottom: marginBottom,
                                        ),
                                        child: Row(
                                          mainAxisAlignment: isMe
                                              ? MainAxisAlignment.end
                                              : MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            if (!isMe) ...[
                                              const SizedBox(width: 8),
                                              if (isLastInGroup)
                                                CircleAvatar(
                                                  radius: 16,
                                                  backgroundImage:
                                                      CachedNetworkImageProvider(
                                                        _cleanUrl(
                                                          widget.friendPhoto,
                                                        ),
                                                      ),
                                                )
                                              else
                                                const SizedBox(width: 32),
                                              const SizedBox(width: 8),
                                            ],
                                            Flexible(
                                              child: GestureDetector(
                                                onLongPress: () {
                                                  _showMessageOptions(
                                                    context,
                                                    msg,
                                                  );
                                                },
                                                child: Container(
                                                  constraints: BoxConstraints(
                                                    maxWidth:
                                                        MediaQuery.of(
                                                          context,
                                                        ).size.width *
                                                        0.75,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 12,
                                                        horizontal: 16,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: isMe
                                                        ? const Color(
                                                            0xFF6200EE,
                                                          )
                                                        : Colors.grey[200],
                                                    borderRadius: BorderRadius.only(
                                                      topLeft:
                                                          const Radius.circular(
                                                            20,
                                                          ),
                                                      topRight:
                                                          const Radius.circular(
                                                            20,
                                                          ),
                                                      bottomLeft: isMe
                                                          ? const Radius.circular(
                                                              20,
                                                            )
                                                          : const Radius.circular(
                                                              4,
                                                            ),
                                                      bottomRight: isMe
                                                          ? const Radius.circular(
                                                              4,
                                                            )
                                                          : const Radius.circular(
                                                              20,
                                                            ),
                                                    ),
                                                    boxShadow: isOptimistic
                                                        ? []
                                                        : [
                                                            BoxShadow(
                                                              color: Colors
                                                                  .black
                                                                  .withOpacity(
                                                                    0.05,
                                                                  ),
                                                              blurRadius: 2,
                                                              offset:
                                                                  const Offset(
                                                                    0,
                                                                    1,
                                                                  ),
                                                            ),
                                                          ],
                                                  ),
                                                  child: Opacity(
                                                    opacity: isOptimistic
                                                        ? 0.7
                                                        : 1.0,
                                                    child: Text(
                                                      msg['text'] ?? '',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        color: isMe
                                                            ? Colors.white
                                                            : Colors.black87,
                                                        height: 1.3,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            if (isMe) const SizedBox(width: 16),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  color: Colors.white,
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        const SizedBox(width: 4),
                        // Camera Button
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Colors.blueAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Text Input Area (Includes Reply Preview)
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Reply Preview
                              if (provider.replyToMessage != null)
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border(
                                      left: BorderSide(
                                        color: Colors.blueAccent,
                                        width: 4,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.reply,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              provider.replyToMessage!['sender_id'] ==
                                                      provider.currentUserId
                                                  ? 'You'
                                                  : widget.friendName,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: Colors.blueAccent,
                                              ),
                                            ),
                                            Text(
                                              provider.replyToMessage!['text'] ??
                                                  '',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                        onPressed: () {
                                          provider.clearReply();
                                        },
                                      ),
                                    ],
                                  ),
                                ),

                              // Text Field
                              TextField(
                                controller: _controller,
                                focusNode: _focusNode,
                                decoration: InputDecoration(
                                  hintText: 'Message...',
                                  hintStyle: TextStyle(color: Colors.grey[600]),
                                  filled: true,
                                  fillColor: Colors.grey[200],
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide.none,
                                  ),
                                  isDense: true,
                                ),
                                minLines: 1,
                                maxLines: 4,
                                onSubmitted: (_) async {
                                  final text = _controller.text;
                                  _controller.clear(); // Clear immediately
                                  await provider.sendMessage(
                                    widget.chatId,
                                    text,
                                  );
                                  _scrollToBottom();
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),
                        // Send Button
                        GestureDetector(
                          onTap: () async {
                            final text = _controller.text;
                            _controller.clear(); // Clear immediately
                            await provider.sendMessage(widget.chatId, text);
                            _scrollToBottom();
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.send,
                              color: Colors.blueAccent,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
