// lib/screens/customer/dashboard/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import '../../../models/customer_model.dart';

class CustomerProfileScreen extends StatelessWidget {
  final Customer profile;

  const CustomerProfileScreen({
    Key? key,
    required this.profile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String name  = '${profile.firstName} ${profile.lastName}';
    final int rmeq     = profile.rmeqScore;
    final int meq      = profile.meqScore ?? 0;

    return Scaffold(
      backgroundColor: generalBackground,
      appBar: AppBar(
        backgroundColor: navBar,
        title: const Text(
          'Profil',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white24,
              child: const Icon(Icons.person, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              'rMEQ: $rmeq   /  MEQ: $meq',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
