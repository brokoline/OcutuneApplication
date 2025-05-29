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
          style: TextStyle(color: Colors.white70, fontSize: 14.sp),
        )
            : null,
        items: _buildItems(),
        onChanged: onChanged,
        buttonStyleData: ButtonStyleData(
          height: 44.h, // 👈 mindre dropdownknap
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: Colors.white24),
          ),
        ),
        dropdownStyleData: DropdownStyleData(
          maxHeight: 240.h,
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
          offset: const Offset(0, 0),
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
          child: Center(child: items[i].child),
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
