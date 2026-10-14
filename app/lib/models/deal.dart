import 'package:cloud_firestore/cloud_firestore.dart';

class DealRecord {
  final String id;
  final String itemId;
  final String itemTitle;
  final DateTime createdAt;
  final bool isGiven;
  final String counterpartName;

  const DealRecord({
    required this.id,
    required this.itemId,
    required this.itemTitle,
    required this.createdAt,
    required this.isGiven,
    required this.counterpartName,
  });

  factory DealRecord.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String currentUserId,
  ) {
    final data = doc.data()!;
    final isGiven = data['giverId'] == currentUserId;
    return DealRecord(
      id: doc.id,
      itemId: data['itemId'] as String,
      itemTitle: data['itemTitle'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isGiven: isGiven,
      counterpartName:
          (isGiven ? data['receiverName'] : data['giverName']) as String? ?? '',
    );
  }
}
