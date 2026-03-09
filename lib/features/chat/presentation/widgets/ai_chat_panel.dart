import 'package:flutter/material.dart';
import 'dart:math';
import 'package:google_fonts/google_fonts.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_theme.dart';
import 'package:fcm_app/core/services/translation_service.dart';
import 'package:fcm_app/shared/models/parsed_task_model.dart';
import 'package:fcm_app/shared/models/user_info_model.dart';
import 'package:fcm_app/shared/widgets/repair_request_preview_card.dart';
import 'package:fcm_app/shared/widgets/repair_confirmation_overlay.dart';
import '../../data/repositories/ai_chat_repository.dart';
import '../../data/models/ai_conversation_model.dart';
import '../../data/models/ai_message_model.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:permission_handler/permission_handler.dart';

class AIChatPanel extends StatefulWidget {
  final VoidCallback onClose;
  final String residentName;
  final VoidCallback? onHistoryRequested;

  const AIChatPanel({
    super.key,
    required this.onClose,
    required this.residentName,
    this.onHistoryRequested,
  });

  @override
  State<AIChatPanel> createState() => _AIChatPanelState();
}

class _AIChatPanelState extends State<AIChatPanel> {
  final _repo = AIChatRepository.instance;
  final _msgCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _msgFocusNode = FocusNode();

  List<AIConversationModel> _conversations = [];
  List<AIMessageModel> _currentMessages = [];
  String? _activeConversationId;
  bool _isLoadingThreads = true;
  bool _isLoadingMessages = false;
  bool _isSending = false;

  // Persistent Draft Text
  static String _draftText = '';

  String _searchQuery = '';
  bool _isNewChat = false;

  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  double _soundLevel = 0.0;

  AIConversationModel? get _activeConversation {
    try {
      return _conversations.firstWhere((c) => c.id == _activeConversationId);
    } catch (e) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _msgCtrl.text = _draftText;
    _msgCtrl.addListener(() {
      _draftText = _msgCtrl.text;
    });

    _loadConversations();
    _initSpeech();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    });
  }

  Future<void> _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() {
            _isListening = false;
          });
        }
      },
      onError: (errorNotification) {
        print('Speech recognition error: ${errorNotification.errorMsg}');

        String? message;
        if (errorNotification.errorMsg == 'error_network') {
          message = 'Speech connection failed. Try again or check internet.';
        } else if (errorNotification.errorMsg == 'error_no_match') {
          message = 'No speech detected.';
        } else if (errorNotification.errorMsg == 'error_speech_timeout') {
          message = 'Recording timed out.';
        }

        if (message != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(message), duration: const Duration(seconds: 2)),
          );
        }

        setState(() {
          _isListening = false;
        });
      },
    );
    setState(() {});
  }

  Future<void> _startListening() async {
    final status = await Permission.microphone.request();
    print('Mic permission status: $status');
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(TranslationService.instance.t('mic_permission_denied'))),
        );
      }
      return;
    }

    if (!_speechEnabled) {
      await _initSpeech();
    }

    if (_speechEnabled) {
      try {
        await _speechToText.listen(
          onResult: _onSpeechResult,
          onSoundLevelChange: _onSoundLevelChange,
          localeId: 'th_TH',
        );
        _msgFocusNode.unfocus();
        setState(() {
          _isListening = true;
          _soundLevel = 0.0;
        });
      } catch (e) {
        print('Listen error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cannot start recording: $e')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Speech recognition not available.')),
        );
      }
    }
  }

  Future<void> _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _msgCtrl.text = result.recognizedWords;
    });
  }

  void _onSoundLevelChange(double level) {
    setState(() {
      _soundLevel = level;
    });
  }

  Future<void> _loadConversations() async {
    if (!mounted) return;
    setState(() => _isLoadingThreads = true);
    final threads = await _repo.getConversations();
    if (!mounted) return;
    setState(() {
      _conversations = threads;
      _isLoadingThreads = false;
      if (threads.isNotEmpty) {
        if (threads.first.isArchived) {
          // Unsent logic dictates archived threads should default to new thread view
          _currentMessages = [];
          _activeConversationId = null;
        } else {
          _setActiveConversation(threads.first.id);
        }
      } else {
        // Start a fresh thread
        _currentMessages = [];
        _activeConversationId = null;
      }
    });
  }

  Future<void> _setActiveConversation(String id) async {
    setState(() {
      _activeConversationId = id;
      _isLoadingMessages = true;
    });

    final msgs = await _repo.getMessages(id);
    if (!mounted) return;
    setState(() {
      _currentMessages = msgs;
      _isLoadingMessages = false;
    });

    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    if (_isListening) {
      await _stopListening();
    }

    setState(() {
      _isSending = true;
      // Optimistic update
      _currentMessages.add(AIMessageModel(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: _activeConversationId ?? 'new',
        senderType: 'USER',
        content: text,
        createdAt: DateTime.now(),
      ));
      _msgCtrl.clear();
      _draftText = '';
    });
    _scrollToBottom();

    final result =
        await _repo.sendMessage(text, conversationId: _activeConversationId);

    if (!mounted) return;

    if (result['success']) {
      final data = result['data'];
      final newConvoId = data['conversation_id'];

      // If it was a new conversation, refresh threads and extract tasks
      if (_activeConversationId == null) {
        // Extract tasks from AI reply BEFORE reloading
        final intentResult = data['intent_result'];
        if (intentResult != null && intentResult['request'] != null) {
          final request = intentResult['request'];
          final tasksList = request['tasks'] as List?;
          if (tasksList != null && tasksList.isNotEmpty) {
            final parsedTasks = tasksList
                .map((t) => ParsedTask.fromJson(Map<String, dynamic>.from(t)))
                .toList();

            final residentInfoRaw = data['resident_info'];
            UserInfoModel userInfo;
            if (residentInfoRaw != null) {
              userInfo = UserInfoModel.fromJson(residentInfoRaw);
            } else {
              userInfo = UserInfoModel(name: 'Unknown', houseNumber: 'Unknown');
            }

            _repo.savePendingTasks(parsedTasks, userInfo);
          }
        }
        await _loadConversations();
        // Keep optimistic messages + AI reply in view
        setState(() {
          _activeConversationId = newConvoId;
          _isNewChat = false;
          final intentResult = data['intent_result'];
          String? currActionData;
          String? currActionState;

          if (intentResult != null && intentResult['request'] != null) {
            final requestObj = intentResult['request'];
            final tasksList = requestObj['tasks'] as List?;
            if (tasksList != null && tasksList.isNotEmpty) {
              currActionData = jsonEncode(requestObj);
              currActionState = 'pending';
            }
          }

          _currentMessages.add(AIMessageModel(
            id: data['ai_message_id'] ??
                'ai_${DateTime.now().millisecondsSinceEpoch}',
            conversationId: newConvoId,
            senderType: 'AI',
            content: data['reply_text'],
            actionData: currActionData,
            actionState: currActionState,
            createdAt: DateTime.now(),
          ));
        });
        _scrollToBottom();
      } else {
        // Just append the AI's reply
        setState(() {
          final intentResult = data['intent_result'];
          String? currActionData;
          String? currActionState;

          if (intentResult != null && intentResult['request'] != null) {
            final requestObj = intentResult['request'];
            final tasksList = requestObj['tasks'] as List?;
            if (tasksList != null && tasksList.isNotEmpty) {
              currActionData = jsonEncode(requestObj);
              currActionState = 'pending';
            }
          }

          _currentMessages.add(AIMessageModel(
            id: data['ai_message_id'] ??
                'ai_${DateTime.now().millisecondsSinceEpoch}',
            conversationId: newConvoId,
            senderType: 'AI',
            content: data['reply_text'],
            actionData: currActionData,
            actionState: currActionState,
            createdAt: DateTime.now(),
          ));
        });

        // Check for parsed tasks in intent_result
        final intentResult = data['intent_result'];
        if (intentResult != null && intentResult['request'] != null) {
          final request = intentResult['request'];
          final tasksList = request['tasks'] as List?;
          if (tasksList != null && tasksList.isNotEmpty) {
            final parsedTasks = tasksList
                .map((t) => ParsedTask.fromJson(Map<String, dynamic>.from(t)))
                .toList();

            final residentInfoRaw = data['resident_info'];
            UserInfoModel userInfo;
            if (residentInfoRaw != null) {
              userInfo = UserInfoModel.fromJson(residentInfoRaw);
            } else {
              userInfo = UserInfoModel(name: 'Unknown', houseNumber: 'Unknown');
            }

            _repo.savePendingTasks(parsedTasks, userInfo);
          }
        }

        _scrollToBottom();
      }
    } else {
      // Handle error gracefully
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: ${result["error"]}')));
      // Remove optimistic update
      setState(() {
        _currentMessages.removeLast();
      });
    }

    setState(() {
      _isSending = false;
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _deleteConversation(String id) async {
    final t = TranslationService.instance;
    final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              backgroundColor: DashboardTheme.surface,
              title: Text(t.t('ai_panel_delete_title'),
                  style: GoogleFonts.outfit(color: DashboardTheme.textMain)),
              content: Text(t.t('ai_panel_delete_body'),
                  style:
                      GoogleFonts.outfit(color: DashboardTheme.textSecondary)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(t.t('cancel'),
                        style: GoogleFonts.outfit(
                            color: DashboardTheme.textPale))),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(t.t('ai_panel_delete_confirm'),
                        style: GoogleFonts.outfit(color: Colors.red))),
              ],
            ));
    if (confirm != true) return;

    final success = await _repo.deleteConversation(id);
    if (success && mounted) {
      if (_activeConversationId == id) {
        _activeConversationId = null;
        _currentMessages = [];
      }
      await _loadConversations();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: TranslationService.instance.currentLanguage,
      builder: (context, _, __) => _buildPanel(context),
    );
  }

  Widget _buildPanel(BuildContext context) {
    return Container(
      width: 400,
      height: 550,
      decoration: BoxDecoration(
        color: DashboardTheme.background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DashboardTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // Floating Window Header
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: DashboardTheme.surface,
                border:
                    Border(bottom: BorderSide(color: DashboardTheme.border)),
              ),
              child: Row(
                children: [
                  Text(
                    'V', // Bold V Branding
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: DashboardTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    TranslationService.instance.t('ai_panel_title'),
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: DashboardTheme.textMain,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon:
                        Icon(Icons.close, color: DashboardTheme.textSecondary),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),
            // Body: 2-Column Layout or Stack (Simplified for smaller width)
            Expanded(
              child: _activeConversationId == null &&
                      _conversations.isNotEmpty &&
                      !_isNewChat
                  ? _buildSidebar()
                  : Stack(
                      children: [
                        _buildChatArea(),
                        // Add a button to go back to history if needed
                        if (_conversations.isNotEmpty)
                          Positioned(
                            top: 12,
                            right: 16,
                            child: IconButton(
                              icon: Icon(Icons.history,
                                  color: DashboardTheme.textSecondary),
                              onPressed: () {
                                setState(() {
                                  _activeConversationId = null;
                                  _isNewChat = false;
                                });
                              },
                            ),
                          )
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _startNewChat() {
    setState(() {
      _activeConversationId = null;
      _currentMessages = [];
      _repo.clearPendingTasks();
      _isNewChat = true;
      _searchCtrl.clear();
      _msgCtrl.clear();
    });
  }

  @override
  void dispose() {
    _msgFocusNode.dispose();
    _msgCtrl.dispose();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    _speechToText.stop();
    super.dispose();
  }

  Widget _buildSidebar() {
    // Filter conversations by search query
    final filtered = _searchQuery.isEmpty
        ? _conversations
        : _conversations.where((c) {
            final title = c.title.toLowerCase();
            return title.contains(_searchQuery);
          }).toList();

    return Container(
      color: DashboardTheme.surfaceSecondary,
      child: Column(
        children: [
          // Header / Search
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            color: DashboardTheme.surface,
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: TextField(
                      controller: _searchCtrl,
                      textAlignVertical: TextAlignVertical.center,
                      style: GoogleFonts.outfit(
                          color: DashboardTheme.textMain, fontSize: 13),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: DashboardTheme.background,
                        prefixIcon: Icon(Icons.search,
                            color: DashboardTheme.textPale, size: 16),
                        prefixIconConstraints:
                            const BoxConstraints(minWidth: 36, minHeight: 36),
                        hintText:
                            TranslationService.instance.t('ai_panel_search'),
                        hintStyle: GoogleFonts.outfit(
                            color: DashboardTheme.textPale, fontSize: 13),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                              color: DashboardTheme.primary.withOpacity(0.5)),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: TranslationService.instance.t('ai_panel_new_chat'),
                  child: InkWell(
                    onTap: _startNewChat,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: DashboardTheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.add,
                          color: DashboardTheme.primary, size: 18),
                    ),
                  ),
                )
              ],
            ),
          ),

          // History List
          Expanded(
            child: _isLoadingThreads
                ? Center(
                    child: CircularProgressIndicator(
                        color: DashboardTheme.primary))
                : filtered.isEmpty
                    ? Center(
                        child: Text(
                        _searchQuery.isNotEmpty
                            ? TranslationService.instance.t('ai_panel_no_chats')
                            : TranslationService.instance
                                .t('ai_panel_no_chats'),
                        style:
                            GoogleFonts.outfit(color: DashboardTheme.textPale),
                      ))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final c = filtered[index];
                          final isSelected = c.id == _activeConversationId;
                          return _buildHistoryItem(c, isSelected);
                        },
                      ),
          )
        ],
      ),
    );
  }

  Widget _buildHistoryItem(AIConversationModel convo, bool isSelected) {
    return _HistoryItem(
      convo: convo,
      isSelected: isSelected,
      onTap: () => _setActiveConversation(convo.id),
      onDelete: () => _deleteConversation(convo.id),
    );
  }

  Widget _buildChatArea() {
    return Column(
      children: [
        // Thread Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: DashboardTheme.background,
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: DashboardTheme.primary.withOpacity(0.2),
                child: Text(
                  'V',
                  style: GoogleFonts.outfit(
                    color: DashboardTheme.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TranslationService.instance.t('ai_panel_assistant_name'),
                    style: GoogleFonts.outfit(
                        color: DashboardTheme.textMain,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _isSending
                        ? TranslationService.instance.t('ai_panel_typing')
                        : TranslationService.instance.t('ai_panel_online'),
                    style: GoogleFonts.outfit(
                        color: DashboardTheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              )
            ],
          ),
        ),
        Divider(color: DashboardTheme.border, height: 1),

        // Messages + Request Card
        Expanded(
          child: _isLoadingMessages
              ? Center(
                  child:
                      CircularProgressIndicator(color: DashboardTheme.primary))
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(20),
                  itemCount: _currentMessages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageBubble(_currentMessages[index]);
                  },
                ),
        ),

        // Input Area
        _buildInputArea(),
      ],
    );
  }

  Widget _buildInputArea() {
    final isArchived = _activeConversation?.isArchived ?? false;

    if (isArchived) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DashboardTheme.surface,
          border: Border(top: BorderSide(color: DashboardTheme.border)),
        ),
        child: Center(
          child: Text(
            'This conversation is archived.',
            style: GoogleFonts.outfit(
              color: DashboardTheme.textPale,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DashboardTheme.surface,
        border: Border(top: BorderSide(color: DashboardTheme.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgCtrl,
              focusNode: _msgFocusNode,
              style: GoogleFonts.outfit(
                  color: DashboardTheme.textMain, fontSize: 14),
              decoration: InputDecoration(
                hintText: _isListening
                    ? TranslationService.instance.t('ai_panel_listening')
                    : TranslationService.instance.t('ai_panel_input_hint'),
                hintStyle: GoogleFonts.outfit(
                    color: _isListening ? Colors.red : DashboardTheme.textPale,
                    fontSize: 14),
                filled: true,
                fillColor: _isListening
                    ? Colors.red.withOpacity(0.05)
                    : DashboardTheme.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                      color: DashboardTheme.primary.withOpacity(0.5)),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          _isListening
              ? InkWell(
                  onTap: _stopListening,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(21),
                    ),
                    child: Center(
                      child: VoiceSpectrumWidget(
                          soundLevel: _soundLevel, color: Colors.white),
                    ),
                  ),
                )
              : InkWell(
                  onTap: _startListening,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: DashboardTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mic_none,
                      color: Colors.black,
                      size: 18,
                    ),
                  ),
                ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _isSending ? null : _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DashboardTheme.primary,
                shape: BoxShape.circle,
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.black, strokeWidth: 2))
                  : const Icon(Icons.send_rounded,
                      color: Colors.black, size: 18),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMessageBubble(AIMessageModel msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: msg.isUser
                  ? DashboardTheme.primaryDim
                  : DashboardTheme.surfaceSecondary,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
                bottomRight: Radius.circular(msg.isUser ? 4 : 16),
              ),
              border: Border.all(
                color: msg.isUser
                    ? DashboardTheme.primary.withOpacity(0.3)
                    : DashboardTheme.border,
              ),
            ),
            child: Text(
              msg.content,
              style: GoogleFonts.outfit(
                color: msg.isUser
                    ? DashboardTheme.primary
                    : DashboardTheme.textMain,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
          if (!msg.isUser &&
              msg.actionData != null &&
              msg.actionData!.isNotEmpty)
            _buildEmbeddedActionCard(msg),
        ],
      ),
    );
  }

  Widget _buildEmbeddedActionCard(AIMessageModel msg) {
    try {
      final requestObj = jsonDecode(msg.actionData!);
      final tasksList = requestObj['tasks'] as List?;
      if (tasksList != null && tasksList.isNotEmpty) {
        final parsedTasks = tasksList
            .map((t) => ParsedTask.fromJson(Map<String, dynamic>.from(t)))
            .toList();

        // Check if this is the latest pending message
        final isLatestPending = msg.id ==
                _currentMessages
                    .lastWhere((m) => m.actionState == 'pending',
                        orElse: () => msg)
                    .id &&
            msg.actionState == 'pending';

        // Hide older superseded drafts to prevent multiple pending cards in UI
        if (msg.actionState == 'pending' && !isLatestPending) {
          return const SizedBox.shrink();
        }

        return MouseRegion(
          cursor: isLatestPending
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: GestureDetector(
            onTap: isLatestPending
                ? () => _showConfirmationOverlay(parsedTasks, msg.id)
                : (msg.actionState == 'confirmed' &&
                        widget.onHistoryRequested != null)
                    ? () => widget.onHistoryRequested!()
                    : null,
            child: Opacity(
              opacity: isLatestPending ? 1.0 : 0.6,
              child: RepairRequestPreviewCard(
                tasks: parsedTasks,
                isReadOnly: true,
                actionState: msg.actionState,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      print('FCM AIChatPanel: Error parsing embedded action data -> $e');
    }
    return const SizedBox.shrink();
  }

  void _showConfirmationOverlay(List<ParsedTask> tasks, String messageId) {
    final userInfoRaw = _repo.pendingRequestDataNotifier.value?['userInfo'];
    if (userInfoRaw != null && userInfoRaw is UserInfoModel) {
      showRepairConfirmationOverlay(
        context: context,
        tasks: tasks,
        userInfo: userInfoRaw,
        onConfirm: () async {
          // 1. Send the actual request to the backend DB
          final success =
              await _repo.confirmRequest(tasks, messageId: messageId);
          if (!success) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to confirm request')),
              );
            }
            return false;
          }

          // 2. Update panel state
          setState(() {
            final idx = _currentMessages.indexWhere((m) => m.id == messageId);
            if (idx != -1) {
              final old = _currentMessages[idx];
              _currentMessages[idx] = AIMessageModel(
                id: old.id,
                conversationId: old.conversationId,
                senderType: old.senderType,
                content: old.content,
                actionData: old.actionData,
                actionState: 'confirmed',
                createdAt: old.createdAt,
              );
            }
          });
          _repo.updateMessageActionState(messageId, 'confirmed');
          _repo.clearPendingTasks();

          // Automatically archive the thread after confirmation
          if (_activeConversationId != null) {
            await _repo.archiveConversation(_activeConversationId!);
            // Optionally, tell the panel to reload the thread list here so it reflects the change
            _loadConversations();
          }

          return true;
        },
        onCancel: () {
          setState(() {
            final idx = _currentMessages.indexWhere((m) => m.id == messageId);
            if (idx != -1) {
              final old = _currentMessages[idx];
              _currentMessages[idx] = AIMessageModel(
                id: old.id,
                conversationId: old.conversationId,
                senderType: old.senderType,
                content: old.content,
                actionData: old.actionData,
                actionState: 'cancelled',
                createdAt: old.createdAt,
              );
            }
          });
          _repo.updateMessageActionState(messageId, 'cancelled');
          _repo.clearPendingTasks();
        },
      );
    }
  }
}

class _HistoryItem extends StatefulWidget {
  final AIConversationModel convo;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HistoryItem({
    required this.convo,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_HistoryItem> createState() => _HistoryItemState();
}

class _HistoryItemState extends State<_HistoryItem> {
  bool _isHovered = false;
  bool _isDeleteHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isDeleteHovered = false;
      }),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? DashboardTheme.primary.withOpacity(0.1)
                : DashboardTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: widget.isSelected
                    ? DashboardTheme.primary.withOpacity(0.3)
                    : DashboardTheme.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: DashboardTheme.primary.withOpacity(0.2),
                child: Text(
                  'V',
                  style: GoogleFonts.outfit(
                    color: DashboardTheme.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.convo.title,
                      style: GoogleFonts.outfit(
                          color: DashboardTheme.textMain,
                          fontWeight: widget.isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.convo.lastMessage ?? 'Started...',
                      style: GoogleFonts.outfit(
                          color: DashboardTheme.textSecondary, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (_isHovered)
                MouseRegion(
                  onEnter: (_) => setState(() => _isDeleteHovered = true),
                  onExit: (_) => setState(() => _isDeleteHovered = false),
                  child: GestureDetector(
                    onTap: widget.onDelete,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isDeleteHovered
                            ? Colors.red.withOpacity(0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: _isDeleteHovered
                            ? Border.all(color: Colors.red.withOpacity(0.3))
                            : null,
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        color: _isDeleteHovered
                            ? Colors.red
                            : DashboardTheme.textPale,
                        size: 20,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class VoiceSpectrumWidget extends StatefulWidget {
  final double soundLevel;
  final Color? color;

  const VoiceSpectrumWidget({super.key, required this.soundLevel, this.color});

  @override
  State<VoiceSpectrumWidget> createState() => _VoiceSpectrumWidgetState();
}

class _VoiceSpectrumWidgetState extends State<VoiceSpectrumWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(15, (index) {
            double height;
            if (widget.soundLevel > 0) {
              // Real-time amplitude
              height = 3 + (widget.soundLevel.abs() * 2);
              height = height.clamp(3, 24);
            } else {
              // Web Fallback Animation
              final phase = (index / 15) * 2 * pi;
              final t = _controller.value * 2 * pi;
              height = 8 + 6 * sin(t + phase) + _random.nextDouble() * 4;
            }

            return Container(
              width: 3,
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                color: widget.color ?? DashboardTheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}
