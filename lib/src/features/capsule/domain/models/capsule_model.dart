import 'package:cloud_firestore/cloud_firestore.dart';

class CapsuleModel {
  final String id;
  final String title;
  final String? letter;
  final List<String> mediaUrls;
  final DateTime openDate;

  CapsuleModel({
    required this.id,
    required this.title,
    this.letter,
    this.mediaUrls = const [],
    required this.openDate,
  });

  factory CapsuleModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CapsuleModel(
      id: doc.id,
      title: data['title'] ?? '',
      openDate: (data['openDate'] as Timestamp).toDate(),
      mediaUrls: List<String>.from(data['mediaUrls'] ?? []),
      letter: data['letter'],
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'openDate': Timestamp.fromDate(openDate),
    'mediaUrls': mediaUrls,
    'letter': letter,
  };

  Map<String, dynamic> toFirestore() => toMap();
}
