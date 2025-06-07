import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/services/auth_storage.dart';

import 'customer_change_password_screen.dart';

class CustomerSettingsScreen extends StatelessWidget {
  const CustomerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      builder: (_, __) => Scaffold(
        backgroundColor: generalBackground,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(80.h),
          child: AppBar(
            backgroundColor: generalBackground,
            elevation: 0,
            centerTitle: true,
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
                  children: [
                    // Kort med alle indstillinger
                    Card(
                      color: generalBox,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        children: [
                          // Skift adgangskode
                          ListTile(
                            leading: Icon(Icons.lock_outline, color: Colors.white70, size: 24.sp),
                            title: Text('Skift adgangskode', style: TextStyle(color: Colors.white, fontSize: 16.sp)),
                            trailing: Icon(Icons.chevron_right, color: Colors.white54, size: 24.sp),
                            onTap: () async {
                              final token = await AuthStorage.getToken();
                              if (token == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Du er ikke logget ind')),
                                );
                                return;
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CustomerChangePasswordScreen(jwtToken: token),
                                ),
                              );
                            },
                          ),
                          Divider(color: Colors.white24, height: 1.h),

                          // Notifikationer
                          ListTile(
                            leading: Icon(Icons.notifications, color: Colors.white70, size: 24.sp),
                            title: Text('Notifikationer', style: TextStyle(color: Colors.white, fontSize: 16.sp)),
                            trailing: Icon(Icons.chevron_right, color: Colors.white54, size: 24.sp),
                            onTap: () {
                              // TODO: Naviger til NotificationSettingsScreen
                            },
                          ),
                          Divider(color: Colors.white24, height: 1.h),

                          // Om Oc utune
                          ListTile(
                            leading: Icon(Icons.info_outline, color: Colors.white70, size: 24.sp),
                            title: Text('Om Oc utune', style: TextStyle(color: Colors.white, fontSize: 16.sp)),
                            trailing: Icon(Icons.chevron_right, color: Colors.white54, size: 24.sp),
                            onTap: () {
                              // TODO: Vis About-dialog
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Log ud nederst
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: GestureDetector(
                  onTap: () {
                    // TODO: Udfør logout: slet token fra AuthStorage og naviger til login
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.exit_to_app, color: Colors.white70, size: 24.sp),
                      SizedBox(width: 8.w),
                      Text('Log ud', style: TextStyle(color: Colors.white70, fontSize: 16.sp)),
                    ],
                  ),
                ),
              ),

              // Version-tekst lige over nav-bar
              Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Text('Version 1.0.0', style: TextStyle(color: Colors.white54, fontSize: 13.sp)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
