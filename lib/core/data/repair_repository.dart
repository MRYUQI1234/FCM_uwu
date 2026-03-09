import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fcm_app/core/data/auth_repository.dart';

class RepairRequest {
  final String id;
  final String title;
  final String description;
  final String date;
  final String status;
  final Color statusColor;
  final List<String> imagePaths;
  final String? rejectionReason;
  final String? rejectionTemplate;

  // V11 Compliance Fields
  final DateTime? appointmentDate;
  final TimeOfDay? appointmentTime;
  final String? appointmentSlot; // 'AM' or 'PM' per SRS
  final bool isEmergency;
  final bool isWarranty;
  final double estimatedCost;

  // Assessment fields (FE-03)
  final int? rating;
  final String? assessmentComment;
  final DateTime? completionDate;
  final String? technicianName;

  // FE-02: Assignment fields
  final List<String> assignedStaff;

  // FE-03: Technician report fields
  final String? techReport;
  final List<String> techReportPhotos;
  final DateTime? workStartTime;

  // Requester info (for staff view)
  final String? requesterName;
  final String? requesterEmail;
  final String? requesterHouse;

  RepairRequest({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.status,
    required this.statusColor,
    this.imagePaths = const [],
    this.rejectionReason,
    this.rejectionTemplate,
    this.appointmentDate,
    this.appointmentTime,
    this.appointmentSlot,
    this.isEmergency = false,
    this.isWarranty = true,
    this.estimatedCost = 0.0,
    this.rating,
    this.assessmentComment,
    this.completionDate,
    this.technicianName,
    this.assignedStaff = const [],
    this.techReport,
    this.techReportPhotos = const [],
    this.workStartTime,
    this.requesterName,
    this.requesterEmail,
    this.requesterHouse,
  });

  /// Create a copy with modified fields
  RepairRequest copyWith({
    String? id,
    String? title,
    String? description,
    String? date,
    String? status,
    Color? statusColor,
    List<String>? imagePaths,
    String? rejectionReason,
    String? rejectionTemplate,
    DateTime? appointmentDate,
    TimeOfDay? appointmentTime,
    String? appointmentSlot,
    bool? isEmergency,
    bool? isWarranty,
    double? estimatedCost,
    int? rating,
    String? assessmentComment,
    DateTime? completionDate,
    String? technicianName,
    List<String>? assignedStaff,
    String? techReport,
    List<String>? techReportPhotos,
    DateTime? workStartTime,
    String? requesterName,
    String? requesterEmail,
    String? requesterHouse,
  }) {
    return RepairRequest(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      status: status ?? this.status,
      statusColor: statusColor ?? this.statusColor,
      imagePaths: imagePaths ?? this.imagePaths,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      rejectionTemplate: rejectionTemplate ?? this.rejectionTemplate,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      appointmentTime: appointmentTime ?? this.appointmentTime,
      appointmentSlot: appointmentSlot ?? this.appointmentSlot,
      isEmergency: isEmergency ?? this.isEmergency,
      isWarranty: isWarranty ?? this.isWarranty,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      rating: rating ?? this.rating,
      assessmentComment: assessmentComment ?? this.assessmentComment,
      completionDate: completionDate ?? this.completionDate,
      technicianName: technicianName ?? this.technicianName,
      assignedStaff: assignedStaff ?? this.assignedStaff,
      techReport: techReport ?? this.techReport,
      techReportPhotos: techReportPhotos ?? this.techReportPhotos,
      workStartTime: workStartTime ?? this.workStartTime,
      requesterName: requesterName ?? this.requesterName,
      requesterEmail: requesterEmail ?? this.requesterEmail,
      requesterHouse: requesterHouse ?? this.requesterHouse,
    );
  }
}

/// Team Preset — saved selection of technicians
class TeamPreset {
  final String id;
  final String name;
  final List<String> memberNames;
  final IconData icon;

  TeamPreset({
    required this.id,
    required this.name,
    required this.memberNames,
    this.icon = Icons.folder_rounded,
  });
}

class RepairRepository {
  static final RepairRepository instance = RepairRepository._internal();
  RepairRepository._internal();

  final String _baseUrl = 'http://localhost:3000/api';

  // ── Repairs ──
  final ValueNotifier<List<RepairRequest>> repairsNotifier = ValueNotifier([]);

  /// Fetch repair history from backend API
  Future<void> fetchHistory() async {
    try {
      final token = await AuthRepository.instance.getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$_baseUrl/repair/history'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          final List data = result['data'] ?? [];
          repairsNotifier.value = data.map<RepairRequest>((r) {
            // Build title from first task description or fallback
            final tasks = (r['tasks'] as List?) ?? [];
            final firstTask = tasks.isNotEmpty ? tasks[0] : null;
            final title = firstTask != null
                ? '${firstTask['category'] ?? ''} - ${firstTask['object_name'] ?? ''}'
                    .trim()
                : 'Repair Request';
            final description = firstTask?['description'] ?? '';
            final urgency = firstTask?['urgency'] ?? 'Normal';

            // Status color mapping
            Color statusColor;
            final status = (r['status'] ?? 'Created').toString();
            switch (status.toLowerCase()) {
              case 'completed':
              case 'reviewed':
                statusColor = Colors.green;
                break;
              case 'in progress':
              case 'inprogress':
                statusColor = Colors.blue;
                break;
              case 'denied':
                statusColor = Colors.red;
                break;
              default:
                statusColor = Colors.orange;
            }

            // Parse dates
            DateTime? completedAt;
            if (r['completed_at'] != null) {
              completedAt = DateTime.tryParse(r['completed_at'].toString());
            }
            DateTime? createdAt;
            if (r['created_at'] != null) {
              createdAt = DateTime.tryParse(r['created_at'].toString());
            }
            DateTime? preferDate;
            if (firstTask?['prefer_date'] != null) {
              preferDate =
                  DateTime.tryParse(firstTask['prefer_date'].toString());
            }

            final dateStr = createdAt != null
                ? '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}'
                : '';

            return RepairRequest(
              id: r['id']?.toString() ?? '',
              title: title.replaceAll(RegExp(r'^\s*-\s*'), ''),
              description: description,
              date: dateStr,
              status: status,
              statusColor: statusColor,
              technicianName: r['technician_name']?.toString(),
              completionDate: completedAt,
              appointmentDate: preferDate,
              isEmergency: urgency.toString().toLowerCase() == 'emergency',
            );
          }).toList();
        }
      }
    } catch (e) {
      debugPrint('FCM: Error fetching repair history: $e');
    }
  }

  // ── Team Presets ──
  final ValueNotifier<List<TeamPreset>> teamPresetsNotifier = ValueNotifier([
    TeamPreset(
      id: 'preset_1',
      name: 'Electrical Team',
      memberNames: ['Wichai', 'Pee'],
      icon: Icons.bolt_rounded,
    ),
    TeamPreset(
      id: 'preset_2',
      name: 'Plumbing Team',
      memberNames: ['Kong'],
      icon: Icons.water_drop_rounded,
    ),
  ]);

  void addRequest({
    required String title,
    required String description,
    List<String> imagePaths = const [],
    DateTime? appointmentDate,
    TimeOfDay? appointmentTime,
    String? appointmentSlot,
    bool isEmergency = false,
    bool isWarranty = true,
    double estimatedCost = 0.0,
    String? requesterName,
    String? requesterEmail,
    String? requesterHouse,
  }) {
    final now = DateTime.now();
    final dateStr =
        "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year + 543}";

    final newRequest = RepairRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      date: dateStr,
      status: 'Pending',
      statusColor: Colors.orange,
      imagePaths: imagePaths,
      appointmentDate: appointmentDate,
      appointmentTime: appointmentTime,
      appointmentSlot: appointmentSlot,
      isEmergency: isEmergency,
      isWarranty: isWarranty,
      estimatedCost: estimatedCost,
      requesterName: requesterName,
      requesterEmail: requesterEmail,
      requesterHouse: requesterHouse,
    );

    repairsNotifier.value = [newRequest, ...repairsNotifier.value];
  }

  void deleteRequest(String id) {
    repairsNotifier.value =
        repairsNotifier.value.where((item) => item.id != id).toList();
  }

  void updateRequest(RepairRequest updatedItem) {
    final index =
        repairsNotifier.value.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      final List<RepairRequest> newList = List.from(repairsNotifier.value);
      newList[index] = updatedItem;
      repairsNotifier.value = newList;
    }
  }

  // ── SRS Workflow Methods ──

  /// FE-02: Assign technicians to a request
  void assignRequest(String id, List<String> staffNames) {
    final request = repairsNotifier.value.firstWhere((r) => r.id == id);
    updateRequest(request.copyWith(
      status: 'In Progress',
      statusColor: Colors.blue,
      assignedStaff: staffNames,
      technicianName: staffNames.join(', '),
    ));
  }

  /// FE-02: Reject a request with reason
  void rejectRequest(String id, String reason, {String? template}) {
    final request = repairsNotifier.value.firstWhere((r) => r.id == id);
    updateRequest(request.copyWith(
      status: 'Denied',
      statusColor: Colors.red,
      rejectionReason: reason,
      rejectionTemplate: template,
    ));
  }

  /// FE-03: Technician starts work
  void startWork(String id) {
    final request = repairsNotifier.value.firstWhere((r) => r.id == id);
    updateRequest(request.copyWith(
      status: 'In Progress',
      statusColor: Colors.blue,
      workStartTime: DateTime.now(),
    ));
  }

  /// FE-03: Technician completes work with report
  void completeWork(String id, {String? report, List<String>? photos}) {
    final request = repairsNotifier.value.firstWhere((r) => r.id == id);
    updateRequest(request.copyWith(
      status: 'Completed',
      statusColor: Colors.green,
      completionDate: DateTime.now(),
      techReport: report,
      techReportPhotos: photos ?? [],
    ));
  }

  // ── Team Preset Methods ──

  void addTeamPreset(
      {required String name,
      required List<String> memberNames,
      IconData icon = Icons.folder_rounded}) {
    final preset = TeamPreset(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      memberNames: memberNames,
      icon: icon,
    );
    teamPresetsNotifier.value = [...teamPresetsNotifier.value, preset];
  }

  void deleteTeamPreset(String id) {
    teamPresetsNotifier.value =
        teamPresetsNotifier.value.where((p) => p.id != id).toList();
  }
}
