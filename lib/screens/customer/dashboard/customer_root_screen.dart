// lib/screens/customer_root_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../widgets/customer_widgets/customer_app_bar.dart';



class CustomerRootScreen extends StatefulWidget {
  const CustomerRootScreen({Key? key}) : super(key: key);

  @override
  State<CustomerRootScreen> createState() => _CustomerRootScreenState();
}

class _CustomerRootScreenState extends State<CustomerRootScreen> {
  int _currentIndex = 0;

  // Her ligger alle underskærme — vi har pt. blot to: "Hjem" og "Profil"
  final List<Widget> _pages = [
    // 0: “Hjem” (indholdet med lysdata kommer senere)
    const Center(
      child: Text(
        'Her kommer lysdata',
        style: TextStyle(fontSize: 18),
      ),
    ),

    // 1: “Profil” (eksempel på profil-skærm – smid egen profil-widget ind)
    Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person,
            size: 64,
            color: Colors.grey.shade700,
          ),
          const SizedBox(height: 16),
          const Text(
            'Min Profil',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'E-mail: bruger@eksempel.dk\nNavn: John Kund',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
        ],
      ),
    ),
  ];

  // Helper til at sætte AppBar-titlen dynamisk efter valg
  String _titleForIndex(int index) {
    switch (index) {
      case 0:
        return 'Hjem';
      case 1:
        return 'Min Profil';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomerAppBar(
        title: _titleForIndex(_currentIndex),
        showLogout: false, // Hvis I vil håndtere logout i profil-siden i stedet
        showBackButton: false,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (idx) => setState(() => _currentIndex = idx),
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Hjem',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
