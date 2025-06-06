// lib/screens/customer/dashboard/light_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:ocutune_light_logger/theme/colors.dart';

class CustomerLightDetailScreen extends StatelessWidget {
  const CustomerLightDetailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: generalBackground,
      body: const Center(
        child: Text(
          'Her kan du se dybdegående lys-data, grafer mv.',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ),
    );
  }
}
