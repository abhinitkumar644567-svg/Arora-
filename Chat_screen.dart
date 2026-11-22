import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/app_models.dart';
import '../../widgets/liquid_glass_box.dart';
import '../main_shell.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  final ImagePicker _picker = ImagePicker();

  Uint8List? _pendingImageBytes;
  int _lastKnownMessageCount = 0;
  bool _wasPartnerTyping = false;

  static const List<String> _quickPrompts = [
    'आज के मुख्य नोट्स भेजो',
    'फॉर्मूला शीट चेक करें',
    'अगला रिवीज़न प्लान क्या है?',
  ];

  @override
  void initState() {
    super.initState();
    _lastKnownMessageCount = appStore.messages.length;
    _wasPartnerTyping = appStore.isPartnerTyping;
    appStore.addListener(_onStoreUpdated);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(animate: false);
    });
  }

  @override
  void dispose() {
    appStore.removeListener(_onStoreUpdated);
    _messageController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _onStoreUpdated() {
    final currentCount = appStore.messages.length;
    final isTyping = appStore.isPartnerTyping;

    if (currentCount != _lastKnownMessageCount ||
        isTyping != _wasPartnerTyping) {
      _lastKnownMessageCount = currentCount;
      _wasPartnerTyping = isTyping;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom(animate: true);
      });
    }
  }

  void _scrollToBottom({required bool animate}) {
    if (!_scrollController.hasClients) return;
    final target = _scrollController.position.maxScrollExtent;
    if (animate) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(target);
    }
  }

  Future<void> _pickAttachment(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 78,
        maxWidth: 1600,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (!mounted) return;

      HapticFeedback.selectionClick();
      setState(() => _pendingImageBytes = bytes);
    } catch (_) {
      if (!mounted) return;
      _showToast('इमेज चुनने में समस्या आई, कृपया पुनः प्रयास करें।');
    }
  }

  Future<void> _openAttachmentPickerSheet() async {
    FocusScope.of(context).unfocus();
    HapticFeedback.selectionClick();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: LiquidGlassBox(
              borderRadius: 28,
              blur: 28,
              surfaceOpacity: 0.78,
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'इमेज अटैच करें',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _PickerOptionTile(
                          icon: Icons.photo_library_rounded,
                          label: 'गैलरी से चुनें',
                          color: const Color(0xFF007AFF),
                          onTap: () {
                            Navigator.of(ctx).pop();
                            _pickAttachment(ImageSource.gallery);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _PickerOptionTile(
                          icon: Icons.camera_alt_rounded,
                          label: 'कैमरा खोलें',
                          color: const Color(0xFF10B981),
                          onTap: () {
                            Navigator.of(ctx).pop();
                            _pickAttachment(ImageSource.camera);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _sendCurrentMessage([String? presetText]) async {
    final text = (presetText ?? _messageController.text).trim();
    final attachment = presetText == null ? _pendingImageBytes : null;

    if (text.isEmpty && attachment == null) return;

    HapticFeedback.lightImpact();
    if (presetText == null) {
      _messageController.clear();
      setState(() => _pendingImageBytes = null);
    }

    await appStore.sendMessage(text, attachmentBytes: attachment);
  }

  Future<void> _confirmClearChat() async {
    if (appStore.messages.isEmpty) return;
    HapticFeedback.selectionClick();

    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white.withValues(alpha: 0.96),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'पूरी चैट साफ़ करें?',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: const Text(
          'इस बातचीत के सभी संदेश हटा दिए जाएँगे। क्या आप जारी रखना चाहते हैं?',
          style: TextStyle(color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('रद्द करें'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('साफ़ करें'),
          ),
        ],
      ),
    );

    if (shouldClear == true) {
      appStore.clearChat();
      _showToast('चैट साफ़ कर दी गई है।');
    }
  }

  void _showMessageActions(ChatMessage message) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: LiquidGlassBox(
              borderRadius: 26,
              blur: 28,
              surfaceOpacity: 0.80,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.text.isNotEmpty)
                    ListTile(
                      leading: const Icon(
                        Icons.copy_rounded,
                        color: Color(0xFF007AFF),
                      ),
                      title: const Text(
                        'मैसेज कॉपी करें',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: message.text));
                        Navigator.of(ctx).pop();
                        _showToast('मैसेज कॉपी हो गया।');
                      },
                    ),
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFDC2626),
                    ),
                    title: const Text(
                      'मैसेज डिलीट करें',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      appStore.deleteMessage(message.id);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openFullScreenImage(Uint8List bytes) {
    HapticFeedback.selectionClick();
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.86),
      builder: (ctx) {
        return Dialog.fullscreen(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4.5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.memory(bytes, fit: BoxFit.contain),
                  ),
                ),
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: LiquidGlassBox(
                      borderRadius: 50,
                      blur: 20,
                      surfaceOpacity: 0.32,
                      padding: const EdgeInsets.all(10),
                      onTap: () => Navigator.of(ctx).pop(),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showToast(String text) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0F172A),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 112),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 80;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: ListenableBuilder(
        listenable: appStore,
        builder: (context, _) {
          final messages = appStore.messages;
          final isTyping = appStore.isPartnerTyping;

          return Column(
            children: [
              // 1. चैट स्टेटस ग्लास स्ट्रिप
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                child: _buildChatStatusBar(isTyping, messages.length),
              ),

              // 2. स्क्रॉल होने वाली मैसेज लिस्ट
              Expanded(
                child: messages.isEmpty && !isTyping
                    ? _buildEmptyChatState()
                    : ListView.builder(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                        itemCount: messages.length + (isTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (isTyping && index == messages.length) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 6, bottom: 4),
                              child: _LiquidTypingBubble(),
                            );
                          }

                          final msg = messages[index];
                          final showTopGap = index == 0 ||
                              messages[index - 1].isMe != msg.isMe;

                          return Padding(
                            padding: EdgeInsets.only(
                              top: showTopGap ? 10 : 4,
                              bottom: 2,
                            ),
                            child: _ChatMessageBubble(
                              message: msg,
                              onLongPress: () => _showMessageActions(msg),
                              onImageTap: msg.attachmentBytes != null
                                  ? () =>
                                      _openFullScreenImage(msg.attachmentBytes!)
                                  : null,
                            ),
                          );
                        },
                      ),
              ),

              // 3. फ्लोटिंग Liquid Glass मैसेज इनपुट बार
              AnimatedPadding(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.fromLTRB(
                  16,
                  6,
                  16,
                  isKeyboardOpen ? 10 : MainShell.bottomDockClearance,
                ),
                child: _buildMessageComposer(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChatStatusBar(bool isTyping, int totalCount) {
    return LiquidGlassBox(
      borderRadius: 22,
      blur: 20,
      surfaceOpacity: 0.62,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF007AFF), Color(0xFF38BDF8)],
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 19,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'स्मार्ट डिस्कशन रूम',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  isTyping
                      ? 'टाइप कर रहे हैं...'
                      : 'ऑनलाइन • $totalCount संदेश',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isTyping
                        ? const Color(0xFF007AFF)
                        : const Color(0xFF059669),
                  ),
                ),
              ],
            ),
          ),
          if (totalCount > 0)
            Tooltip(
              message: 'चैट साफ़ करें',
              child: GestureDetector(
                onTap: _confirmClearChat,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.delete_sweep_rounded,
                    size: 19,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyChatState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LiquidGlassBox(
              width: 74,
              height: 74,
              borderRadius: 24,
              padding: EdgeInsets.zero,
              surfaceOpacity: 0.70,
              child: const Center(
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 32,
                  color: Color(0xFF007AFF),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'नई बातचीत शुरू करें',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'नीचे कोई भी संदेश लिखें, फोटो भेजें या त्वरित सुझाव चुनें।',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _quickPrompts.map((prompt) {
                return LiquidGlassBox(
                  borderRadius: 20,
                  blur: 16,
                  surfaceOpacity: 0.68,
                  showShadow: false,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  onTap: () => _sendCurrentMessage(prompt),
                  child: Text(
                    prompt,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF007AFF),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageComposer() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _messageController,
      builder: (context, value, _) {
        final canSend =
            value.text.trim().isNotEmpty || _pendingImageBytes != null;

        return LiquidGlassBox(
          borderRadius: 28,
          blur: 26,
          surfaceOpacity: 0.72,
          padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // यदि यूज़र ने भेजने के लिए इमेज चुनी है, तो उसका प्रीव्यू
              if (_pendingImageBytes != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 4, 6, 10),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.memory(
                          _pendingImageBytes!,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: -6,
                        right: -6,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _pendingImageBytes = null),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFF0F172A),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // इमेज अटैचमेंट बटन
                  GestureDetector(
                    onTap: _openAttachmentPickerSheet,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_photo_alternate_rounded,
                        size: 20,
                        color: Color(0xFF007AFF),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // मल्टी-लाइन टेक्स्ट इनपुट
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _inputFocusNode,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendCurrentMessage(),
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF0F172A),
                      ),
                      decoration: const InputDecoration(
                        hintText: 'संदेश लिखें...',
                        hintStyle: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 14.5,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // सेंड बटन
                  GestureDetector(
                    onTap: canSend ? () => _sendCurrentMessage() : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: canSend
                            ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF007AFF), Color(0xFF2563EB)],
                              )
                            : null,
                        color: canSend
                            ? null
                            : Colors.black.withValues(alpha: 0.08),
                        boxShadow: canSend
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF007AFF)
                                      .withValues(alpha: 0.30),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        Icons.arrow_upward_rounded,
                        size: 21,
                        color: canSend ? Colors.white : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback onLongPress;
  final VoidCallback? onImageTap;

  const _ChatMessageBubble({
    required this.message,
    required this.onLongPress,
    this.onImageTap,
  });

  IconData _statusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return Icons.schedule_rounded;
      case MessageStatus.sent:
        return Icons.done_rounded;
      case MessageStatus.delivered:
      case MessageStatus.read:
        return Icons.done_all_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxBubbleWidth = MediaQuery.sizeOf(context).width * 0.78;
    final isMe = message.isMe;

    final content = Column(
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.attachmentBytes != null) ...[
          GestureDetector(
            onTap: onImageTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 220,
                  minWidth: 150,
                ),
                child: Image.memory(
                  message.attachmentBytes!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          if (message.text.isNotEmpty) const SizedBox(height: 8),
        ],
        if (message.text.isNotEmpty)
          Text(
            message.text,
            style: TextStyle(
              fontSize: 14.8,
              height: 1.38,
              fontWeight: FontWeight.w500,
              color: isMe ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        const SizedBox(height: 5),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.formattedTime,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: isMe
                    ? Colors.white.withValues(alpha: 0.78)
                    : const Color(0xFF64748B),
              ),
            ),
            if (isMe) ...[
              const SizedBox(width: 4),
              Icon(
                _statusIcon(message.status),
                size: 14,
                color: message.status == MessageStatus.read
                    ? const Color(0xFFBAE6FD)
                    : Colors.white.withValues(alpha: 0.78),
              ),
            ],
          ],
        ),
      ],
    );

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxBubbleWidth),
        child: GestureDetector(
          onLongPress: onLongPress,
          child: isMe
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0A84FF), Color(0xFF0066E5)],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(22),
                      topRight: Radius.circular(22),
                      bottomLeft: Radius.circular(22),
                      bottomRight: Radius.circular(7),
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF007AFF).withValues(alpha: 0.22),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: content,
                )
              : LiquidGlassBox(
                  borderRadius: 22,
                  blur: 20,
                  surfaceOpacity: 0.70,
                  showShadow: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 11,
                  ),
                  child: content,
                ),
        ),
      ),
    );
  }
}

/// तीन बाउंसिंग डॉट्स वाला स्मूद Liquid Glass टाइपिंग इंडिकेटर
class _LiquidTypingBubble extends StatefulWidget {
  const _LiquidTypingBubble();

  @override
  State<_LiquidTypingBubble> createState() => _LiquidTypingBubbleState();
}

class _LiquidTypingBubbleState extends State<_LiquidTypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: LiquidGlassBox(
        borderRadius: 20,
        blur: 18,
        surfaceOpacity: 0.68,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final phase = ((_controller.value * 3) - i) % 3;
                final lift =
                    (phase >= 0 && phase <= 1) ? (1 - (phase - 0.5).abs() * 2) : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Transform.translate(
                    offset: Offset(0, -lift * 4.5),
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF)
                            .withValues(alpha: 0.45 + lift * 0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

class _PickerOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PickerOptionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 1.2),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}