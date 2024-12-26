import 'package:flutter/material.dart';
import 'package:patient_app/Pages/Home/QR_code.dart';
import 'package:patient_app/data/db_helper.dart';
import 'package:patient_app/data/session.dart';

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

  final List<Map<String, String>> doctors = [
    {'name': 'Doctor 1', 'updated_history': 'Last Updated: 2h ago', 'avatar': 'assets/doctor1.png'},
    {'name': 'Doctor 2', 'updated_history': 'Last Updated: 3h ago', 'avatar': 'assets/doctor2.png'},
    {'name': 'Doctor 3', 'updated_history': 'Last Updated: 5h ago', 'avatar': 'assets/doctor3.png'},
    {'name': 'Doctor 4', 'updated_history': 'Last Updated: 7h ago', 'avatar': 'assets/doctor4.png'},
  ];

  final Map<String, dynamic> schedule = {
    'doctor': 'Dr. Jon',
    'address': 'Migraines',
    'day_time': 'Tuesday, 5 March',
    'start_time': '11:00 AM',
    'end_time': '12:00 PM',
    'avatar': 'assets/dr_jon.png',
  };
  void initState() {  
    super.initState();  
    _loadUserData();  
  }  

  Future<void> _loadUserData() async {  
    try {  
      String? email = await SessionManager.getUserSession();  
      if (email != null) {  
        Map<String, dynamic>? userData = await DBHelper().getPatientsByEmail(email);
        Map<String, dynamic>? userInfo =
                      await DBHelper().getPatientsInfoByEmail(email);
          // Fetch UserInfo
        if (userData != null) {  
          setState(() {
            _email = email;
            _fullName = userData['fullName'];
            _phoneNumber = userData['phoneNumber'];
            _address = userInfo?['address'];
            _contact = userInfo?['contact'];
            _dateOfBirth = userInfo?['birthday'];
          });
          _loadMedicalHistory(email);
        }  
      }  
    } catch (e) {  
      // It's good practice to handle the error, e.g. log it or show feedback  
    } finally {  
      setState(() {
        user['name'] = _fullName;
      });  
    }  
  }
  
  Future<void> _loadMedicalHistory(email) async {
    try {
      final records = await DBHelper().getMedicalHistoryByEmail(email);
      setState(() {
        _medicalHistory = records;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Your profile lacks medical history. Please add it.')),
      );
    }
  }
   // Import this for JSON serialization  

  void _generateQRCode() async {
  // Assuming _user and _userInfo are already fetched and contain the necessary information
    if (_fullName != null && _address != null && _phoneNumber != null && _email != null && _contact != null && _dateOfBirth != null && _medicalHistory != []) {
      List<Map<String, dynamic>> userData = [
        {'Name': _fullName},
        {'Email': _email},
        {'Phone Number': _phoneNumber},
        {'Address': _address},
        {'Contact': _contact},
        {'Birthday': _dateOfBirth},
      ];
      
      // Now add medical history entries
      List<Map<String, dynamic>> medicalHistoryList = [];
      for (var history in _medicalHistory!) {
        medicalHistoryList.add({
          'Medical History Title': history['title'],
          'Subtitle': history['subtitle'],
          'Description': history['description'],
        });
      }
      
      // Add the medical history list to the main user data
      userData.add({
        'Medical History': medicalHistoryList
      });

      // Convert the list of maps to a JSON string
      String userDataString = userData.join('\n');

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QRCodePage(data: userDataString), // Pass the JSON string
        ),
      );
    } else {
      // Handle case where user data is not available
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User data not available. Please make your profile!")),
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
                            style: TextStyle(
                              fontSize: size.width * 0.04,
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            "Today is a busy day",
                            style: TextStyle(
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
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.notifications, color: Color.fromRGBO(33, 158, 80, 1)),
                        onPressed: () {},
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
    return Container(
      margin: EdgeInsets.symmetric(horizontal: size.width * 0.05),
      padding: EdgeInsets.all(size.width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: AssetImage(schedule['avatar']),
                radius: size.width * 0.08,
              ),
              SizedBox(width: size.width * 0.04),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schedule['doctor'],
                    style: TextStyle(fontSize: size.width * 0.045, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    schedule['address'],
                    style: TextStyle(color: Colors.grey, fontSize: size.width * 0.035),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: size.height * 0.02),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(33, 158, 80, 1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(vertical: size.height * 0.01, horizontal: size.width * 0.04),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: Color.fromRGBO(33, 158, 80, 1)),
                          SizedBox(width: size.width * 0.01),
                          Flexible(
                            child: Text(
                              schedule['day_time'],
                              style: TextStyle(
                                color: const Color.fromRGBO(33, 158, 80, 1),
                                fontWeight: FontWeight.w500,
                                fontSize: size.width * 0.03,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16, color: Color.fromRGBO(33, 158, 80, 1)),
                          SizedBox(width: size.width * 0.01),
                          Flexible(
                            child: Text(
                              "${schedule['start_time']} - ${schedule['end_time']}",
                              style: TextStyle(
                                color: const Color.fromRGBO(33, 158, 80, 1),
                                fontWeight: FontWeight.w500,
                                fontSize: size.width * 0.03,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: size.height * 0.02),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: size.width * 0.02),
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color.fromRGBO(33, 158, 80, 1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      foregroundColor: Colors.white,
                    ),
                    child: FittedBox(
                      child: Text(
                        "Reschedule",
                        style: TextStyle(
                          color: const Color.fromRGBO(33, 158, 80, 1),
                          fontSize: size.width * 0.035,
                        ),
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
                      backgroundColor: const Color.fromRGBO(33, 158, 80, 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: FittedBox(
                      child: Text(
                        "Join Session",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: size.width * 0.035,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
              "Recent Records",
              style: TextStyle(
                fontSize: size.width * 0.045,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: size.height * 0.01),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  color: Colors.white,
                  child: ListView.builder(
                    itemCount: doctors.length,
                    itemBuilder: (context, index) {
                      final doctor = doctors[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: AssetImage(doctor['avatar']!),
                        ),
                        title: Text(
                          doctor['name']!,
                          style: TextStyle(fontSize: size.width * 0.035),
                        ),
                        subtitle: Text(
                          doctor['updated_history']!,
                          style: TextStyle(fontSize: size.width * 0.03),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        onTap: () {},
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
                      onPressed: () {
                        _generateQRCode();
                      },
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
                              Icons.qr_code,
                              color: Color.fromRGBO(33, 158, 80, 1),
                            ),
                            SizedBox(width: 5),
                            Text(
                              "Get QR Code",
                              style: TextStyle(color: Color.fromRGBO(33, 158, 80, 1)),
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
            ),
          ],
        ),
      ),
    );
  }
}
