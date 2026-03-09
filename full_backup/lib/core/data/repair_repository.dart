import 'package:flutter/material.dart';

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

  // ── Repairs ──
  final ValueNotifier<List<RepairRequest>> repairsNotifier = ValueNotifier([
    RepairRequest(
      id: '1',
      title: 'Air Conditioner leaking',
      description: 'Water is dripping from the indoor unit onto the floor.',
      date: '02/03/2569',
      status: 'In Progress',
      statusColor: Colors.blue,
      technicianName: 'Somsak',
      assignedStaff: ['Jib'],
      appointmentDate: DateTime.now().add(const Duration(days: 1)),
      appointmentTime: const TimeOfDay(hour: 10, minute: 30),
      appointmentSlot: 'AM',
      requesterName: 'Resident A',
      requesterEmail: 'resident@gmail.com',
      requesterHouse: 'UNIT-B12',
    ),
  ]);

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
    final dateStr = "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year + 543}";
    
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
    repairsNotifier.value = repairsNotifier.value.where((item) => item.id != id).toList();
  }

  void updateRequest(RepairRequest updatedItem) {
    final index = repairsNotifier.value.indexWhere((item) => item.id == updatedItem.id);
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

  void addTeamPreset({required String name, required List<String> memberNames, IconData icon = Icons.folder_rounded}) {
    final preset = TeamPreset(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      memberNames: memberNames,
      icon: icon,
    );
    teamPresetsNotifier.value = [...teamPresetsNotifier.value, preset];
  }

  void deleteTeamPreset(String id) {
    teamPresetsNotifier.value = teamPresetsNotifier.value.where((p) => p.id != id).toList();
  }
}
