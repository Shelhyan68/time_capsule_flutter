import 'package:cloud_firestore/cloud_firestore.dart';
import '../presentation/models/capsule_model.dart';

class CapsuleService {
  final FirebaseFirestore firestore;

  CapsuleService({required this.firestore});

  Stream<List<CapsuleModel>> getCapsules() {
    return firestore
        .collection('capsules')
        .orderBy('openDate')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => CapsuleModel.fromDoc(doc)).toList(),
        );
  }
}
