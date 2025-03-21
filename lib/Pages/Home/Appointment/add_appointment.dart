import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:patient_app/data/session.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:patient_app/data/db_helper.dart';
import 'package:intl/intl.dart';

class AddAppointment extends StatefulWidget {
  final String? id;
  final List<Map<String, dynamic>> doctors;

  const AddAppointment({Key? key, this.id, required this.doctors})
    : super(key: key);

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
  Set<String> _bookedTimeSlots = {};
  bool _allSlotsBooked = false;

  // New variables for doctor's availability
  Map<String, List<String>> _doctorAvailability = {};
  List<String> _availableTimesForSelectedDay = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized && widget.id != null) {
      _isInitialized = true;
      _loadAppointmentData();
    }
  }

  Future<void> _loadAppointmentData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.id != null) {
        final appointment =
            await FirebaseFirestore.instance
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

            // Load doctor's availability when editing an existing appointment
            _loadDoctorAvailability();
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

  Future<void> _loadDoctorAvailability() async {
    if (_selectedDoctorEmail == null) return;

    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('doctors')
              .where('email', isEqualTo: _selectedDoctorEmail)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doctorDoc = querySnapshot.docs.first.data();

        if (doctorDoc.containsKey('availability')) {
          setState(() {
            _doctorAvailability = Map<String, List<String>>.from(
              doctorDoc['availability'].map(
                (key, value) => MapEntry(key, List<String>.from(value)),
              ),
            );

            // Update available times for the current selected day
            _updateAvailableTimesForDay();
          });
        }
      }
    } catch (e) {
      print('Error loading doctor availability: $e');
    }
  }

  void _updateAvailableTimesForDay() {
    // Get the day abbreviation
    String dayAbbr = DateFormat('EEE').format(_selectedDate);

    // Update available times based on doctor's availability for the selected day
    setState(() {
      _availableTimesForSelectedDay = _doctorAvailability[dayAbbr] ?? [];
    });
  }

  Future<void> _showHospitalSelectionModal(String doctorEmail) async {
    try {
      final dbHelper = DBHelper();
      final availableHospitals = await dbHelper.fetchHospitalsForDoctor(
        doctorEmail,
      );

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
        builder:
            (context) => StatefulBuilder(
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
                    children:
                        availableHospitals.map((hosp) {
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
                      onPressed:
                          selectedHospitalName == null
                              ? null
                              : () {
                                if (mounted) {
                                  setState(() {
                                    _selectedHospitalName =
                                        selectedHospitalName;
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

  void _checkBookedAppointments() async {
    if (_selectedDoctorEmail == null || !mounted) return;

    setState(() {
      _isLoading = true;
      _bookedTimeSlots.clear();
      _allSlotsBooked = false;
    });

    try {
      final startOfDay = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('appointments')
              .where('doctorEmail', isEqualTo: _selectedDoctorEmail)
              .where(
                'day',
                isGreaterThanOrEqualTo: startOfDay.toIso8601String(),
              )
              .where('day', isLessThan: endOfDay.toIso8601String())
              .get();

      if (!mounted) return;

      setState(() {
        // Filter booked times that are in the doctor's available times
        _bookedTimeSlots =
            querySnapshot.docs
                .map((doc) => doc['time'] as String)
                .where((time) => _availableTimesForSelectedDay.contains(time))
                .toSet();

        // Check if all available slots are booked
        _allSlotsBooked =
            _bookedTimeSlots.length == _availableTimesForSelectedDay.length;

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking booked appointments: $e'),
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
        title: Text(
          widget.id == null ? 'Add Appointment' : 'Edit Appointment',
          style: const TextStyle(
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
            icon: const Icon(
              Icons.arrow_back,
              color: Color.fromRGBO(33, 158, 80, 1),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color.fromRGBO(33, 158, 80, 1),
                  ),
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
                        selectedDayPredicate:
                            (day) => isSameDay(_selectedDate, day),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDate = selectedDay;
                            _selectedTime =
                                null; // Reset selected time when date changes
                          });

                          // Update available times for the selected day
                          _updateAvailableTimesForDay();

                          if (_selectedDoctorEmail != null) {
                            _checkBookedAppointments();
                          }
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
                      child:
                          _availableTimesForSelectedDay.isEmpty
                              ? const Center(
                                child: Text(
                                  'No available times for this doctor on the selected day',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                              : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _availableTimesForSelectedDay.length,
                                itemBuilder: (context, index) {
                                  final time =
                                      _availableTimesForSelectedDay[index];
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
                          'Select Doctor',
                          style: TextStyle(
                            color: Color.fromRGBO(33, 158, 80, 1),
                          ),
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
                              style: TextStyle(
                                color: Color.fromRGBO(33, 158, 80, 1),
                              ),
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
                                _selectedTime =
                                    null; // Reset selected time when doctor changes
                                _selectedHospitalName = null;

                                if (_selectedDoctorEmail != null) {
                                  // Load doctor's availability
                                  _loadDoctorAvailability();

                                  // Show hospital selection modal
                                  _showHospitalSelectionModal(
                                    _selectedDoctorEmail!,
                                  );
                                }
                              });
                            },
                            items:
                                widget.doctors.map<DropdownMenuItem<String>>((
                                  doctor,
                                ) {
                                  return DropdownMenuItem<String>(
                                    value: doctor['email'],
                                    child: Text(
                                      doctor['fullName']!,
                                      style: const TextStyle(
                                        color: Colors.black,
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed:
                          _allSlotsBooked ||
                                  _selectedTime == null ||
                                  _selectedDoctorEmail == null ||
                                  _selectedHospitalName == null
                              ? null
                              : _scheduleAppointment,
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
                      child: Text(
                        widget.id == null ? 'Schedule' : 'Update',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
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
    final isBooked = _bookedTimeSlots.contains(time);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ElevatedButton(
        onPressed:
            isBooked
                ? null
                : () {
                  setState(() {
                    _selectedTime = time;
                  });
                },
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isBooked
                  ? Colors.grey
                  : isSelected
                  ? const Color.fromRGBO(33, 158, 80, 1)
                  : Colors.grey[200],
          foregroundColor:
              isBooked
                  ? Colors.white
                  : isSelected
                  ? Colors.white
                  : Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(time),
            if (isBooked) const Icon(Icons.block, size: 16),
          ],
        ),
      ),
    );
  }

  void _scheduleAppointment() async {
    // Validate all required fields are selected
    if (_selectedTime == null ||
        _selectedDoctorEmail == null ||
        _selectedHospitalName == null) {
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
            valueColor: AlwaysStoppedAnimation<Color>(
              Color.fromRGBO(33, 158, 80, 1),
            ),
          ),
        );
      },
    );

    try {
      // Get current user's email from session
      final userEmail = await SessionManager.getUserSession();
      if (userEmail == null) {
        throw Exception('No user session found. Please log in again.');
      }

      // Prepare appointment data
      final appointmentData = {
        'userEmail': userEmail,
        'doctorEmail': _selectedDoctorEmail!,
        'hospitalName': _selectedHospitalName!,
        'day': _selectedDate.toIso8601String(),
        'time': _selectedTime,
        'status': 'scheduled',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Close loading dialog
      Navigator.pop(context);

      // Add or update appointment based on whether it's a new or existing appointment
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

      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.id == null
                ? 'Appointment scheduled successfully'
                : 'Appointment updated successfully',
          ),
          backgroundColor: const Color.fromRGBO(33, 158, 80, 1),
        ),
      );

      // Navigate back to previous screen
      Navigator.pop(context, true);
    } catch (e) {
      // Close loading dialog if it's still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error ${widget.id == null ? 'scheduling' : 'updating'} appointment: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
