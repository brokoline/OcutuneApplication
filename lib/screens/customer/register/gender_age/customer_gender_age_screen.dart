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

  final List<String> years = [
    for (int i = 2025; i >= 1925; i--) i.toString(),
  ];



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
        title: 'Opret konto',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(top: 60.h, left: 24.w, right: 24.w, bottom: 24.h),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CustomerGenderAgeForm(
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
                ],
              ),
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
