import 'package:flutter/material.dart';
import 'package:patient_app/Pages/Home/Appointment/calendar.dart';
import 'package:patient_app/Pages/Home/dashboard.dart';
import 'package:patient_app/Pages/Home/settings.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const Dashboard(),
    Calendar(),
    const SettingsPage()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: _buildIcon(Icons.dashboard, _currentIndex == 0),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: _buildIcon(Icons.calendar_month, _currentIndex == 1),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: _buildIcon(Icons.settings, _currentIndex == 2),
            label: '',
          ),
        ],
        // Disable the animation when switching tabs
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _buildIcon(IconData icon, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? Color.fromRGBO(33, 158, 80, 1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8), // Rounded corners
      ),
      padding: EdgeInsets.all(10), // Adjust padding for better appearance
      child: Icon(
        icon,
        color: isSelected ? Colors.white : Color.fromRGBO(33, 158, 80, 1),
      ),
    );
  }
}
