// widgets/clinician_nav_bar.dart
import 'package:flutter/material.dart';
import 'package:ocutune_light_logger/theme/colors.dart';

class CustomerNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomerNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: navBar)),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        backgroundColor: navBar,
        selectedItemColor: white,
        unselectedItemColor: white.withAlpha(153),
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Søg',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mail_outlined),
            activeIcon: Icon(Icons.mail),
            label: 'Indbakke',
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