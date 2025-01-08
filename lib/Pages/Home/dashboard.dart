import 'dart:async';

import 'package:flutter/material.dart';
import 'package:patient_app/Pages/Home/qr_code.dart';
import 'package:patient_app/data/db_helper.dart';
import 'package:patient_app/data/session.dart';
import 'package:patient_app/models/schedule.dart';
import 'package:patient_app/widgets/schedule_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>>? _medicalHistory = [];
  String? _fullName;
  String? _phoneNumber;
  String? _address;
  String? _contact;
  String? _dateOfBirth;
  String? _email;
  bool _isLoading = false;
  late AnimationController _animationController;
  List<Map<String, dynamic>> recentDocotors = [];
  bool _isFetchingRecords = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchDoctors();
    getLatestRecordsByPatientEmail(_email);
    _animationController = AnimationController(
      duration: const Duration(seconds: 1, milliseconds: 500), // 1.5 seconds duration
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose(); // Dispose the controller when not needed
    super.dispose();
  }

  final Map<String, dynamic> user = {
    'name': '',
    'age': 29,
  };

  Future<void> getLatestRecordsByPatientEmail(String? patientEmail) async {

    setState(() {
      _isFetchingRecords = true; // Start fetching
    });

    try {
      // Step 1: Query records matching the given patientEmail
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('records')
          .where('patientEmail', isEqualTo: patientEmail)
          .get();

      print("Number of records fetched: ${snapshot.docs.length}");
      if (snapshot.docs.isEmpty) {
        print("No records found for patientEmail: $patientEmail");
        return;
      }

      // Step 2: Process records to group by patientEmail and get the latest updatedAt
      Map<String, Map<String, dynamic>> latestRecords = {};

      for (var doc in snapshot.docs) {
        Map<String, dynamic> record = doc.data() as Map<String, dynamic>;
        String? doctorEmail = record['doctorEmail'] as String?;
        Timestamp? updatedAt = record['time'] as Timestamp?;

        // Skip records with null patientEmail or updatedAt
        if (doctorEmail == null || updatedAt == null) {
          print("Skipping record with missing data: $record");
          continue;
        }

        // Check if this record is more recent than the stored one
        if (!latestRecords.containsKey(doctorEmail) || 
            updatedAt.toDate().isAfter(
                (latestRecords[doctorEmail]!['time'] as Timestamp).toDate())) {
          latestRecords[doctorEmail] = record;
        }
      }

      // Debug latest records
      List<Map<String, dynamic>> sortedRecentDocotors = latestRecords.values.toList();
      sortedRecentDocotors.sort((a, b) {
        Timestamp timeA = a['time'] as Timestamp;
        Timestamp timeB = b['time'] as Timestamp;
        return timeB.compareTo(timeA); // Latest time first
      });

      // Step 3: Update state with the filtered records
      setState(() {
        recentDocotors = sortedRecentDocotors;
        _isFetchingRecords = false;
      });
    } catch (e) {
      print('Error fetching records: $e');
    }
  }

  void _onButtonPressed() {
    setState(() {
      _isLoading = true;
    });
    _animationController.repeat();
    Timer(Duration(seconds: 1, milliseconds: 500), () {
      setState(() {
        _isLoading = false;
      });
      _showSuccessMessage();
      _animationController.stop();
    });
  }
  
  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sync completed successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<String> getDoctorName(String? userEmail) async {
    List<Map<String, dynamic>> doctors = await DBHelper().getAllDoctors();
    if (userEmail == null) return 'Unknown Patient';
    final doctor = doctors.firstWhere(
      (doc) => doc['email'] == userEmail,
      orElse: () => {'fullName': 'Unknown Patient'},
    );
    return doctor['fullName'] ?? 'Unknown Patient';
  }

  Future<Map<String, dynamic>> getDoctorDetailsByEmail(String email) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('doctors')
          .where('email', isEqualTo: email)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data() as Map<String, dynamic>;
      } else {
        throw Exception('No patient found with email: $email');
      }
    } catch (e) {
      throw Exception('Failed to load patient data: $e');
    }
  }

  void _showDoctorInfo(BuildContext context, String email) async {
    try {
      Map<String, dynamic> doctorData = await getDoctorDetailsByEmail(email);

      String formatDate(String dateStr) {
        if (dateStr.isEmpty) return 'N/A';
        try {
          DateTime parsedDate = DateTime.parse(dateStr);
          return DateFormat('yyyy-MM-dd').format(parsedDate);
        } catch (e) {
          return 'Invalid Date';
        }
      }

      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            title: const Text(
              "Doctor Information",
              style: TextStyle(color: Color.fromRGBO(33, 158, 80, 1), fontSize: 22, fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: const Icon(Icons.person, color: Color.fromRGBO(10, 62, 29, 1)),
                    title: Text(
                      doctorData['fullName'] ?? 'Unknown Name',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.black),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.email, color: Color.fromRGBO(10, 62, 29, 1)),
                    title: Text(
                      "Email: ${doctorData['email']}",
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.phone, color: Color.fromRGBO(10, 62, 29, 1)),
                    title: Text(
                      "Phone: ${doctorData['phoneNumber'] ?? 'N/A'}",
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.home, color: Color.fromRGBO(10, 62, 29, 1)),
                    title: Text(
                      "Address: ${doctorData['doctors_info']['address'] ?? 'N/A'}",
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.home, color: Color.fromRGBO(10, 62, 29, 1)),
                    title: Text(
                      "Demography: ${doctorData['doctors_info']['demography'] ?? 'N/A'}",
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.home, color: Color.fromRGBO(10, 62, 29, 1)),
                    title: Text(
                      "Practing Tenure: ${doctorData['doctors_info']['practingTenure'] ?? 'N/A'}",
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.home, color: Color.fromRGBO(10, 62, 29, 1)),
                    title: Text(
                      "Specialization: ${doctorData['doctors_info']['specialization'] ?? 'N/A'}",
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.cake, color: Color.fromRGBO(10, 62, 29, 1)),
                    title: Text(
                      "Birthday: ${formatDate(doctorData['doctors_info']['birthday'])}",
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.contact_phone, color: Color.fromRGBO(10, 62, 29, 1)),
                    title: Text(
                      "Contact: ${doctorData['doctors_info']['contact'] ?? 'N/A'}",
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  "Close",
                  style: TextStyle(color: Color.fromRGBO(33, 158, 80, 1), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
  
  List<Map<String, dynamic>> doctors = [];  // Change this to store raw doctor data

  Stream<List<Schedule>> _getSchedulesStream() async* {
    try {
      String? userEmail = await SessionManager.getUserSession();
      if (userEmail == null) {
        throw Exception('No user session found. Please log in again.');
      }

      yield* FirebaseFirestore.instance
          .collection('appointments')
          .where('userEmail', isEqualTo: userEmail)
          .snapshots()
          .map((snapshot) {
        final schedules = snapshot.docs.map((doc) {
          final data = doc.data();
          final String appointmentId = doc.id;  // Get the appointment ID
          
          final String doctorName = data['doctorEmail'] != null 
              ? doctors.firstWhere(
                  (doc) => doc['email'] == data['doctorEmail'],
                  orElse: () => {'fullName': 'Unknown Doctor'},
                )['fullName'] ?? 'Unknown Doctor'
              : data['doctorName'] ?? 'Unknown Doctor';

          final DateTime? appointmentDate = data['day'] != null 
              ? DateTime.parse(data['day'].toString())
              : null;

          DateTime? startTime;
          if (appointmentDate != null && data['time'] != null) {
            final timeStr = data['time'].toString();
            final timeParts = timeStr.toUpperCase().split(' ');
            if (timeParts.length == 2) {
              final time = timeParts[0].split(':');
              int hour = int.parse(time[0]);
              int minute = int.parse(time[1]);
              
              if (timeParts[1] == 'PM' && hour < 12) {
                hour += 12;
              } else if (timeParts[1] == 'AM' && hour == 12) {
                hour = 0;
              }
              
              startTime = DateTime(
                appointmentDate.year,
                appointmentDate.month,
                appointmentDate.day,
                hour,
                minute,
              );
            }
          }

          final DateTime? endTime = startTime?.add(const Duration(hours: 1));
          
          if (appointmentDate == null || startTime == null || endTime == null) {
            return null;
          }

          return Schedule(
            doctor: doctorName,
            address: data['hospitalName'] ?? 'Consultation',
            dayTime: _formatDate(appointmentDate),
            startTime: _formatTime(startTime),
            endTime: _formatTime(endTime),
            avatar: 'assets/images/avatar.png',
            id: appointmentId,  // Add the ID to the Schedule
          );
        })
        .where((schedule) => schedule != null)
        .cast<Schedule>()
        .toList();
        
        return schedules;
      });
    } catch (e) {
      yield [];
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('EEEE, d MMMM').format(date);
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    return DateFormat('h:mm a').format(time);
  }

  

  Future<void> _fetchDoctors() async {
    try {
      final getdoctors = await DBHelper().getAllDoctors();
      if (mounted) {
        setState(() {
          doctors = getdoctors;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadUserData() async {
    try {
      final email = await SessionManager.getUserSession();
      if (email != null) {
        final userData = await DBHelper().getPatientsByEmail(email);
        final userInfo = await DBHelper().getPatientsInfoByEmail(email);

        if (userData != null && mounted) {
          setState(() {
            _email = email;
            _fullName = userData['fullName'];
            _phoneNumber = userData['phoneNumber'];
            _address = userInfo?['address'];
            _contact = userInfo?['contact'];
            _dateOfBirth = userInfo?['birthday'];
            user['name'] = userData['fullName'];
          });
          await _loadMedicalHistory(email);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user data: $e')),
        );
      }
    }
  }

  Future<void> _loadMedicalHistory(String email) async {
    try {
      final history = await DBHelper().getMedicalHistoryByEmail(email);
      if (mounted) {
        setState(() {
          _medicalHistory = history;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your profile lacks medical history. Please add it.')),
        );
      }
    }
  }

  void _generateQRCode() async {
    if (_fullName != null &&
        _address != null &&
        _phoneNumber != null &&
        _email != null &&
        _contact != null &&
        _dateOfBirth != null &&
        _medicalHistory != []) {
      List<Map<String, dynamic>> userData = [
        {'name': _fullName},
        {'email': _email},
        {'phoneNumber': _phoneNumber},
        {'address': _address},
        {'contact': _contact},
        {'birthday': _dateOfBirth},
      ];

      // Add medical history entries
      List<Map<String, dynamic>> medicalHistoryList = [];
      for (var history in _medicalHistory!) {
        medicalHistoryList.add({
          'title': history['title'],
          'subtitle': history['subtitle'],
          'description': history['description'],
        });
      }

      userData.add({'medicalHistory': medicalHistoryList});

      try {
        // Query the records collection where patientEmail is equal to _email
        await FirebaseFirestore.instance
            .collection('records')
            .where('patientEmail', isEqualTo: _email)
            .get();
        // Convert the list of maps to a JSON string
        String userDataString = userData.join('\n');

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QRCodePage(data: userDataString),
          ),
        );
      } catch (e) {
        // Handle potential errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching records: $e")),
        );
      }
    } else {
      // Handle case where user data is not available
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("User data not available. Please make your profile!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color.fromRGBO(33, 158, 80, 1),
      body: Column(
        children: [
          // Top Section (green)
          Container(
            color: const Color.fromRGBO(33, 158, 80, 1),
            padding: EdgeInsets.all(size.width * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: size.width * 0.05),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Hey, ${user['name']}",
                            style: GoogleFonts.poppins(
                              fontSize: size.width * 0.04,
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            "Today is a busy day",
                            style: GoogleFonts.poppins(
                              fontSize: size.width * 0.025,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(right: size.width * 0.05),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: SizedBox(
                        width: 32, // Fixed width
                        height: 32, // Fixed height
                        child: IconButton(
                          iconSize: 15, // Ensures icon size doesn't change
                          padding: EdgeInsets.zero, // Removes extra padding
                          icon: RotationTransition(
                            turns: _animationController,
                            child: const Icon(
                              Icons.sync,
                              color: Color.fromRGBO(33, 158, 80, 1),
                            ),
                          ),
                          onPressed: _isLoading ? null : _onButtonPressed,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: size.height * 0.02),
                _buildScheduleCard(size),
              ],
            ),
          ),

          // Body Section (white with border radius)
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: size.height * 0.01),
                    Expanded(
                      child: _buildRecentRecords(size),
                    ),
                    SizedBox(height: size.height * 0.02),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(Size size) {
    return StreamBuilder<List<Schedule>>(
      stream: _getSchedulesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white), // Set loading indicator color to white
                    ),
                  );
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }
        
        final schedules = snapshot.data ?? [];
        if (schedules.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No upcoming appointments',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          );
        }
        
        return ScheduleCard(
          schedules: schedules,
          size: size,
          doctors: doctors,
          appointmentId: schedules.isNotEmpty ? schedules[0].id : null,
        );
      },
    );
  }

  Widget _buildRecentRecords(Size size) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.1, vertical: size.height * 0.02),
      child: Container(
        padding: EdgeInsets.all(size.width * 0.04),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(33, 158, 80, 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Recent Doctors",
              style: GoogleFonts.poppins(
                fontSize: size.width * 0.045,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: size.height * 0.01),
            Expanded(
              child: (_isFetchingRecords)
                  ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white), // Set loading indicator color to white
                    ),
                  ) : ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  color: Colors.white,
                  child: ListView.builder(
                    itemCount: recentDocotors.length,
                    itemBuilder: (context, index) {
                      final doctor = recentDocotors[index];
                      final email = doctor['doctorEmail'] ?? 'Unknown Email';
                      final updatedAt = doctor['time'] != null 
                        ? DateFormat('dd/MM/yyyy hh:mm a').format((doctor['time'] as Timestamp).toDate())
                        : 'No Update Info';
                      return FutureBuilder<String>(
                        future: getDoctorName(email),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const ListTile(
                              leading: CircleAvatar(
                                backgroundImage: AssetImage('assets/images/avatar.png'),
                              ),
                              title: Text('Loading...'),
                              subtitle: Text('Please wait...'),
                              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                            );
                          } else if (snapshot.hasError) {
                            return ListTile(
                              leading: const CircleAvatar(
                                backgroundImage: AssetImage('assets/images/avatar.png'),
                              ),
                              title: const Text('Error loading name'),
                              subtitle: Text(updatedAt),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                            );
                          } else {
                            return ListTile(
                              leading: const CircleAvatar(
                                backgroundImage: AssetImage('assets/images/avatar.png'),
                              ),
                              title: Text(
                                snapshot.data ?? 'Unknown Patient',
                                style: GoogleFonts.poppins(fontSize: size.width * 0.035),
                              ),
                              subtitle: Text(
                                updatedAt,
                                style: GoogleFonts.poppins(fontSize: size.width * 0.03),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                              onTap: () => _showDoctorInfo(context, email),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
            SizedBox(height: size.height * 0.03),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: size.width * 0.02),
                    child: ElevatedButton(
                      onPressed: _generateQRCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(227, 243, 208, 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: FittedBox(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.qr_code,
                              color: Color.fromRGBO(33, 158, 80, 1),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              "Get QR Code",
                              style: GoogleFonts.poppins(color: Color.fromRGBO(33, 158, 80, 1)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: size.width * 0.02),
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(227, 243, 208, 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const FittedBox(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.note_add,
                              color: Color.fromRGBO(33, 158, 80, 1),
                            ),
                            SizedBox(width: 5),
                            Text(
                              "Add Notes",
                              style: TextStyle(color: Color.fromRGBO(33, 158, 80, 1)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
