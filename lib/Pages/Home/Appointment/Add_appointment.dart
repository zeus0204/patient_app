import 'package:flutter/material.dart';
import 'package:patient_app/data/db_helper.dart';
import 'package:patient_app/data/session.dart';
import 'package:table_calendar/table_calendar.dart';

class AddAppointment extends StatefulWidget {
  const AddAppointment({super.key});

  @override
  State<AddAppointment> createState() => _AddAppointmentState();
}

class _AddAppointmentState extends State<AddAppointment> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  String? _selectedDoctorId; // To store selected doctor ID
  String? _selectedHospitalId;

  final List<Map<String, String>> doctors = [
    {'id': '1', 'name': 'Doctor 1'},
    {'id': '2', 'name': 'Doctor 2'},
    {'id': '3', 'name': 'Doctor 3'},
    {'id': '4', 'name': 'Doctor 4'},
  ];

  final List<Map<String, String>> hospital = [
    {'id': '1', 'name': 'hospital 1'},
    {'id': '2', 'name': 'hospital 2'},
    {'id': '3', 'name': 'hospital 3'},
    {'id': '4', 'name': 'hospital 4'},
    {'id': '5', 'name': 'hospital 5'},
    {'id': '6', 'name': 'hospital 6'},
  ];

  final List<Map<String, String>> doctorHospitalRelations = [
    {'doctor_id': '1', 'hospital_id': '1'},
    {'doctor_id': '1', 'hospital_id': '2'},
    {'doctor_id': '2', 'hospital_id': '3'},
    {'doctor_id': '2', 'hospital_id': '4'},
    {'doctor_id': '3', 'hospital_id': '1'},
    {'doctor_id': '4', 'hospital_id': '5'},
    {'doctor_id': '4', 'hospital_id': '6'},
    // You can add more relationships here
  ];
  String _getTimeForIndex(int index) {
    int hour = 6 + index ~/ 2; // 6 AM + half of index as hours
    int minute = (index % 2) * 30; // Alternate between 00 and 30 minutes
    String period = hour < 12 ? 'AM' : 'PM';
    if (hour > 12) hour -= 12;
    return '$hour:${minute == 0 ? '00' : '30'} $period';
  }

  void _showHospitalSelectionModal(String doctorId) {
    // Get a list of hospitals available for the selected doctor
    final hospitalsForDoctor = doctorHospitalRelations
        .where((relation) => relation['doctor_id'] == doctorId)
        .map((relation) => relation['hospital_id'])
        .toSet()
        .toList();

    final availableHospitals = hospital
        .where((h) => hospitalsForDoctor.contains(h['id']))
        .toList();

    String? selectedHospitalId = _selectedHospitalId; // Temp variable for local state

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.white, // Set dialog background color to white
            title: const Text(
              'Select Hospital',
              style: TextStyle(
                color: Color.fromRGBO(33, 158, 80, 1), // Green text color
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: availableHospitals
                  .map((hosp) => ListTile(
                        title: Text(
                          hosp['name']!,
                          style: const TextStyle(
                            color: Colors.black, // Black text for hospitals
                          ),
                        ),
                        leading: Radio<String>(
                          value: hosp['id']!,
                          groupValue: selectedHospitalId,
                          activeColor: const Color.fromRGBO(33, 158, 80, 1), // Green radio button
                          onChanged: (String? value) {
                            setState(() {
                              selectedHospitalId = value; // Update local state
                            });
                          },
                        ),
                      ))
                  .toList(),
            ),
            actions: [
              TextButton(
                onPressed: selectedHospitalId == null
                    ? null // Disable button if no hospital is selected
                    : () {
                        setState(() {
                          _selectedHospitalId = selectedHospitalId; // Save to main state
                        });
                        Navigator.pop(context); // Close the modal
                      },
                style: TextButton.styleFrom(
                  foregroundColor: const Color.fromRGBO(33, 158, 80, 1), // Green text color
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context), // Close the modal without saving
                style: TextButton.styleFrom(
                  foregroundColor: const Color.fromRGBO(33, 158, 80, 1), // Green text color
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Add Appointment',
          style: TextStyle(
            color: Color.fromRGBO(33, 158, 80, 1),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Color.fromRGBO(226, 248, 227, 1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color.fromRGBO(33, 158, 80, 1)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TableCalendar(
                focusedDay: _selectedDate,
                firstDay: DateTime(2020),
                lastDay: DateTime(2030),
                selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDate = selectedDay;
                  });
                },
                calendarStyle: CalendarStyle(
                  selectedDecoration: const BoxDecoration(
                    color: Color.fromRGBO(33, 158, 80, 1),
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.white, // White background for today's date
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color.fromRGBO(33, 158, 80, 1), // Green border
                      width: 2, // Adjust the border width as needed
                    ),
                  ),
                  todayTextStyle: const TextStyle(
                    color: Colors.black, // Text color for today's date
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,  // Removes the "2 weeks" button
                  titleCentered: true,         // Centers the header title
                  headerPadding: EdgeInsets.all(8), // Adjust header padding
                  titleTextStyle: TextStyle(
                    fontSize: 24,  // Makes the month and year text bigger
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(33, 158, 80, 1)
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Available Times',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 24,
                itemBuilder: (context, index) {
                  String time = _getTimeForIndex(index);
                  return _buildTimeButton(time);
                },
              ),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0), // Add padding if needed
                child: Text(
                  'View patient availability',
                  style: TextStyle(color: Color.fromRGBO(33, 158, 80, 1)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color.fromRGBO(33, 158, 80, 1), // Green border color
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.circular(8.0), // Rounded corners
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12.0), // Inner padding
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    hint: const Text(
                      'Select a Doctor',
                      style: TextStyle(color: Color.fromRGBO(33, 158, 80, 1)), // Green hint color
                    ),
                    value: _selectedDoctorId,
                    isExpanded: true, // Ensures the dropdown takes the full width of its container
                    dropdownColor: Colors.white,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black, // Dropdown text color
                    ),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Color.fromRGBO(33, 158, 80, 1), // Green arrow color
                    ),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedDoctorId = newValue;
                        if (_selectedDoctorId != null) {
                          _showHospitalSelectionModal(_selectedDoctorId!);
                        }
                      });
                    },
                    items: doctors.map<DropdownMenuItem<String>>((doctor) {
                      return DropdownMenuItem<String>(
                        value: doctor['id'],
                        child: Text(
                          doctor['name']!,
                          style: const TextStyle(color: Colors.black),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _scheduleAppointment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(33, 158, 80, 1),
                padding: const EdgeInsets.symmetric(
                  horizontal: 100,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Schedule',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeButton(String time) {
    bool isSelected = _selectedTime == time;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _selectedTime = time;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? const Color.fromRGBO(33, 158, 80, 1) : Colors.grey[200],
          foregroundColor: isSelected ? Colors.white : Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(time),
      ),
    );
  }

  void _scheduleAppointment() async {
    if (_selectedTime == null || _selectedDoctorId == null || _selectedHospitalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a doctor, hospital, and time!'),
        ),
      );
      return;
    }
    
    try {
      String? userEmail = await SessionManager.getUserSession();
      if (userEmail == null) {
        throw Exception('No user session found. Please log in again.');
      }
      final dbHelper = DBHelper();
      final userId = await dbHelper.getUserIdByEmail(userEmail);
      final appointmentData = {
        'user_id': userId, // Replace with actual patient ID (e.g., from logged-in user)
        'doctor_id': int.parse(_selectedDoctorId!), // Convert ID to integer
        'hospital_id': int.parse(_selectedHospitalId!), // Convert ID to integer
        'day': _selectedDate.toIso8601String(), // Store date as ISO 8601 string
        'time': _selectedTime, // Store selected time
      };
      
      await DBHelper().insertAppointment(appointmentData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scheduling appintment successfully')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error scheduling appointment: $e')),
      );
    }
  }
}
