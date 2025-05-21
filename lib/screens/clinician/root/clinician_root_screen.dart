import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import '../../../services/auth_storage.dart';
import '../../../services/controller/clinician_dashboard_controller.dart';
import '../../../widgets/clinician_widgets/clinician_nav_bar.dart';
import '../../../widgets/clinician_widgets/clinician_app_bar.dart';
import '../search/clinician_search_screen.dart';
import '../messages/clinician_inbox_screen.dart';

class ClinicianRootScreen extends StatefulWidget {
  const ClinicianRootScreen({Key? key}) : super(key: key);

  @override
  State<ClinicianRootScreen> createState() => _ClinicianRootScreenState();
}

class _ClinicianRootScreenState extends State<ClinicianRootScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    _ClinicianDashboardContent(),
    ClinicianSearchScreen(),
    ClinicianInboxScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkToken();
    _initializeController();
  }

  void _initializeController() {
    final controller = Provider.of<ClinicianDashboardController>(context, listen: false);
    controller.loadInitialData();
  }

  void _checkToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      });
    }
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: generalBackground,
      appBar: ClinicianAppBar(
        showLogout: _currentIndex == 0, // Kun vis logud på hovedsiden
        onLogout: _logout,
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: ClinicianNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _ClinicianDashboardContent extends StatelessWidget {
  const _ClinicianDashboardContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint('🌀 Building ClinicianDashboardContent');

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<String>(
              future: AuthStorage.getClinicianName(),
              builder: (context, snapshot) {
                return Text(
                  snapshot.hasData ? 'Hej ${snapshot.data!}' : 'Kliniker Dashboard',
                  style: TextStyle(
                    color: white,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
            SizedBox(height: 24.h),

            Text(
              'Notifikationer',
              style: TextStyle(
                color: white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12.h),

            Expanded(
              child: Consumer<ClinicianDashboardController>(
                builder: (context, controller, child) {
                  if (controller.notifications.isEmpty) {
                    return Center(
                      child: Text(
                        'Ingen nye notifikationer',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16.sp,
                        ),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () => controller.refreshNotifications(),
                    child: ListView.separated(
                      itemCount: controller.notifications.length,
                      separatorBuilder: (context, index) => SizedBox(height: 8.h),
                      itemBuilder: (context, index) {
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
                              controller.notifications[index],
                              style: TextStyle(
                                color: white,
                                fontSize: 14.sp,
                              ),
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              size: 16.sp,
                              color: Colors.white70,
                            ),
                            onTap: () => controller.handleNotificationTap(index),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}