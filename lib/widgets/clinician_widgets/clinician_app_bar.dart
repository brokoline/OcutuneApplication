import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ocutune_light_logger/theme/colors.dart';

class ClinicianAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showLogout;
  final VoidCallback? onLogout;
  final String? title;  // Tilføjet titel parameter

  const ClinicianAppBar({
    super.key,
    this.showLogout = false,
    this.onLogout,
    this.title,  // Tilføjet til konstruktør
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: generalBackground,
      elevation: 0,
      centerTitle: true,
      title: title != null
          ? Text(
        title!,
        style: TextStyle(
          color: white,
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
        ),
      )
          : Image.asset(
        'assets/logo/logo_ocutune.png',
        height: 40.h,
        color: white,
      ),
      actions: showLogout
          ? [
        IconButton(
          icon: Icon(Icons.logout, size: 24.sp),
          color: Colors.white70,
          onPressed: onLogout,
        ),
      ]
          : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}