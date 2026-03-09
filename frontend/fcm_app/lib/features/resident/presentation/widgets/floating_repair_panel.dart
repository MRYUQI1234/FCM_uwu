import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fcm_app/core/data/repair_repository.dart';

class PendingRepairItem {
  final String id;
  final String name;
  final String? imagePath;

  PendingRepairItem({required this.id, required this.name, this.imagePath});
}

class FloatingRepairPanel extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onSubmit;
  final List<PendingRepairItem> pendingItems;
  final Function(String id) onRemoveItem;

  const FloatingRepairPanel({
    super.key,
    required this.onClose,
    required this.onSubmit,
    required this.pendingItems,
    required this.onRemoveItem,
  });

  @override
  State<FloatingRepairPanel> createState() => _FloatingRepairPanelState();
}

class _FloatingRepairPanelState extends State<FloatingRepairPanel> {
  int _requestNumber = 4; // Mock request number

  void _submitRepair() {
    if (widget.pendingItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('กรุณาคลิกที่วัตถุบนโมเดล 3D เพื่อเพิ่มรายการ', style: GoogleFonts.kanit()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Add each item to RepairRepository
    for (var item in widget.pendingItems) {
      RepairRepository.instance.addRequest(title: item.name, description: item.name, imagePaths: item.imagePath != null ? [item.imagePath!] : []);
    }

    widget.onSubmit();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ส่งแจ้งซ่อม ${widget.pendingItems.length} รายการเรียบร้อย!', style: GoogleFonts.kanit()),
        backgroundColor: const Color(0xFFC5A059),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC5A059).withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF252525),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.assignment, color: Color(0xFFC5A059)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'คำขอแจ้งซ่อมหมายเลข $_requestNumber',
                    style: GoogleFonts.kanit(
                      color: const Color(0xFFC5A059),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                  onPressed: widget.onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Instructions
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF252525),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFC5A059).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.touch_app, color: Color(0xFFC5A059), size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'คลิกที่วัตถุบนโมเดล 3D\nเพื่อเพิ่มรายการแจ้งซ่อม',
                          style: GoogleFonts.kanit(color: Colors.grey[400], fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Items Label
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'รายการ',
                      style: GoogleFonts.kanit(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      '${widget.pendingItems.length} รายการ',
                      style: GoogleFonts.kanit(color: const Color(0xFFC5A059), fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Items List
                Container(
                  constraints: const BoxConstraints(maxHeight: 250),
                  decoration: BoxDecoration(
                    color: const Color(0xFF252525),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: widget.pendingItems.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.inbox_outlined, color: Colors.grey[600], size: 48),
                                const SizedBox(height: 8),
                                Text(
                                  'ยังไม่มีรายการ',
                                  style: GoogleFonts.kanit(color: Colors.grey[600], fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(8),
                          itemCount: widget.pendingItems.length,
                          separatorBuilder: (_, __) => const Divider(color: Colors.grey, height: 1),
                          itemBuilder: (context, index) {
                            final item = widget.pendingItems[index];
                            return ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                              leading: const Icon(Icons.handyman, color: Color(0xFFC5A059), size: 20),
                              title: Text(
                                item.name,
                                style: GoogleFonts.kanit(color: Colors.white, fontSize: 13),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                onPressed: () => widget.onRemoveItem(item.id),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submitRepair,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC5A059),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('แจ้งซ่อม', style: GoogleFonts.kanit(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onClose,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                      side: const BorderSide(color: Colors.grey),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('ยกเลิก', style: GoogleFonts.kanit()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
