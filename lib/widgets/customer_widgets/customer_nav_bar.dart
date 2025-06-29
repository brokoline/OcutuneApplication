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
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: navBar)),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        backgroundColor: navBar,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        items: [

          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Oversigt',
          ),

          const BottomNavigationBarItem(
            icon: Icon(Icons.local_activity_rounded),
            activeIcon: Icon(Icons.local_activity),
            label: 'Aktivitet',
          ),


          BottomNavigationBarItem(
            icon: Image.asset(
              "assets/icon/BLE-sensor-ikon.png",
              height: 50,
              width: 50,
              color: currentIndex == 2 ? Colors.white : Colors.white54,
            ),
            label: "Sensor",
          ),


          const BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_outline_sharp),
            activeIcon: Icon(Icons.lightbulb),
            label: 'Lysdetaljer',
          ),


          const BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            activeIcon: Icon(Icons.info),
            label: 'Chrono-info',
          ),


          const BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Indstillinger',
          ),
        ],
      ),
    );
  }
}
