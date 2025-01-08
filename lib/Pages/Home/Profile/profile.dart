import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting

import '../../../data/db_helper.dart';
import '../../../data/session.dart';  
import '../../../data/model/User.dart';
import 'edit_profile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? _user; // Store user details  
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();
  String? _imagePath;
  List<Map<String, dynamic>> _records = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      String? email = await SessionManager.getUserSession();
      if (email != null) {
        Map<String, dynamic>? userData = await DBHelper().getPatientsByEmail(email);
        if (userData != null) {
          setState(() {
            _user = User.fromMap(userData);
          });
          _fetchRecords(email);
        }
      }
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchRecords(String email) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('records')
          .where('patientEmail', isEqualTo: email)
          .get();

      setState(() {
        _records =
            querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      });
    } catch (e) {
      // Handle error
    }
  }

  Widget _buildMedicalRecordSection(String title, List<Map<String, dynamic>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color.fromRGBO(33, 158, 80, 1),
          ),
        ),
        const SizedBox(height: 12),
        Expanded( // Wrap ListView in Expanded to take available space
          child: ListView.builder(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(), // Use a scrollable physics
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              var timestamp = item['time'];
              String formattedTime = 'N/A';
              if (timestamp != null && timestamp is Timestamp) {
                DateTime dateTime = timestamp.toDate();
                formattedTime = DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
              }
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 2,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  title: Text(
                    item['title'] ?? 'N/A',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: FutureBuilder<String>(
                    future: getDoctornameByEmail(item['doctorEmail']),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white), // Set loading indicator color to white
                          ),
                        ); // Show loading indicator while waiting
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['subtitle'] ?? 'N/A'),
                            Text(item['description'] ?? 'N/A'),
                            Text(snapshot.data ?? 'Unknown Doctor'), // Display doctor name
                            Text(formattedTime),
                          ],
                        );
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<String> getDoctornameByEmail(String doctorEmail) async {
    Map<String, dynamic>? userData = await DBHelper().getDoctorByEmail(doctorEmail);
    return userData?['fullName'] ?? 'Unknown Doctor';
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imagePath = pickedFile.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white), // Set loading indicator color to white
                    ),
                  )
          : _user == null
              ? const Center(child: Text("No user data found"))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 30),
                      const Text(
                        'Patient',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 127,
                              height: 126,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: _imagePath != null
                                      ? FileImage(File(_imagePath!))
                                      : const AssetImage('assets/images/avatar.png') as ImageProvider,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: IconButton(
                                icon: const Icon(Icons.edit, color: Colors.white),
                                onPressed: _pickImage,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      Column(
                        children: [
                          const Text(
                            'Full Name',
                            style: TextStyle(color: Colors.grey),
                          ),
                          Text(
                            _user!.fullName ?? 'Full Name',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'E-mail Address',
                            style: TextStyle(color: Colors.grey),
                          ),
                          Text(
                            _user!.email ?? 'E-mail Address',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Phone Number',
                            style: TextStyle(color: Colors.grey),
                          ),
                          Text(
                            _user!.phoneNumber ?? 'Phone Number',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const EditProfile()),
                            ).then((result) {
                              if (result == true) {
                                _loadUserData();
                              }
                            });
                          },
                          child: const Text(
                            'Edit Details',
                            style: TextStyle(color: Colors.green),
                          ),
                        ),
                      ),
                      Expanded(
                        child: _buildMedicalRecordSection(
                          'Medical Records',
                          _records,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
