import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../widgets/customer_widgets/drop_down_menu_widget.dart';

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
    final double rowHeight = 48.h;
    final double dividerH  = 1.h;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
        SizedBox(height: 12.h),

        OcutuneDropdown<String>(
          value: selectedYear,
          hintText: yearChosen ? null : 'Vælg fødselsår',
          onChanged: onYearChanged,
          maxHeight: 4 * rowHeight + 2 * dividerH,
          items: years.map((year) {
            return DropdownMenuItem<String>(
              value: year,
              child: Text(year, style: TextStyle(fontSize: 14.sp)),
            );
          }).toList(),
        ),

        SizedBox(height: 32.h),

        const Text(
          "Hvad er dit køn?",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 12.h),

        OcutuneDropdown<String>(
          value: selectedGender,
          hintText: 'Vælg køn',
          onChanged: onGenderChanged,
          maxHeight: genders.length * rowHeight
              + (genders.length - 1) * dividerH,
          items: genders.map((entry) {
            return DropdownMenuItem<String>(
              value: entry['value'],
              child: Text(entry['label']!, style: TextStyle(fontSize: 14.sp)),
            );
          }).toList(),
        ),
      ],
    );
  }
}
