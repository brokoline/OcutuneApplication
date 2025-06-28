import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../theme/colors.dart';
import '../../../services/auth_storage.dart';
import '../../../widgets/clinician_widgets/clinician_nav_bar.dart';
import '../../../widgets/clinician_widgets/clinician_app_bar.dart';
import '../messages/clinician_inbox_screen.dart';
import '../profile/clinician_profile_screen.dart';
import '../search/clinician_search_screen.dart';
import 'clinician_root_controller.dart';

class ClinicianRootScreen extends StatefulWidget {
  const ClinicianRootScreen({super.key});

  @override
  State<ClinicianRootScreen> createState() => _ClinicianRootScreenState();
}

class _ClinicianRootScreenState extends State<ClinicianRootScreen> {
  int _currentIndex = 0;

  static const _screens = <Widget>[
    _ClinicianDashboardContent(),
    ClinicianSearchScreen(),
    ClinicianInboxScreen(),
    ClinicianProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _ensureLoggedIn();
  }

  Future<void> _ensureLoggedIn() async {
    final token = await AuthStorage.getToken();
    if (token == null && mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ClinicianRootController>(
      create: (_) => ClinicianRootController(),
      child: Scaffold(
        backgroundColor: generalBackground,
        appBar: const ClinicianAppBar(),
        body: _screens[_currentIndex],
        bottomNavigationBar: ClinicianNavBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
        ),
      ),
    );
  }
}

class _ClinicianDashboardContent extends StatelessWidget {
  const _ClinicianDashboardContent();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        child: Consumer<ClinicianRootController>(
          builder: (ctx, ctrl, _) {
            if (ctrl.loading) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white70),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ctrl.welcomeText,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  'Notifikationer',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12.h),
                Expanded(
                  child: ctrl.notifications.isEmpty
                      ? Center(
                    child: Text(
                      'Ingen nye notifikationer',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16.sp,
                      ),
                    ),
                  )
                      : RefreshIndicator(
                    onRefresh: ctrl.refreshNotifications,
                    child: ListView.separated(
                      itemCount: ctrl.notifications.length,
                      separatorBuilder: (_, __) =>
                          SizedBox(height: 8.h),
                      itemBuilder: (context, idx) {
                        return Container(
                          decoration: BoxDecoration(
                            color: generalBox,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: darkGray),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 8.h,
                            ),
                            title: Text(
                              ctrl.notifications[idx],
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.sp,
                              ),
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              size: 16.sp,
                              color: Colors.white70,
                            ),
                            onTap: () => ctrl.handleNotificationTap(idx),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
