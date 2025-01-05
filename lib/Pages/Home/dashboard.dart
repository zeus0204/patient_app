import 'package:flutter/material.dart';
import 'package:patient_app/Pages/Home/qr_code.dart';
import 'package:patient_app/data/db_helper.dart';
import 'package:patient_app/data/session.dart';
import 'package:patient_app/models/doctor.dart';
import 'package:patient_app/models/schedule.dart';
import 'package:patient_app/utils/constants.dart';
import 'package:patient_app/widgets/doctor_list.dart';
import 'package:patient_app/widgets/schedule_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  List<Map<String, dynamic>>? _medicalHistory = [];
  String? _fullName;
  String? _phoneNumber;
  String? _address;
  String? _contact;
  String? _dateOfBirth;
  String? _email;
  final Map<String, dynamic> user = {
    'name': '',
    'age': 29,
  };

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

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchDoctors();
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
        final history = await DBHelper().getMedicalHistoryByEmail(email);

        if (userData != null && mounted) {
          setState(() {
            _email = email;
            _fullName = userData['fullName'];
            _phoneNumber = userData['phoneNumber'];
            _address = userInfo?['address'];
            _contact = userInfo?['contact'];
            _dateOfBirth = userInfo?['birthday'];
            user['name'] = userData['fullName'];
            _medicalHistory = history;
          });
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

  Future<void> _generateQRCode() async {
    if (_medicalHistory != null && _medicalHistory!.isNotEmpty) {
      final dbHelper = DBHelper();
      final userDataString = await dbHelper.generateQRData(
        _fullName ?? '',
        _phoneNumber ?? '',
        _address ?? '',
        _contact ?? '',
        _dateOfBirth ?? '',
        _email ?? '',
        _medicalHistory ?? [],
      );

      if (!mounted) return;
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QRCodePage(data: userDataString),
        ),
      );
    } else {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User data not available. Please make your profile!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: size.height * 0.02),
                          _buildUserInfo(),
                          SizedBox(height: size.height * 0.01),
                          StreamBuilder<List<Schedule>>(
                            stream: _getSchedulesStream(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              
                              if (snapshot.hasError) {
                                return Center(
                                  child: Text('Error: ${snapshot.error}'),
                                );
                              }
                              
                              final schedules = snapshot.data ?? [];
                              if (schedules.isEmpty) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Text(
                                      'No upcoming appointments',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              
                              return ScheduleCard(
                                schedules: schedules,
                                size: Size(size.width, 200), // Reduced from 0.35 to 0.25
                                doctors: doctors,
                                appointmentId: schedules.isNotEmpty ? schedules[0].id : null,
                              );
                            },
                          ),
                          SizedBox(height: size.height * 0.02),
                          DoctorList(
                            doctors: doctors.map((doc) => Doctor(
                              name: doc['fullName'] ?? 'Unknown Doctor',
                              updatedHistory: 'Last Updated: 2h ago',
                              avatar: 'assets/images/avatar.png',
                            )).toList(),
                            size: Size(size.width, constraints.maxHeight * 0.25),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(size.width * 0.04),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: _buildActionButtons(size),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${AppStrings.heyUser}${user['name']}",
          style: TextStyle(
            fontSize: 24,
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          AppStrings.busyDay,
          style: TextStyle(
            fontSize: 16,
            color: AppColors.primaryColor.withOpacity(0.85),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(Size size) {
    return Row(
      children: [
        _buildActionButton(
          size,
          AppStrings.getQRCode,
          Icons.qr_code,
          _generateQRCode,
        ),
        _buildActionButton(
          size,
          AppStrings.addNotes,
          Icons.note_add,
          () {},
        ),
      ],
    );
  }

  Widget _buildActionButton(
    Size size,
    String text,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: size.width * 0.02),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryLightColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: FittedBox(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: AppColors.primaryColor,
                ),
                const SizedBox(width: 5),
                Text(
                  text,
                  style: const TextStyle(color: AppColors.primaryColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
