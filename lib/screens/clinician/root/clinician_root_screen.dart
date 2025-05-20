import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../search/clinician_search_screen.dart';
import '../messages/clinician_inbox_screen.dart';

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
  ];

  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  void _checkToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    print('🔐 Token i _checkToken(): $token'); // debug (fjern evt.)
    if (token == null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      });
    }
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kliniker Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Patienter'),
          BottomNavigationBarItem(icon: Icon(Icons.mail_outline), label: 'Indbakke'),
        ],
      ),
    );
  }
}
