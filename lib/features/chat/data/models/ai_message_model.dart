class AIMessageModel {
  final String id;
  final String conversationId;
  final String senderType; // 'USER' or 'AI'
  final String content;
  final String? actionData;
  final String? actionState;
  final DateTime createdAt;

  AIMessageModel({
    required this.id,
    required this.conversationId,
    required this.senderType,
    required this.content,
    this.actionData,
    this.actionState,
    required this.createdAt,
  });

  bool get isUser => senderType == 'USER';

  factory AIMessageModel.fromJson(Map<String, dynamic> json) {
    return AIMessageModel(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderType: json['sender_type'] as String,
      content: json['content'] as String,
      actionData: json['action_data'] as String?,
      actionState: json['action_state'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
