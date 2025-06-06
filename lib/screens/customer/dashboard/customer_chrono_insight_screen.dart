// lib/screens/customer/dashboard/nerd_info_screen.dart

import 'package:flutter/material.dart';
import 'package:ocutune_light_logger/theme/colors.dart';

class CustomerChronoInsightScreen extends StatelessWidget {
  const CustomerChronoInsightScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: generalBackground,
      appBar: AppBar(
        backgroundColor: navBar,
        title: const Text(
          'Nørdeside',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Nørdeside – detaljeret baggrundsinfo:',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            SizedBox(height: 12),
            Text(
              '- Videnskabelige referencer om søvn & lys\n'
                  '- Sensor-logs og rådata-graf\n'
                  '- Teknik-dokumentation (API-specifikationer)\n'
                  '- … og meget mere',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
