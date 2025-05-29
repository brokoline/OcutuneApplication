import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
        _buildDropdown(
          context: context,
          value: selectedYear,
          hint: !yearChosen ? 'Vælg fødselsår' : null,
          items: years.map((year) {
            return DropdownMenuItem<String>(
              value: year,
              child: Text(year),
            );
          }).toList(),
          onChanged: onYearChanged,
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
        _buildDropdown(
          context: context,
          value: selectedGender,
          hint: 'Vælg køn',
          items: genders.map((entry) {
            return DropdownMenuItem<String>(
              value: entry['value'],
              child: Text(entry['label']!),
            );
          }).toList(),
          onChanged: onGenderChanged,
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required BuildContext context,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
    String? hint,
  }) {
    return Container(
      height: 56.h,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white24),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: darkGray, // Dropdown background
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: darkGray,
            // dropdownDirection removed for Flutter <3.16
            borderRadius: BorderRadius.circular(12.r),
            menuMaxHeight: 300.h,
            itemHeight: 48.h,
            iconEnabledColor: Colors.white,
            style: TextStyle(color: Colors.white, fontSize: 16.sp),
            hint: hint != null
                ? Text(hint, style: TextStyle(color: Colors.white70, fontSize: 16.sp))
                : null,
            items: items,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}
