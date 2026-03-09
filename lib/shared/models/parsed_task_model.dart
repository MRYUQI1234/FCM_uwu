/// Lightweight data class representing a single task parsed from AI intent JSON.
/// This model is shared across all request creation methods (AI chat, manual form, etc.)
class ParsedTask {
  final String? objectId;
  final String objectType;
  final String? objectName;
  final String description;
  final String urgency; // 'normal' | 'emergency'
  final String? preferDate;
  final String? preferTime;

  const ParsedTask({
    this.objectId,
    required this.objectType,
    this.objectName,
    required this.description,
    this.urgency = 'normal',
    this.preferDate,
    this.preferTime,
  });

  factory ParsedTask.fromJson(Map<String, dynamic> json) {
    return ParsedTask(
      objectId: json['object_id'] as String?,
      objectType: (json['object_type'] ?? '') as String,
      objectName: json['object_name'] as String?,
      description: (json['description'] ?? '') as String,
      urgency: (json['urgency'] ?? 'normal') as String,
      preferDate: json['prefer_date'] as String?,
      preferTime: json['prefer_time'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'object_id': objectId,
        'object_type': objectType,
        'object_name': objectName,
        'description': description,
        'urgency': urgency,
        'prefer_date': preferDate,
        'prefer_time': preferTime,
      };

  bool get isEmergency => urgency.toLowerCase() == 'emergency';
}
