class AIConversationModel {
  final String id;
  final String residentId;
  final String title;
  final String? lastMessage;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  AIConversationModel({
    required this.id,
    required this.residentId,
    required this.title,
    this.lastMessage,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AIConversationModel.fromJson(Map<String, dynamic> json) {
    return AIConversationModel(
      id: json['id'] as String,
      residentId: json['resident_id'] as String,
      title: json['title'] as String,
      lastMessage: json['last_message'] as String?,
      isArchived: (json['is_archived'] == 1 || json['is_archived'] == true),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
