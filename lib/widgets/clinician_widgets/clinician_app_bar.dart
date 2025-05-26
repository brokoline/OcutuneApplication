import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ocutune_light_logger/theme/colors.dart';

class ClinicianAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showLogout;
  final VoidCallback? onLogout;
  final String? title;
  final String? subtitle;
  final bool showBackButton;

  const ClinicianAppBar({
    super.key,
    this.showLogout = false,
    this.onLogout,
    this.title,
    this.subtitle,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      leading: showBackButton && Navigator.canPop(context)
          ? IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      )
          : null,
      backgroundColor: generalBackground,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      centerTitle: true,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (title != null)
            Text(
              title!,
              style: TextStyle(
                color: white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
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
