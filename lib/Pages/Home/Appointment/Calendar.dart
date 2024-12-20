import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:patient_app/data/db_helper.dart';
import 'package:patient_app/data/model/Appointment.dart';
import 'package:patient_app/data/session.dart';
import 'add_appointment.dart'; // Import the AddAppointment page.

class Calendar extends StatefulWidget {
  const Calendar({Key? key}) : super(key: key);

  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  List<Appointment> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAppointments(); // Fetch appointments when the page loads
  }

  Future<void> _fetchAppointments() async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      // Step 1: Get the user's email from the session
      String? userEmail = await SessionManager.getUserSession();
      if (userEmail == null) {
        throw Exception('No user session found. Please log in again.');
      }

      // Step 2: Get the user ID from the database using the email
      final dbHelper = DBHelper();
      final userId = await dbHelper.getUserIdByEmail(userEmail);
      if (userId == null) {
        throw Exception('No user found for the current session email.');
      }

      // Step 3: Fetch appointments for the user ID
      final appointmentsData = await dbHelper.getAppointmentsByPatientId(userId);

      // Step 4: Update the state with the fetched appointments
      setState(() {
        _appointments = appointmentsData
            .map<Appointment>((appointmentMap) => Appointment.fromMap(appointmentMap))
            .toList();
        _isLoading = false; // Hide loading indicator
      });

    } catch (e) {
      // Handle any errors and show a message
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching appointments: $e')),
      );
    }
  }

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

  String getDoctorName(String doctorId) {
    final doctor = doctors.firstWhere(
      (doc) => doc['id'] == doctorId,
      orElse: () => {'name': 'Unknown Doctor'},
    );
    return doctor['name']!;
  }

  String getHospitalName(String hospitalId) {
    final hosp = hospital.firstWhere(
      (hos) => hos['id'] == hospitalId,
      orElse: () => {'name': 'Unknown Hospital'},
    );
    return hosp['name']!;
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
      await dbHelper.deleteAppointment(appointmentId); // Delete from DB
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
        builder: (context) => AddAppointment(id:appointmentId),
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
                            final doctorName = getDoctorName(appointment.doctor_id.toString());
                            final hospitalName = getHospitalName(appointment.hospital_id.toString());
                            
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
                                        'Day: ${_formatDate(appointment.day)}\n'
                                        'Time: ${appointment.time}',
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
                                            _editAppointment(appointment.id);                                            
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () {
                                            // Your delete logic here
                                            _showDeleteConfirmationDialog(appointment.id!);
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
            MaterialPageRoute(builder: (context) => const AddAppointment()),
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
