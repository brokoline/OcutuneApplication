import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '/theme/colors.dart';

class OcutuneDropdown<T> extends StatelessWidget {
  final T? value;
  final String? hintText;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;
  final double? maxHeight;

  const OcutuneDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hintText,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton2<T>(
        isExpanded: true,
        value: value,
        hint: hintText != null
            ? Text(
          hintText!,
          style: TextStyle(color: Colors.white70, fontSize: 14.sp),
        )
            : null,
        items: _buildItems(),
        onChanged: onChanged,
        buttonStyleData: ButtonStyleData(
          height: 55.h,
          width: 260.w,
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: Colors.white24),
          ),
        ),
        dropdownStyleData: DropdownStyleData(
          maxHeight: maxHeight ?? 200.h,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            color: darkGray,
            borderRadius: BorderRadius.circular(10.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        iconStyleData: IconStyleData(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
          iconSize: 20.sp,
        ),
        style: TextStyle(color: Colors.white, fontSize: 14.sp),
      ),
    );
  }

  List<DropdownMenuItem<T>> _buildItems() {
    List<DropdownMenuItem<T>> styledItems = [];
    for (int i = 0; i < items.length; i++) {
      styledItems.add(
        DropdownMenuItem<T>(
          value: items[i].value,
          child: SizedBox(
            height: 32.h,
            child: Center(child: items[i].child),
          ),
        ),
      );
      if (i < items.length - 1) {
        styledItems.add(
          DropdownMenuItem<T>(
            enabled: false,
            child: SizedBox(
              height: 1.h,
              child: Divider(
                color: Colors.white12,
                thickness: 0.3,
                height: 0.3,
                indent: 4.w,
                endIndent: 4.w,
              ),
            ),
          ),
        );
      }
    }
    return styledItems;
  }
}

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
        /// Årstal
        OcutuneDropdown<String>(
          value: selectedYear,
          hintText: yearChosen ? null : 'Vælg fødselsår',
          onChanged: onYearChanged,
          maxHeight: 3 * 100.h + 2 * 1.h, // 3 synlige år + 2 dividers
          items: years.map((year) {
            return DropdownMenuItem(
              value: year,
              child: Text(year, style: TextStyle(fontSize: 14.sp)),
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
        /// Køn
        OcutuneDropdown<String>(
          value: selectedGender,
          hintText: 'Vælg køn',
          onChanged: onGenderChanged,
          maxHeight: 32.h * genders.length + 1.h * (genders.length - 1),
          items: genders.map((entry) {
            return DropdownMenuItem(
              value: entry['value'],
              child: Text(entry['label']!, style: TextStyle(fontSize: 14.sp)),
            );
          }).toList(),
        ),
      ],
    );
  }
}
