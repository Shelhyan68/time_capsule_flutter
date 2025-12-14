import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/models/capsule_model.dart';

class CapsuleService {
  final FirebaseFirestore _firestore;

  CapsuleService({required FirebaseFirestore firestore})
    : _firestore = firestore;

  /// Récupère toutes les capsules de l'utilisateur courant
  /// Triées par date d'ouverture croissante
  Stream<List<CapsuleModel>> getCapsules() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return const Stream.empty();
      }
      return _firestore
          .collection('capsules')
          .where('userId', isEqualTo: user.uid)
          .orderBy('openDate')
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs.map((doc) => CapsuleModel.fromDoc(doc)).toList(),
          );
    } catch (e) {
      throw Exception('Erreur lors de la récupération des capsules: $e');
    }
  }

  /// Supprime une capsule par son ID
  Future<void> deleteCapsule(String capsuleId) async {
    try {
      await _firestore.collection('capsules').doc(capsuleId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la capsule: $e');
    }
  }

  /// Crée une nouvelle capsule
  Future<String> createCapsule(CapsuleModel capsule) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');
      final docRef = await _firestore
          .collection('capsules')
          .add(capsule.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création de la capsule: $e');
    }
  }

  /// Met à jour une capsule existante
  Future<void> updateCapsule(CapsuleModel capsule) async {
    try {
      await _firestore
          .collection('capsules')
          .doc(capsule.id)
          .update(capsule.toFirestore());
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la capsule: $e');
    }
  }
}
