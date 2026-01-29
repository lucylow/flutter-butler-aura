import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/env.dart';
import '../../../core/theme/aura_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/haptic_feedback.dart';
import '../../../shared/widgets/app_scaffold_with_nav.dart';
import '../data/chat_repository.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _typingAnimationController;

  @override
  void initState() {
    super.initState();
    _typingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _typingAnimationController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final isMobile = context.isMobile;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.position.pixels;
        if ((maxScroll - currentScroll) < 100) _scrollToBottom();
      }
    });

    final appBar = AppBar(
      backgroundColor: AuraColors.surfaceLight,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft, color: AuraColors.textDark),
        onPressed: () => context.pop(),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AuraColors.teal,
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.bot, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 10),
          const Text(
            'A.U.R.A. — Your Flutter Butler',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AuraColors.textDark,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          tooltip: 'New conversation',
          icon: const Icon(LucideIcons.plusCircle, color: AuraColors.textDark),
          onPressed: () {
            HapticUtils.lightImpact();
            ref.read(chatProvider.notifier).clearMessages();
          },
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Container(
            key: ValueKey(chatState.isConnected),
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: chatState.isConnected
                  ? AuraColors.successCheck.withValues(alpha: 0.2)
                  : AuraColors.coral.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: chatState.isConnected
                    ? AuraColors.successCheck
                    : AuraColors.coral,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: chatState.isConnected
                        ? AuraColors.successCheck
                        : AuraColors.coral,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  chatState.isConnected ? 'Connected' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: chatState.isConnected
                        ? AuraColors.textDark
                        : AuraColors.coral,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    return AppScaffoldWithNav(
      currentPath: GoRouterState.of(context).matchedLocation,
      appBar: appBar,
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              itemCount: chatState.messages.length + (chatState.messages.length <= 1 ? 1 : 0),
              itemBuilder: (context, index) {
                if (chatState.messages.length <= 1 && index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildHowItWorksCard(context),
                  );
                }
                final msgIndex = chatState.messages.length <= 1 ? index - 1 : index;
                final msg = chatState.messages[msgIndex];
                final isUser = msg.isUser;
                final isLastMessage = msgIndex == chatState.messages.length - 1;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: isUser
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!isUser) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AuraColors.teal,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.bot,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isUser
                                ? AuraColors.teal
                                : AuraColors.surfaceLight,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(20),
                              topRight: const Radius.circular(20),
                              bottomLeft: isUser
                                  ? const Radius.circular(20)
                                  : const Radius.circular(4),
                              bottomRight: isUser
                                  ? const Radius.circular(4)
                                  : const Radius.circular(20),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg.text,
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.4,
                                  color: isUser
                                      ? Colors.white
                                      : AuraColors.textDark,
                                ),
                              ),
                              if (isLastMessage && isUser) ...[
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      LucideIcons.check,
                                      size: 12,
                                      color: Colors.white.withValues(alpha: 0.8),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Sent',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.8),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (isUser) ...[
                        const SizedBox(width: 8),
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: AuraColors.teal.withValues(alpha: 0.3),
                          child: const Text(
                            'U',
                            style: TextStyle(
                              color: AuraColors.textDark,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          if (chatState.isLoading)
            const LinearProgressIndicator(
              minHeight: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AuraColors.teal),
            ),
          if (chatState.error != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AuraColors.coral.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AuraColors.coral.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.alertCircle,
                      color: AuraColors.coral, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      chatState.error!,
                      style: const TextStyle(
                        color: AuraColors.textDark,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 16),
                    onPressed: () =>
                        ref.read(chatProvider.notifier).clearError(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          _buildSuggestedGoals(context, chatState),
          _buildInputArea(context),
        ],
      ),
    );
  }

  Widget _buildThinkingBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      color: AuraColors.teal.withValues(alpha: 0.08),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AuraColors.teal),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'A.U.R.A. is thinking…',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AuraColors.teal.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AuraColors.teal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AuraColors.teal.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.gitBranch, size: 18, color: AuraColors.teal),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'You ask → Your butler plans → Devices and routines respond',
              style: TextStyle(
                fontSize: 12,
                color: AuraColors.textDark.withValues(alpha: 0.85),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const List<String> _suggestedGoals = [
    'Set up for movie night',
    'I\'m cold',
    'Goodnight',
    'Wind down',
  ];

  Widget _buildSuggestedGoals(BuildContext context, ChatState chatState) {
    if (chatState.messages.length > 2) return const SizedBox.shrink();
    return Container(
      color: AuraColors.surfaceLight,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _suggestedGoals.map((goal) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(goal, style: const TextStyle(fontSize: 12)),
                selected: false,
                onSelected: (_) {
                  HapticUtils.lightImpact();
                  ref.read(chatProvider.notifier).sendMessage(goal);
                },
                backgroundColor: AuraColors.lightGrey,
                side: BorderSide(color: AuraColors.teal.withValues(alpha: 0.5)),
                checkmarkColor: AuraColors.teal,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    return Container(
      color: AuraColors.surfaceLight,
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: AuraColors.textDark),
                maxLines: null,
                textInputAction: TextInputAction.send,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: Env.isGoalBackendConfigured()
                      ? 'What may I help you with? e.g. "Movie night" or "I\'m cold"'
                      : 'Ask your butler…',
                  hintStyle: TextStyle(
                    color: AuraColors.textLight.withValues(alpha: 0.8),
                  ),
                  filled: true,
                  fillColor: AuraColors.lightGrey,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: const BoxDecoration(
                color: AuraColors.teal,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(LucideIcons.send, color: Colors.white),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      HapticUtils.lightImpact();
      ref.read(chatProvider.notifier).sendMessage(text);
      _controller.clear();
      FocusScope.of(context).unfocus();
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    }
  }
}
