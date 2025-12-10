import 'package:cloud_firestore/cloud_firestore.dart';

class CapsuleModel {
  final String id;
  final String title;
  final DateTime openDate;
  final List<String> mediaUrls;

  CapsuleModel({
    required this.id,
    required this.title,
    required this.openDate,
    required this.mediaUrls,
  });

  factory CapsuleModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CapsuleModel(
      id: doc.id,
      title: data['title'] ?? '',
      openDate: (data['openDate'] as Timestamp).toDate(),
      mediaUrls: List<String>.from(data['mediaUrls'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'openDate': Timestamp.fromDate(openDate),
    'mediaUrls': mediaUrls,
  };
}
