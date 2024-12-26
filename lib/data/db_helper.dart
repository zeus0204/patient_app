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
    final querySnapshot = await _firestore
    .collection('patients')
    .where('email', isEqualTo: email)
    .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.data();
    } else {
      return null;
    }
  }

  // Update Patients information
  Future<void> updatePatients({
    required String email,
    String? fullName,
    String? phoneNumber,
  }) async {
      try {
      final querySnapshot = await _firestore
          .collection('patients')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        for (var doc in querySnapshot.docs) {
          await doc.reference.update({
            if (fullName != null) 'fullName': fullName,
            if (phoneNumber != null) 'phoneNumber': phoneNumber,
          });
        }
      } else {
        throw Exception('No patient found with email $email');
      }
    } catch (e) {
      throw Exception('Failed to update patient: $e');
    }
  }

  // Manage Patients info
  Future<void> updatePatientsInfo({
    required String email,
    String? address,
    String? contact,
    DateTime? birthday,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('patients')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        for (var doc in querySnapshot.docs) {
          await doc.reference.set({
            'patients_info': {
              if (address != null) 'address': address,
              if (contact != null) 'contact': contact,
              if (birthday != null) 'birthday': birthday.toIso8601String(),
            }
          }, SetOptions(merge: true));
        }
      } else {
        throw Exception('No patient info found with email $email');
      }
    } catch (e) {
      throw Exception('Failed to upsert Patients info: $e');
    }
  }

  // Insert medical history
  Future<void> insertMedicalHistory(String email, Map<String, dynamic> medicalHistory) async {
    try {
      final querySnapshot = await _firestore
          .collection('patients')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        for (var doc in querySnapshot.docs) {
          // Use arrayUnion to add the new medicalHistory to the existing list
          await doc.reference.update({
            'medical_history': FieldValue.arrayUnion([medicalHistory])
          });
        }
      } else {
        throw Exception('No patient info found with email $email');
      }
    } catch (e) {
      throw Exception('Failed to upsert Patients info: $e');
    }
  }

  Future<void> updateMedicalHistory(String email, String recordTitle, Map<String, dynamic> updatedData) async {
    try {
      final querySnapshot = await _firestore
          .collection('patients')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        List<dynamic> medicalHistory = doc['medical_history'] ?? [];

        // Find index of the record with the matching title
        int recordIndex = medicalHistory.indexWhere((record) => record['title'] == recordTitle);

        if (recordIndex != -1) {
          // Update the specific record's data
          medicalHistory[recordIndex] = updatedData;

          // Update the document with the modified medical history array
          await doc.reference.update({'medical_history': medicalHistory});
        } else {
          throw Exception('No medical history record found with title $recordTitle');
        }
      } else {
        throw Exception('No patient found with email $email');
      }
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
  Future<List<Map<String, dynamic>>> getMedicalHistoryByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('patients')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Assuming there's only one document per unique email
        final doc = querySnapshot.docs.first;
        final medicalHistory = doc['medical_history'] ?? [];

        if (medicalHistory is List) {
          return medicalHistory.map((item) => Map<String, dynamic>.from(item)).toList();
        }
      }

      return []; // Return an empty list if no medical history found
    } catch (e) {
      throw Exception('Failed to fetch medical history: $e');
    }
  }


  Future<Map<String, dynamic>?> getPatientsInfoByEmail(String email) async {
    try {
      // Query the 'patients' collection for a document where the 'email' field matches the given email
      final querySnapshot = await _firestore
          .collection('patients')
          .where('email', isEqualTo: email)
          .get();
      
      // Check if any documents were found
      if (querySnapshot.docs.isNotEmpty) {
        // Assuming each email is unique, take the first match
        final doc = querySnapshot.docs.first;
        // Retrieve the 'patients_info' field from the document
        return doc.data()['patients_info'] as Map<String, dynamic>?;
      } else {
        // Return null if no document was found
        return null;
      }
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
