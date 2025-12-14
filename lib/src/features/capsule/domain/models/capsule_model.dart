import 'package:cloud_firestore/cloud_firestore.dart';

class CapsuleModel {
  final String id;
  final String title;
  final String? letter;
  final List<String> mediaUrls;
  final DateTime openDate;
  final String? recipientName;
  final String? recipientEmail;
  final String userId;

  CapsuleModel({
    required this.id,
    required this.title,
    this.letter,
    this.mediaUrls = const [],
    required this.openDate,
    this.recipientName,
    this.recipientEmail,
    required this.userId,
  });

  factory CapsuleModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CapsuleModel(
      id: doc.id,
      title: data['title'] ?? '',
      openDate: (data['openDate'] as Timestamp).toDate(),
      mediaUrls: List<String>.from(data['mediaUrls'] ?? []),
      letter: data['letter'],
      recipientName: data['recipientName'],
      recipientEmail: data['recipientEmail'],
      userId: data['userId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'openDate': Timestamp.fromDate(openDate),
    'mediaUrls': mediaUrls,
    'letter': letter,
    'recipientName': recipientName,
    'recipientEmail': recipientEmail,
    'userId': userId,
  };

  Map<String, dynamic> toFirestore() => toMap();
}
