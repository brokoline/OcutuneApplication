import 'package:flutter/material.dart';
import '../../../../widgets/customer_widgets/customer_app_bar.dart';
import '/theme/colors.dart';
import 'choose_chronotype_form.dart';

class CustomerChooseChronotypeScreen extends StatelessWidget {
  const CustomerChooseChronotypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: generalBackground,
      appBar: const CustomerAppBar(
        showBackButton: true,
        title: 'Opret konto',
      ),
      body: const ChooseChronotypeForm(),
    );
  }
}
