// lib/screens/choose_chronotype_screen.dart

import 'package:flutter/material.dart';
import '/theme/colors.dart';
import 'choose_chronotype_form.dart';

class CustomerChooseChronotypeScreen extends StatelessWidget {
  const CustomerChooseChronotypeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: generalBackground,
      appBar: AppBar(
        backgroundColor: generalBackground,
        foregroundColor: Colors.white70,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const ChooseChronotypeForm(),
    );
  }
}
