import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ocutune_light_logger/theme/colors.dart';

class OcutunePatientDashboardTile extends StatelessWidget {
  final String label;
  final String? iconAsset;
  final IconData? icon;
  final VoidCallback onPressed;

  // optional subtitle under label
  final Widget? subtitle;

  // trailing-widget til f.eks. chevron
  final Widget? trailingWidget;

  const OcutunePatientDashboardTile({
    super.key,
    required this.label,
    this.iconAsset,
    this.icon,
    required this.onPressed,
    this.subtitle,
    this.trailingWidget,
  });

  @override
  Widget build(BuildContext context) {
    Widget leadingIcon;
    if (iconAsset != null) {
      leadingIcon = Image.asset(
        iconAsset!,
        width: 48.w,
        height: 48.h,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.broken_image, size: 40.sp, color: Colors.white70);
        },
      );
    } else if (icon != null) {
      leadingIcon = Icon(icon, size: 48.sp, color: Colors.white70);
    } else {
      leadingIcon = SizedBox(width: 48.w, height: 48.h);
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Material(
          color: generalBox,
          borderRadius: BorderRadius.circular(16.r),
          elevation: 0,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16.r),
            splashColor: const Color.fromRGBO(255, 255, 255, 0.15),
            highlightColor: const Color.fromRGBO(255, 255, 255, 0.05),
            hoverColor: const Color.fromRGBO(255, 255, 255, 0.03),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color.fromRGBO(255, 255, 255, 0.25),
                  width: 1.2.w,
                ),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Row(
                children: [
                  leadingIcon,
                  SizedBox(width: 16.w),

                  // Label + optional subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                            fontSize: 16.sp,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null) ...[
                          SizedBox(height: 4.h),
                          DefaultTextStyle(
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.white60,
                              fontWeight: FontWeight.w400,
                            ),
                            child: subtitle!,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // trailing-widget
                  if (trailingWidget != null) ...[
                    SizedBox(width: 16.w),
                    trailingWidget!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}