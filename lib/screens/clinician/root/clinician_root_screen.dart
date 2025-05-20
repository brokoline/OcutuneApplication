import 'package:flutter/material.dart';
import '../search/clinician_search_screen.dart';
import '../messages/clinician_inbox_screen.dart';
// import '../profile/clinician_profile_screen.dart'; // hvis du tilføjer den

class ClinicianRootScreen extends StatefulWidget {
  const ClinicianRootScreen({Key? key}) : super(key: key);

  @override
  State<ClinicianRootScreen> createState() => _ClinicianRootScreenState();
}

class _ClinicianRootScreenState extends State<ClinicianRootScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ClinicianSearchScreen(),
    const ClinicianInboxScreen(),
    // const ClinicianProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Patienter'),
          BottomNavigationBarItem(icon: Icon(Icons.mail_outline), label: 'Indbakke'),
          // BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
