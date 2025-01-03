import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:patient_app/data/db_helper.dart';
import 'package:patient_app/data/model/Appointment.dart';
import 'package:patient_app/data/session.dart';
import 'add_appointment.dart'; // Import the AddAppointment page.

class Calendar extends StatefulWidget {
  const Calendar({super.key});

  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;
  List<Map<String, dynamic>> doctors = [];

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    try {
      List<Map<String, dynamic>> getdoctors = await DBHelper().getAllDoctors();
      
      setState(() {
        doctors = getdoctors;
      });
    } catch (e) {
      // Handle error fetching doctors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching doctors: $e')),
      );
    }
  }

  Future<void> _fetchAppointments() async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      String? userEmail = await SessionManager.getUserSession();
      if (userEmail == null) {
        throw Exception('No user session found. Please log in again.');
      }
      final dbHelper = DBHelper();

      final appointmentsData = await dbHelper.getAppointmentsByPatientEmail(userEmail);

      setState(() {
        _appointments = appointmentsData.cast<Map<String, dynamic>>();
        _isLoading = false; // Hide loading indicator
      });

    } catch (e) {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching appointments: $e')),
      );
    }
  }

  String getDoctorName(String? doctorEmail) {
    if (doctorEmail == null) return 'Unknown Doctor'; // Safeguard against null emails
    final doctor = doctors.firstWhere(
      (doc) => doc['email'] == doctorEmail,
      orElse: () => {'fullName': 'Unknown Doctor'},
    );
    return doctor['fullName'] ?? 'Unknown Doctor'; // Avoid null by providing a default value
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Future<void> _showDeleteConfirmationDialog(int appointmentId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Delete Appointment', style: TextStyle(color: Color.fromRGBO(33, 158, 80, 1)),),
          content: const Text('Are you sure you want to delete this appointment?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel', style: TextStyle(color: Color.fromRGBO(33, 158, 80, 1)),),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                await _deleteAppointment(appointmentId); // Delete the appointment
              },
              child: const Text('Okay', style: TextStyle(color: Color.fromRGBO(33, 158, 80, 1)),),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAppointment(int appointmentId) async {
    final dbHelper = DBHelper();
    try {
      await dbHelper.deleteAppointment(appointmentId as String); // Delete from DB
      _fetchAppointments(); // Refresh the list of appointments
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting appointment: $e')),
      );
    }
  }
  
  Future<void> _editAppointment(int? appointmentId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddAppointment(id:appointmentId, doctors: doctors),
      ),
    );
    
    if (result == true) {
      _fetchAppointments();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20), // Add spacing
            // "Appointments" Text at the Top
            const Text(
              'Appointments',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color.fromRGBO(33, 158, 80, 1),
              ),
            ),
            const SizedBox(height: 20),

            // Search Bar and Filter Icon
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const Icon(Icons.search, color: Colors.grey),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search (0 Appoint..)',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.filter_list, color: Colors.green),
                      onPressed: () {
                        // Filter functionality can be added here
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Placeholder for Appointments or Loading Spinner
            Flexible( // Use Flexible instead of Expanded
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator()) // Show loading spinner
                  : _appointments.isEmpty
                      ? Center( // Placeholder when no appointments exist
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.list_alt_rounded,
                                size: 100,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No appointment yet!!',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Hit the ‘+’ button down\nbelow to Create an appointment',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder( // Show list when appointments exist
                          itemCount: _appointments.length,
                          itemBuilder: (context, index) {
                            final appointment = _appointments[index];
                            final doctorEmail = appointment['doctorEmail'] as String?;
                            final hospitalName = appointment['hospitalName'] as String?;
                            final dayValue = appointment['day'];
                            final doctorName = getDoctorName(doctorEmail);
                            DateTime? formattedDay;
                            if (dayValue is Timestamp) {
                              formattedDay = dayValue.toDate();
                            } else if (dayValue is String) {
                              // Assuming the string is in a valid date format.
                              formattedDay = DateTime.tryParse(dayValue);
                            }
                            final time = appointment['time'] as String?;
                            
                            return Card(
                              color: Colors.white,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              child: Stack(
                                children: [
                                  // Main content of the card (ListTile)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 48.0), // Add some padding on the right side
                                    child: ListTile(
                                      leading: const Icon(
                                        Icons.calendar_today,
                                        color: Colors.green,
                                      ),
                                      title: Text(
                                        'Doctor: $doctorName',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green, // Title color set to green
                                        ),
                                      ),
                                      subtitle: Text(
                                        'Hospital: $hospitalName\n'
                                        'Day: ${formattedDay != null ? _formatDate(formattedDay) : ''}\n'
                                        'Time: ${time ?? 'N/A'}',
                                      ),
                                    ),
                                  ),
                                  // Edit and Delete buttons at the top-right corner
                                  Positioned(
                                    top: 8.0,
                                    right: 8.0,
                                    child: Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blue),
                                          onPressed: () {
                                            // _editAppointment(doctorEmail, hospitalName, dayValue, time);                      
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () {
                                            // Your delete logic here
                                            // _showDeleteConfirmationDialog(appointment.id!);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      // Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to AddAppointment Page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddAppointment(doctors: doctors),
            ),
          ).then((result) {
            if (result == true) {
              _fetchAppointments(); // Refresh appointments after adding
            }
          });
        },
        backgroundColor: const Color.fromRGBO(33, 158, 80, 1), // Green background
        shape: const CircleBorder(), // Ensures the button is circular
        child: const Icon(
          Icons.add,
          size: 30,
          color: Colors.white, // Icon color set to white
        ),
      ),
    );
  }
}
