import 'package:flutter/material.dart';
import 'package:patient_app/data/db_helper.dart';
import 'package:patient_app/data/session.dart';
import 'package:table_calendar/table_calendar.dart';

class AddAppointment extends StatefulWidget {
  final int? id;
  final List<Map<String, dynamic>> doctors;

  const AddAppointment({
    Key? key,
    this.id,
    required this.doctors,
  }) : super(key: key);

  @override
  State<AddAppointment> createState() => _AddAppointmentState();
}

class _AddAppointmentState extends State<AddAppointment> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  String? _selectedDoctorEmail;
  String? _selectedHospitalId;

  @override
  void initState() {
    super.initState();
    if (widget.id != null) {
      _loadAppointmentData();
    }
  }

  Future<void> _loadAppointmentData() async {
    try {
      if (widget.id != null) {
        final appointments = await DBHelper().getAppointmentsById(widget.id.toString());
        if (appointments.isNotEmpty) {
          final appointment = appointments.first;
          setState(() {
            _selectedDate = DateTime.parse(appointment['day']);
            _selectedDoctorEmail = appointment['doctor_id'].toString();
            _selectedHospitalId = appointment['hospital_id'].toString();
            _selectedTime = appointment['time'];
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading appointment data: $e')),
      );
    }
  }

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
  ];

  String _getTimeForIndex(int index) {
    final hour = 6 + index ~/ 2;
    final minute = (index % 2) * 30;
    var period = 'AM';
    if (hour >= 12) {
      period = 'PM';
    }
    return '${hour > 12 ? hour - 12 : hour}:${minute == 0 ? '00' : '30'} $period';
  }

  Future<void> _showHospitalSelectionModal(String doctorEmail) async {
    try {
      final availableHospitals = await DBHelper().fetchHospitalsForDoctor(doctorEmail);
      String? selectedHospitalId;

      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text(
                'Select Hospital',
                style: TextStyle(
                  color: Color.fromRGBO(33, 158, 80, 1),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: availableHospitals.map((hosp) {
                  return ListTile(
                    title: Text(
                      hosp['name']!,
                      style: const TextStyle(color: Colors.black),
                    ),
                    leading: Radio<String>(
                      value: hosp['id']!,
                      groupValue: selectedHospitalId,
                      activeColor: const Color.fromRGBO(33, 158, 80, 1),
                      onChanged: (String? value) {
                        setState(() {
                          selectedHospitalId = value;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: selectedHospitalId == null
                      ? null
                      : () {
                          setState(() {
                            _selectedHospitalId = selectedHospitalId;
                          });
                          Navigator.pop(context);
                        },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color.fromRGBO(33, 158, 80, 1),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color.fromRGBO(33, 158, 80, 1),
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching hospitals: $e')),
      );
    }
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
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color.fromRGBO(33, 158, 80, 1),
                      width: 2,
                    ),
                  ),
                  todayTextStyle: const TextStyle(color: Colors.black),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  headerPadding: EdgeInsets.all(8),
                  titleTextStyle: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(33, 158, 80, 1),
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
                  final time = _getTimeForIndex(index);
                  return _buildTimeButton(time);
                },
              ),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
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
                    color: const Color.fromRGBO(33, 158, 80, 1),
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    hint: const Text(
                      'Select a Doctor',
                      style: TextStyle(color: Color.fromRGBO(33, 158, 80, 1)),
                    ), 
                                        value: _selectedDoctorEmail,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Color.fromRGBO(33, 158, 80, 1),
                    ),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedDoctorEmail = newValue;
                        if (_selectedDoctorEmail != null) {
                          _showHospitalSelectionModal(_selectedDoctorEmail!);
                        }
                      });
                    },
                    items: widget.doctors.map<DropdownMenuItem<String>>((doctor) {
                      return DropdownMenuItem<String>(
                        value: doctor['email'],
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
    final isSelected = _selectedTime == time;
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
    if (_selectedTime == null || _selectedDoctorEmail == null || _selectedHospitalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a doctor, hospital, and time!'),
        ),
      );
      return;
    }
    
    try {
      final userEmail = await SessionManager.getUserSession();
      if (userEmail == null) {
        throw Exception('No user session found. Please log in again.');
      }
      final dbHelper = DBHelper();
      final userId = await dbHelper.getPatientIdByEmail(userEmail);
      final appointmentData = {
        'user_id': userId,
        'doctor_id': int.parse(_selectedDoctorEmail!),
        'hospital_id': int.parse(_selectedHospitalId!),
        'day': _selectedDate.toIso8601String(),
        'time': _selectedTime,
      };

      if (widget.id == null) {
        await dbHelper.insertAppointment(appointmentData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment scheduled successfully')),
        );
      } else {
        await dbHelper.updateAppointment(widget.id.toString(), appointmentData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment updated successfully')),
        );
      }
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error scheduling appointment: $e')),
      );
    }
  }
}

