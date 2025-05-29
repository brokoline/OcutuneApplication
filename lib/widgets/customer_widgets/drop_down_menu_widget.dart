import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '/theme/colors.dart';

class OcutuneDropdown<T> extends StatelessWidget {
  final T? value;
  final String? hintText;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;

  const OcutuneDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hintText,
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
          style: TextStyle(color: Colors.white70, fontSize: 16.sp),
        )
            : null,
        items: _buildItems(),
        onChanged: onChanged,
        buttonStyleData: ButtonStyleData(
          height: 56.h,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.white24),
          ),
        ),
        dropdownStyleData: DropdownStyleData(
          maxHeight: 300.h,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            color: darkGray,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          offset: const Offset(0, 0),
        ),
        iconStyleData: IconStyleData(
          icon: const Icon(
              Icons.keyboard_arrow_down_rounded, color: Colors.white),
          iconSize: 24.sp,
        ),
        style: TextStyle(color: Colors.white, fontSize: 16.sp),
      ),
    );
  }

  List<DropdownMenuItem<T>> _buildItems() {
    List<DropdownMenuItem<T>> styledItems = [];
    for (int i = 0; i < items.length; i++) {
      styledItems.add(
        DropdownMenuItem<T>(
          value: items[i].value,
          child: Center(child: items[i].child),
        ),
      );

      // Tilføj tynd divider efter hvert item, undtagen sidste
      if (i < items.length - 1) {
        styledItems.add(
          DropdownMenuItem<T>(
            enabled: false,
            child: SizedBox(
              height: 2.h,
              child: Divider(
                color: Colors.white12,
                thickness: 0.4,
                height: 0.4,
                indent: 6.w,
                endIndent: 6.w,
              ),
            ),
          ),
        );
      }
    }
    return styledItems;
  }
}