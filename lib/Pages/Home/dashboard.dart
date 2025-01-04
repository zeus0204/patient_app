import 'package:flutter/material.dart';
import 'package:patient_app/Pages/Home/qr_code.dart';
import 'package:patient_app/data/db_helper.dart';
import 'package:patient_app/data/session.dart';
import 'package:patient_app/models/doctor.dart';
import 'package:patient_app/models/schedule.dart';
import 'package:patient_app/utils/constants.dart';
import 'package:patient_app/widgets/doctor_list.dart';
import 'package:patient_app/widgets/schedule_card.dart';

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

  final List<Doctor> doctors = [
    Doctor(name: 'Doctor 1', updatedHistory: 'Last Updated: 2h ago', avatar: 'assets/images/avatar.png'),
    Doctor(name: 'Doctor 2', updatedHistory: 'Last Updated: 3h ago', avatar: 'assets/images/avatar.png'),
    Doctor(name: 'Doctor 3', updatedHistory: 'Last Updated: 5h ago', avatar: 'assets/images/avatar.png'),
    Doctor(name: 'Doctor 4', updatedHistory: 'Last Updated: 7h ago', avatar: 'assets/images/avatar.png'),
  ];

  final List<Schedule> schedules = [
    Schedule(
      doctor: 'Dr. Jon',
      address: 'Migraines',
      dayTime: 'Tuesday, 5 March',
      startTime: '11:00 AM',
      endTime: '12:00 PM',
      avatar: 'assets/images/avatar.png',
    ),
    Schedule(
      doctor: 'Dr. Sarah',
      address: 'Follow-up',
      dayTime: 'Thursday, 7 March',
      startTime: '2:00 PM',
      endTime: '3:00 PM',
      avatar: 'assets/images/avatar.png',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
      backgroundColor: AppColors.primaryColor,
      body: Column(
        children: [
          _buildHeader(size),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppStyles.topBorderRadius),
                  topRight: Radius.circular(AppStyles.topBorderRadius),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppStyles.topBorderRadius),
                  topRight: Radius.circular(AppStyles.topBorderRadius),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: size.height * 0.01),
                      ScheduleCard(schedules: schedules, size: size),
                      SizedBox(height: size.height * 0.02),
                      DoctorList(doctors: doctors, size: size),
                      SizedBox(height: size.height * 0.03),
                      _buildActionButtons(size),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Size size) {
    return Container(
      color: AppColors.primaryColor,
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
                      "${AppStrings.heyUser}${user['name']}",
                      style: TextStyle(
                        fontSize: size.width * 0.04,
                        color: AppColors.white,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      AppStrings.busyDay,
                      style: TextStyle(
                        fontSize: size.width * 0.025,
                        color: AppColors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.only(right: size.width * 0.05),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: Icon(Icons.notifications, color: AppColors.primaryColor),
                  onPressed: () {
                    // TODO: Implement notification functionality
                  },
                ),
              ),
            ],
          ),
        ],
      ),
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
