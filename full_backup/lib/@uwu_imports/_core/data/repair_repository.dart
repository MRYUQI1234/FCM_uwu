import 'package:flutter/material.dart';

class RepairRequest {
  final String id;
  final String title;
  final String description; 
  final String date;
  final String status;
  final Color statusColor;
  final List<String> imagePaths; // Updated to List<String>
  final String? rejectionReason;
  
  // Assessment fields
  final DateTime? completionDate;
  final int? rating;
  final String? assessmentComment;
  final String? technicianName;

  RepairRequest({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.status,
    required this.statusColor,
    this.imagePaths = const [], // Updated
    this.rejectionReason,
    this.completionDate,
    this.rating,
    this.assessmentComment,
    this.technicianName,
  });
}

class RepairRepository {
  static final RepairRepository instance = RepairRepository._internal();
  RepairRepository._internal();

  final ValueNotifier<List<RepairRequest>> repairsNotifier = ValueNotifier([
     RepairRequest(
      id: '1',
      title: 'แอร์เสีย',
      description: 'แอร์ไม่เย็น มีลมร้อนออกมา',
      date: '5/1/2569',
      status: 'กำลังดำเนินการ',
      statusColor: Colors.blue,
    ),
    RepairRequest(
      id: '2',
      title: 'ท่อน้ำรั่ว',
      description: 'ท่อน้ำใต้ซิงค์ก๊อกน้ำรั่ว',
      date: '2/1/2569',
      status: 'รอดำเนินการ',
      statusColor: Colors.orange,
    ),
    RepairRequest(
      id: '3',
      title: 'ไฟดับ',
      description: 'ไฟในห้องนั่งเล่นดับทั้งหมด',
      date: '1/1/2569',
      status: 'เสร็จสิ้น',
      statusColor: Colors.green,
    ),
  ]);

  void addRequest(String title, List<String> imagePaths) { // Updated signature
    final now = DateTime.now();
    final dateStr = "${now.day}/${now.month}/${now.year + 543}";
    
    final newRequest = RepairRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: title,
      date: dateStr,
      status: 'รอดำเนินการ',
      statusColor: Colors.orange,
      imagePaths: imagePaths, // Updated
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
}
