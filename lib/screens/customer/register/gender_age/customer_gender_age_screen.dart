import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../widgets/customer_widgets/customer_app_bar.dart';
import '../../../../widgets/universal/ocutune_next_step_button.dart';
import '/theme/colors.dart';
import 'customer_gender_age_controller.dart';
import 'customer_gender_age_form_field_widget.dart';

class CustomerGenderAgeScreen extends StatefulWidget {
  const CustomerGenderAgeScreen({super.key});

  @override
  State<CustomerGenderAgeScreen> createState() => _CustomerGenderAgeScreenState();
}

class _CustomerGenderAgeScreenState extends State<CustomerGenderAgeScreen> {
  String? selectedYear = '2000';
  bool yearChosen = false;
  String? selectedGender;

  final List<String> years = List.generate(
    DateTime.now().year - 1925 + 1,
        (index) => (1925 + index).toString(),
  );

  final List<Map<String, String>> genders = [
    {'label': 'Mand', 'value': 'male'},
    {'label': 'Kvinde', 'value': 'female'},
    {'label': 'Ikke angivet', 'value': 'other'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: generalBackground,
      appBar: const CustomerAppBar(
        showBackButton: true,
        title: 'Køn og alder',
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(top: 80.h, bottom: 300.h), // 👈 Skubber indholdet lidt ned
            child: CustomerGenderAgeForm(
              selectedGender: selectedGender,
              selectedYear: selectedYear,
              yearChosen: yearChosen,
              years: years,
              genders: genders,
              onGenderChanged: (value) => setState(() => selectedGender = value),
              onYearChanged: (value) => setState(() {
                selectedYear = value;
                yearChosen = true;
              }),
            ),
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 24.h, right: 8.w),
        child: OcutuneButton(
          type: OcutuneButtonType.floatingIcon,
          onPressed: () {
            CustomerGenderAgeController.handleGenderAgeSubmit(
              context: context,
              selectedGender: selectedGender,
              selectedYear: selectedYear,
              yearChosen: yearChosen,
            );
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
