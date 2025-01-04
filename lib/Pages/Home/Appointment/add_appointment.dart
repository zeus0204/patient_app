import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:patient_app/data/session.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:patient_app/data/db_helper.dart'; // Import DBHelper

class AddAppointment extends StatefulWidget {
  final String? id;
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
  String? _selectedHospitalName;
  bool _isInitialized = false;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized && widget.id != null) {
      _isInitialized = true;
      _loadAppointmentData();
    }
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadAppointmentData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.id != null) {
        final appointment = await FirebaseFirestore.instance
            .collection('appointments')
            .doc(widget.id)
            .get();

        if (!mounted) return;

        if (appointment.exists) {
          final data = appointment.data()!;
          setState(() {
            _selectedDate = DateTime.parse(data['day']);
            _selectedDoctorEmail = data['doctorEmail'];
            _selectedHospitalName = data['hospitalName'];
            _selectedTime = data['time'];
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading appointment data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

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
      final dbHelper = DBHelper();
      final availableHospitals = await dbHelper.fetchHospitalsForDoctor(doctorEmail);

      if (!mounted) return;

      if (availableHospitals.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hospitals found for this doctor'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      String? selectedHospitalName;

      await showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setModalState) {
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
                      value: hosp['name']!,
                      groupValue: selectedHospitalName,
                      activeColor: const Color.fromRGBO(33, 158, 80, 1),
                      onChanged: (String? value) {
                        setModalState(() {
                          selectedHospitalName = value;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: selectedHospitalName == null
                      ? null
                      : () {
                          if (mounted) {
                            setState(() {
                              _selectedHospitalName = selectedHospitalName;
                            });
                          }
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching hospitals: $e'),
          backgroundColor: Colors.red,
        ),
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color.fromRGBO(33, 158, 80, 1)),
              ),
            )
          : SingleChildScrollView(
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
                                doctor['fullName']!,
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
    if (_selectedTime == null || _selectedDoctorEmail == null || _selectedHospitalName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a doctor, hospital, and time!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color.fromRGBO(33, 158, 80, 1)),
          ),
        );
      },
    );
    
    try {
      final userEmail = await SessionManager.getUserSession();
      if (userEmail == null) {
        throw Exception('No user session found. Please log in again.');
      }

      final appointmentData = {
        'userEmail': userEmail,
        'doctorEmail': _selectedDoctorEmail!,
        'hospitalName': _selectedHospitalName!,
        'day': _selectedDate.toIso8601String(),
        'time': _selectedTime,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.id == null) {
        // Add new appointment
        await FirebaseFirestore.instance
            .collection('appointments')
            .add(appointmentData);
      } else {
        // Update existing appointment
        await FirebaseFirestore.instance
            .collection('appointments')
            .doc(widget.id)
            .update(appointmentData);
      }
      
      // Close loading dialog
      Navigator.pop(context);
      
      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.id == null ? 'Appointment scheduled successfully' : 'Appointment updated successfully'),
          backgroundColor: const Color.fromRGBO(33, 158, 80, 1),
        ),
      );
      
      // Navigate back to calendar
      Navigator.pop(context, true);
      
    } catch (e) {
      // Close loading dialog
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error ${widget.id == null ? 'scheduling' : 'updating'} appointment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
