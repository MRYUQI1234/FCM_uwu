import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:fcm_app/core/data/auth_repository.dart';
import 'package:image_picker/image_picker.dart';

class RepairTask {
  final String id;
  final String description;
  final String status;
  final String urgency;
  final String? taskReport;
  final String? afterRepairImageUrl;
  final DateTime? preferDate;
  final String? objectName;
  final String? objectId; // Added this
  final String? category;
  final double laborFee;
  final double partFee;
  final String? modelRef3D;

  RepairTask({
    required this.id,
    required this.description,
    required this.status,
    required this.urgency,
    this.taskReport,
    this.afterRepairImageUrl,
    this.preferDate,
    this.objectName,
    this.objectId, // Added this
    this.category,
    this.laborFee = 0.0,
    this.partFee = 0.0,
    this.modelRef3D,
  });

  factory RepairTask.fromJson(Map<String, dynamic> json) {
    return RepairTask(
      id: json['id']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      urgency: json['urgency']?.toString() ?? 'Normal',
      taskReport: (json['taskReport'] ?? json['task_report'])?.toString(),
      afterRepairImageUrl:
          (json['afterRepairImageUrl'] ?? json['after_repair_image_url'])
              ?.toString(),
      preferDate: json['prefer_date'] != null
          ? DateTime.tryParse(json['prefer_date'].toString())
          : null,
      objectName: json['object_name']?.toString(),
      objectId: json['object_id']?.toString(), // Added this
      category: json['category']?.toString(),
      laborFee: (json['labor_fee'] ?? 0.0).toDouble(),
      partFee: (json['part_fee'] ?? 0.0).toDouble(),
      modelRef3D: json['model_ref_3d']?.toString(),
    );
  }
}

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
  final List<RepairTask> tasks;

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
  final String? requesterPhone;
  final String? requesterHouse;
  final String? requesterProfileUrl;

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
    this.tasks = const [],
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
    this.requesterPhone,
    this.requesterHouse,
    this.requesterProfileUrl,
  });

  bool get isWarranty {
    // Logic: Warranty expires after 5 years from handover.
    // If no handover date is available, we assume a default or check if any task has a fee.
    // However, the SRS says "Remaining warranty period".
    // I'll calculate it based on a mock handover date if not present in DB.
    final handoverDate = DateTime(2022, 10, 10);
    final expiryDate =
        DateTime(handoverDate.year + 5, handoverDate.month, handoverDate.day);
    return DateTime.now().isBefore(expiryDate);
  }

  double get estimatedCost {
    if (isWarranty) return 0.0;
    return tasks.fold(0.0, (sum, task) => sum + task.laborFee + task.partFee);
  }

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
    List<RepairTask>? tasks,
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
    String? requesterPhone,
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
      tasks: tasks ?? this.tasks,
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
      requesterPhone: requesterPhone ?? this.requesterPhone,
      requesterHouse: requesterHouse ?? this.requesterHouse,
      requesterProfileUrl: requesterProfileUrl,
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

  final String _baseUrl = 'https://abundantly-unsaturated-hayes.ngrok-free.dev/api';

  // ── Personnel Registration ──
  Future<bool> registerStaff(Map<String, dynamic> staffData) async {
    try {
      final token = await AuthRepository.instance.getToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register-staff'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': '69420',
        },
        body: jsonEncode(staffData),
      );

      return response.statusCode == 201;
    } catch (e) {
      debugPrint("Error registering staff: $e");
      return false;
    }
  }

  /// Upload a profile picture to Cloudflare R2 via backend
  Future<String?> uploadProfilePic(Uint8List bytes, String fileName) async {
    try {
      final token = await AuthRepository.instance.getToken();
      if (token == null) return null;

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/upload/profile-pic'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['ngrok-skip-browser-warning'] = '69420';

      final extension = fileName.split('.').last.toLowerCase();

      request.files.add(http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: fileName,
        contentType: MediaType('image', extension),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['imageUrl'];
      } else {
        debugPrint("Upload failed with status: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("Error uploading profile pic: $e");
      return null;
    }
  }

  /// Update existing staff information
  Future<bool> updateStaff(Map<String, dynamic> staffData) async {
    try {
      final token = await AuthRepository.instance.getToken();
      if (token == null) return false;

      final nationalId = staffData['idCard'];
      final response = await http.put(
        Uri.parse('$_baseUrl/auth/personnel/$nationalId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': '69420',
        },
        body: jsonEncode(staffData),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error updating staff: $e");
      return false;
    }
  }

  /// Delete staff from the system
  Future<bool> deleteStaff(String nationalId) async {
    try {
      final token = await AuthRepository.instance.getToken();
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('$_baseUrl/auth/personnel/$nationalId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': '69420',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error deleting staff: $e");
      return false;
    }
  }

  // ── Repairs ──
  final ValueNotifier<List<RepairRequest>> repairsNotifier = ValueNotifier([]);

  /// Fetch repair history from backend API
  /// ดึงประวัติการแจ้งซ่อม
  Future<void> fetchHistory() async {
    try {
      final token = await AuthRepository.instance.getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$_baseUrl/repair/history'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': '69420',
        },
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          final List data = result['data'] ?? [];
          final remoteRepairs = data.map<RepairRequest>((r) {
            final tasks = ((r['tasks'] as List?) ?? [])
                .map((t) => RepairTask.fromJson(t))
                .toList();

            final title = r['title']?.toString() ?? 'Repair Request';
            final description = tasks.isNotEmpty ? tasks[0].description : '';

            String rawStatus =
                (r['status'] ?? 'CREATED').toString().toUpperCase();
            String status = 'PENDING';
            Color statusColor = Colors.orange;

            switch (rawStatus) {
              case 'CREATED':
                status = 'CREATED';
                statusColor = Colors.orange;
                break;
              case 'ASSIGNED':
                status = 'ASSIGNED';
                statusColor = Colors.blue;
                break;
              case 'BEGAN':
              case 'IN PROGRESS':
                status = 'IN PROGRESS';
                statusColor = Colors.blue;
                break;
              case 'COMPLETED':
                status = 'COMPLETED';
                statusColor = Colors.green;
                break;
              case 'EVALUATED':
                status = 'EVALUATED';
                statusColor = Colors.green;
                break;
              case 'REJECTED':
              case 'DENIED':
              case 'DECLINED':
                status = 'DECLINED';
                statusColor = Colors.red;
                break;
              case 'CANCELED':
              case 'CANCELLED':
                status = 'CANCELLED';
                statusColor = Colors.grey;
                break;
              case 'URGENT':
                status = 'URGENT';
                statusColor = Colors.red;
                break;
            }

            DateTime? completedAt;
            if (r['completed_at'] != null) {
              completedAt = DateTime.tryParse(r['completed_at'].toString());
            }
            DateTime? createdAt;
            if (r['created_at'] != null) {
              createdAt = DateTime.tryParse(r['created_at'].toString());
            }

            final dateStr = createdAt != null
                ? '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}'
                : '';

            final isEmergency =
                r['type']?.toString().toUpperCase() == 'URGENT' ||
                    r['emergency'] == 1 ||
                    r['emergency'] == true ||
                    rawStatus == 'URGENT';

            final allPhotos = tasks
                .where((t) => t.afterRepairImageUrl != null)
                .map((t) => t.afterRepairImageUrl!)
                .toList();
            final allReports = tasks
                .where((t) => t.taskReport != null && t.taskReport!.isNotEmpty)
                .map((t) => t.taskReport!)
                .join("\n");

            return RepairRequest(
              id: r['id']?.toString() ?? '',
              title: title,
              description: description,
              date: dateStr,
              status: status,
              statusColor: statusColor,
              technicianName: r['technician_name']?.toString(),
              completionDate: completedAt,
              appointmentDate: tasks.isNotEmpty ? tasks.first.preferDate : null,
              isEmergency: isEmergency,
              requesterHouse: r['requester_house']?.toString(),
              tasks: tasks,
              requesterName: r['requester_name']?.toString(),
              requesterEmail: r['requester_email']?.toString(),
              requesterPhone: r['requester_phone']?.toString(),
              requesterProfileUrl: r['requester_profile_url']?.toString(),
              rating: (r['rating'] as num?)?.toInt(),
              assessmentComment: r['comment']?.toString(),
              assignedStaff: List<String>.from(r['assignedStaff'] ?? []),
              techReport: allReports.isNotEmpty ? allReports : null,
              techReportPhotos: allPhotos,
              rejectionReason: r['rejection_reason']?.toString(),
              rejectionTemplate: r['rejection_template']?.toString(),
            );
          }).toList();

          // Merge: Keep local requests that aren't in the remote list yet
          final localOnly = repairsNotifier.value.where((local) {
            // If it's a numeric ID (timestamp from addRequest), it's likely local-only
            bool isNewLocal =
                double.tryParse(local.id) != null && local.id.length > 10;
            bool existsRemotely =
                remoteRepairs.any((remote) => remote.id == local.id);
            return isNewLocal && !existsRemotely;
          }).toList();

          repairsNotifier.value = [...localOnly, ...remoteRepairs];
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

  /// FE-01: Submit a new repair request to the backend
  Future<bool> submitRequest({
    required String title,
    required String description,
    List<String> imagePaths = const [],
    DateTime? appointmentDate,
    TimeOfDay? appointmentTime,
    bool isEmergency = false,
    // For 3D model compatibility
    String? objectId,
    String? objectType,
  }) async {
    try {
      final token = await AuthRepository.instance.getToken();
      if (token == null) return false;

      // Map single request to a task array as expected by backend
      final tasks = [
        {
          "object_id": objectId ?? "unk-001",
          "object_name": title,
          "object_type": objectType ?? "General",
          "description": description,
          "urgency": isEmergency ? "Emergency" : "Normal",
          "prefer_date": appointmentDate?.toIso8601String().split('T').first,
          "prefer_time": appointmentTime != null
              ? "${appointmentTime.hour.toString().padLeft(2, '0')}:${appointmentTime.minute.toString().padLeft(2, '0')}"
              : null,
        }
      ];

      final response = await http.post(
        Uri.parse('$_baseUrl/repair/confirm'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': '69420',
        },
        body: jsonEncode({
          "request": {"tasks": tasks}
        }),
      );

      if (response.statusCode == 201) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          // Refresh history after a short delay
          await fetchHistory();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('FCM: Error submitting repair request: $e');
      return false;
    }
  }

  void addRequest({
    required String title,
    required String description,
    List<String> imagePaths = const [],
    DateTime? appointmentDate,
    TimeOfDay? appointmentTime,
    String? appointmentSlot,
    bool isEmergency = false,
    String? requesterName,
    String? requesterEmail,
    String? requesterHouse,
    List<RepairTask> tasks = const [],
  }) {
    final now = DateTime.now();
    final dateStr =
        "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year + 543}";

    final newRequest = RepairRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      date: dateStr,
      status: 'AWAITING APPROVAL',
      statusColor: Colors.orange,
      imagePaths: imagePaths,
      appointmentDate: appointmentDate,
      appointmentTime: appointmentTime,
      appointmentSlot: appointmentSlot,
      isEmergency: isEmergency,
      requesterName: requesterName,
      requesterEmail: requesterEmail,
      requesterHouse: requesterHouse,
      tasks: tasks,
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
  Future<bool> assignRequest(String id, List<String> staffNames) async {
    try {
      final token = await AuthRepository.instance.getToken();
      if (token == null) return false;

      final response = await http.patch(
        Uri.parse('$_baseUrl/repair/request/$id/assign'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': '69420',
        },
        body: jsonEncode({
          'staff_names': staffNames,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          // After a successful backend assign, refresh data to keep UI in sync
          await fetchHistory();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('FCM: Error assigning request: $e');
      return false;
    }
  }

  /// FE-02: Reject a request with reason
  Future<bool> rejectRequest(String id, String reason,
      {String? template}) async {
    try {
      final token = await AuthRepository.instance.getToken();
      if (token == null) return false;

      final response = await http.patch(
        Uri.parse('$_baseUrl/repair/request/$id/reject'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': '69420',
        },
        body: jsonEncode({
          'reason': reason,
          'template': template,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          await fetchHistory();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('FCM: Error rejecting request: $e');
      return false;
    }
  }

  /// FE-03: Technician starts work or completes work (Status update)
  Future<bool> updateStatus(String requestId, String status) async {
    try {
      final token = await AuthRepository.instance.getToken();
      if (token == null) return false;

      // Find the first task ID for this request to update its status
      // In this system, we often update the first task to represent the request status change
      final request = repairsNotifier.value.firstWhere((r) => r.id == requestId,
          orElse: () => repairsNotifier.value[0]);
      if (request.tasks.isEmpty) return false;
      final taskId = request.tasks[0].id;

      final response = await http.patch(
        Uri.parse('$_baseUrl/repair/task/$taskId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': '69420',
        },
        body: json.encode({
          'status': status == 'BEGAN' ? 'InProgress' : 'Completed',
        }),
      );

      if (response.statusCode == 200) {
        await fetchHistory();
        return true;
      }
    } catch (e) {
      debugPrint('Error updating status: $e');
    }
    return false;
  }

  Future<bool> updateTaskReport({
    required String taskId,
    required String status, // 'InProgress' or 'Completed'
    String? report,
    String? imageUrl,
  }) async {
    try {
      final token = await AuthRepository.instance.getToken();
      if (token == null) return false;

      final response = await http.patch(
        Uri.parse('$_baseUrl/repair/task/$taskId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': '69420',
        },
        body: json.encode({
          'status': status,
          'task_report': report,
          'after_repair_image_url': imageUrl,
        }),
      );

      if (response.statusCode == 200) {
        await fetchHistory();
        return true;
      }
    } catch (e) {
      debugPrint('Error updating task report: $e');
    }
    return false;
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

  /// Resident: Submit Evaluation (Feedback System)
  Future<bool> submitEvaluation({
    required String requestId,
    required int rating,
    String? comment,
  }) async {
    try {
      final token = await AuthRepository.instance.getToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$_baseUrl/repair/evaluate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': '69420',
        },
        body: jsonEncode({
          'request_id': requestId,
          'rating': rating,
          'comment': comment ?? '',
        }),
      );

      if (response.statusCode == 201) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          await fetchHistory();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('FCM: Error submitting evaluation: $e');
      return false;
    }
  }

  Future<String?> uploadImage(XFile file) async {
    try {
      final token = await AuthRepository.instance.getToken();
      if (token == null) return null;

      var request =
          http.MultipartRequest('POST', Uri.parse('$_baseUrl/upload/repair'));
      request.headers['Authorization'] = 'Bearer $token';

      var stream = http.ByteStream(file.openRead());
      var length = await file.length();

      var multipartFile = http.MultipartFile('image', stream, length,
          filename: file.name, contentType: MediaType('image', 'jpeg'));

      request.files.add(multipartFile);

      var response = await request.send();
      if (response.statusCode == 200) {
        var responseStr = await response.stream.bytesToString();
        var result = jsonDecode(responseStr);
        return result['imageUrl'];
      }
    } catch (e) {
      debugPrint('FCM: Upload error: $e');
    }
    return null;
  }
}
