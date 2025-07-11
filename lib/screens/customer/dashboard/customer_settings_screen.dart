import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/services/auth_storage.dart';
import '../customer_root_controller.dart';
import 'customer_about_ocutune_screen.dart';
import 'customer_change_password_screen.dart';
import 'customer_notification_settings_screen.dart';
import 'customer_profile_screen.dart';
import 'customer_report_issue_screen.dart';

class CustomerSettingsScreen extends StatelessWidget {
  const CustomerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      builder: (_, __) => Scaffold(
        backgroundColor: generalBackground,

        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding:
                  EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
                  children: [
                    Card(
                      color: generalBox,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r)),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(Icons.manage_accounts, color: Colors.white70, size: 24.sp),
                            title: Text(
                              'Profiloplysninger',
                              style: TextStyle(color: Colors.white70, fontSize: 16.sp),
                            ),
                            trailing: Icon(Icons.chevron_right, color: Colors.white54, size: 24.sp),
                            onTap: () {
                              final rootCtrl = context.read<CustomerRootController>();
                              final customer = rootCtrl.profile;
                              final chrono   = rootCtrl.chronoModel;

                              if (customer == null || chrono == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Profilen indlæses lige nu…')),
                                );
                                return;
                              }

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChangeNotifierProvider.value(
                                    value: rootCtrl,
                                    child: CustomerProfileScreen(
                                      profile: customer,
                                      chronoModel: chrono,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const Divider(color: Colors.white24, height: 1),


                          ListTile(
                            leading: Icon(Icons.lock_outline,
                                color: Colors.white70, size: 24.sp),
                            title: Text('Skift adgangskode',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 16.sp)),
                            trailing: Icon(Icons.chevron_right,
                                color: Colors.white54, size: 24.sp),
                            onTap: () async {
                              final token = await AuthStorage.getToken();
                              if (token == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Du er ikke logget ind')),
                                );
                                return;
                              }

                              final rootCtrl = context.read<CustomerRootController>();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChangeNotifierProvider.value(
                                    value: rootCtrl,
                                    child: CustomerChangePasswordScreen(
                                        jwtToken: token),
                                  ),
                                ),
                              );
                            },
                          ),
                          const Divider(color: Colors.white24, height: 1),

                          ListTile(
                            leading: Icon(Icons.notifications_active,
                                color: Colors.white70, size: 24.sp),
                            title: Text('Notifikationer',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 16.sp)),
                            trailing: Icon(Icons.chevron_right,
                                color: Colors.white54, size: 24.sp),
                            onTap: () {
                              final rootCtrl = context.read<CustomerRootController>();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChangeNotifierProvider.value(
                                    value: rootCtrl,
                                    child: const NotificationSettingsScreen(),
                                  ),
                                ),
                              );
                            },
                          ),
                          const Divider(color: Colors.white24, height: 1),

                          ListTile(
                            leading: Icon(Icons.report_problem, color: Colors.white70, size: 24.sp),
                            title: Text('Indrapporter problem', style: TextStyle(color: Colors.white70, fontSize: 16.sp)),
                            trailing: Icon(Icons.chevron_right, color: Colors.white54, size: 24.sp),
                            onTap: () {
                              final rootCtrl = context.read<CustomerRootController>();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChangeNotifierProvider.value(
                                    value: rootCtrl,
                                    child: const CustomerReportIssueScreen(),
                                  ),
                                ),
                              );
                            },
                          ),
                          const Divider(color: Colors.white24, height: 1),

                          ListTile(
                            leading: Icon(Icons.list_alt, color: Colors.white70, size: 24.sp),
                            title: Text('Om Ocutune', style: TextStyle(color: Colors.white70, fontSize: 16.sp)),
                            trailing: Icon(Icons.chevron_right, color: Colors.white54, size: 24.sp),
                            onTap: () {
                              final rootCtrl = context.read<CustomerRootController>();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChangeNotifierProvider.value(
                                    value: rootCtrl,
                                    child: const CustomerAboutOcutuneScreen(),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: GestureDetector(
                  onTap: () async {
                    await AuthStorage.logoutCustomer();
                    Navigator.of(context).pushReplacementNamed('/login');
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.exit_to_app,
                        color: Colors.white70,
                        size: 24.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Log ud',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Text('Version 1.0.0',
                    style: TextStyle(color: Colors.white54, fontSize: 13.sp)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
