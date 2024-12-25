import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:patient_app/data/model/Appointment.dart';

class DBHelper {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Insert Patients data
  Future<void> insertPatients(Map<String, dynamic> patientsData) async {
    try {
      var result = await _firestore.collection('patients').where('email', isEqualTo: patientsData['email']).get();
      if (result.docs.isNotEmpty) {
        throw Exception('Email already exists. Please use a different email');
      }
      await _firestore.collection('patients').add(patientsData);
    } catch (e) {
      throw Exception('An error occurred while inserting the Patients');
    }
  }

  // Get all patients
  Future<List<Map<String, dynamic>>> getAllpatients() async {
    try {
      final querySnapshot = await _firestore.collection('patients').get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to fetch patients: $e');
    }
  }

  // Check if email exists
  Future<bool> emailExists(String email) async {
    try {
      final docSnapshot = await _firestore.collection('patients').doc(email).get();
      return docSnapshot.exists;
    } catch (e) {
      throw Exception('Error checking email existence: $e');
    }
  }

  // Get patients by email
  Future<Map<String, dynamic>?> getPatientsByEmail(String email) async {
    try {
      final docSnapshot = await _firestore.collection('patients').doc(email).get();
      return docSnapshot.exists ? docSnapshot.data() : null;
    } catch (e) {
      throw Exception('Failed to fetch Patients by email: $e');
    }
  }

  // Update Patients information
  Future<void> updatePatients({
    required String email,
    String? fullName,
    String? phoneNumber,
  }) async {
    Map<String, dynamic> updatedPatientsData = {};
    if (fullName != null) updatedPatientsData['fullName'] = fullName;
    if (phoneNumber != null) updatedPatientsData['phoneNumber'] = phoneNumber;

    if (updatedPatientsData.isNotEmpty) {
      try {
        await _firestore.collection('patients').doc(email).update(updatedPatientsData);
      } catch (e) {
        throw Exception('Failed to update Patients: $e');
      }
    }
  }

  // Manage Patients info
  Future<void> updatePatientsInfo({
    required String email,
    String? address,
    String? contact,
    DateTime? birthday,
  }) async {
    Map<String, dynamic> updatedPatientsInfoData = {};
    if (address != null) updatedPatientsInfoData['address'] = address;
    if (contact != null) updatedPatientsInfoData['contact'] = contact;
    if (birthday != null) updatedPatientsInfoData['birthday'] = birthday.toIso8601String();

    if (updatedPatientsInfoData.isNotEmpty) {
      try {
        await _firestore.collection('patients_info').doc(email).set(
          {'email': email, ...updatedPatientsInfoData},
          SetOptions(merge: true),
        );
      } catch (e) {
        throw Exception('Failed to upsert Patients info: $e');
      }
    }
  }

  // Insert medical history
  Future<void> insertMedicalHistory(String email, Map<String, dynamic> medicalHistory) async {
    try {
      await _firestore.collection('patients').doc(email)
          .collection('medical_history').add(medicalHistory);
    } catch (e) {
      throw Exception('Failed to insert medical history: $e');
    }
  }

  Future<void> updateMedicalHistory(String email, String recordId, Map<String, dynamic> updatedData) async {
    try {
      await _firestore.collection('patients').doc(email)
          .collection('medical_history').doc(recordId).update(updatedData);
    } catch (e) {
      throw Exception('Failed to update medical history: $e');
    }
  }

  Future<void> deleteMedicalHistory(String email, String recordId) async {
    try {
      await _firestore.collection('patients').doc(email)
          .collection('medical_history').doc(recordId).delete();
    } catch (e) {
      throw Exception('Failed to delete medical history: $e');
    }
  }

  // Fetch medical history
  Future<List<Map<String, dynamic>>> getMedicalHistoryByPatientsId(String email) async {
    try {
      final querySnapshot = await _firestore.collection('patients').doc(email)
          .collection('medical_history').get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to fetch medical history: $e');
    }
  }

  Future<Map<String, dynamic>?> getPatientsInfoByPatientsId(String patientsId) async {
    try {
      final docRef = _firestore.collection('patients_info').doc(patientsId);
      final doc = await docRef.get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      rethrow;
    }
  }

  Future<int?> getPatientIdByEmail(String email) async {
    try {
      // Get a reference to the Firestore instance
      final firestore = FirebaseFirestore.instance;

      // Query the 'users' collection where the 'email' field matches the given email
      final querySnapshot = await firestore
          .collection('patients')
          .where('email', isEqualTo: email)
          .limit(1) // Limit to 1 result since emails are unique
          .get();

      // Check if any documents were returned
      if (querySnapshot.docs.isNotEmpty) {
        // Extract the 'id' from the first document; ensure it is a number
        return querySnapshot.docs.first.data()['id'] as int?;
      }
    } catch (e) {
      print('Failed to get user ID by email: $e');
    }

    // Return null if no matching document was found or an error occurred
    return null;
  }

  Future<List<Appointment>> getAppointmentsByPatientId(String patientId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('appointments')
          .where('patient_id', isEqualTo: patientId)
          .get();

      return querySnapshot.docs.map((doc) =>
          Appointment.fromMap(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Error fetching appointments: $e');
    }
  }

  Future<void> deleteAppointment(String appointmentId) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).delete();
    } catch (e) {
      throw Exception('Error deleting appointment: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAppointmentsById(String id) async {
    try {
      // Access Firestore instance
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Query Firestore collection to find appointments matching the given ID
      QuerySnapshot querySnapshot = await firestore
          .collection('appointments')
          .where(FieldPath.documentId, isEqualTo: id)
          .get();

      // Convert the query snapshot into a list of maps
      return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Error fetching appointment by ID: $e');
    }
  }

  Future<void> insertAppointment(Map<String, dynamic> appointmentData) async {
    try {
      await _firestore.collection('appointments').add(appointmentData);
    } catch (e) {
      throw Exception('Error inserting appointment: $e');
    }
  }

  Future<void> updateAppointment(String id, Map<String, dynamic> updatedData) async {
    try {
      await _firestore.collection('appointments').doc(id).update(updatedData);
    } catch (e) {
      throw Exception('Error updating appointment: $e');
    }
  }
}
