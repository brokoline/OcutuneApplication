import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../widgets/customer_widgets/drop_down_menu_widget.dart';
import '/theme/colors.dart';

class CustomerGenderAgeForm extends StatelessWidget {
  final String? selectedGender;
  final String? selectedYear;
  final bool yearChosen;
  final List<String> years;
  final List<Map<String, String>> genders;
  final void Function(String?) onGenderChanged;
  final void Function(String?) onYearChanged;

  const CustomerGenderAgeForm({
    super.key,
    required this.selectedGender,
    required this.selectedYear,
    required this.yearChosen,
    required this.years,
    required this.genders,
    required this.onGenderChanged,
    required this.onYearChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          "Hvornår er du født?",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 16.h),

        /// 🎯 Fødselsår med OcutuneDropdown
        OcutuneDropdown<String>(
          value: selectedYear,
          hintText: !yearChosen ? 'Vælg fødselsår' : null,
          onChanged: onYearChanged,
          items: years.map((year) {
            return DropdownMenuItem(
              value: year,
              child: Text(year),
            );
          }).toList(),
        ),

        SizedBox(height: 48.h),
        const Text(
          "Hvad er dit køn?",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 16.h),

        /// 🎯 Køn med OcutuneDropdown
        OcutuneDropdown<String>(
          value: selectedGender,
          hintText: 'Vælg køn',
          onChanged: onGenderChanged,
          items: genders.map((entry) {
            return DropdownMenuItem(
              value: entry['value'],
              child: Text(entry['label']!),
            );
          }).toList(),
        ),
      ],
    );
  }
}
