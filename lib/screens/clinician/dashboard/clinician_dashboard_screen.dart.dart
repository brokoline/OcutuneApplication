import 'package:flutter/material.dart';

class ClinicianDashboardScreen extends StatelessWidget {
  const ClinicianDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kliniker Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.popUntil(context, ModalRoute.withName('/'));
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Velkommen til kliniker-dashboardet!',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
