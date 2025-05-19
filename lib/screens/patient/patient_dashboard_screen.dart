import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ocutune_light_logger/services/auth_storage.dart';
import 'package:ocutune_light_logger/services/ble_controller.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/widgets/ocutune_patient_dashboard_tile.dart';

class PatientDashboardScreen extends StatefulWidget {
  final int patientId;

  const PatientDashboardScreen({super.key, required this.patientId});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  late Future<String> _nameFuture;

  @override
  void initState() {
    super.initState();
    _nameFuture = AuthStorage.getName().then((name) {
      if (name.trim().isEmpty) return 'Bruger';
      return name.split(' ').first;
    });
  }

  Color _batteryColor(int level) {
    if (level >= 25) return Colors.green;
    if (level >= 10) return Colors.orange;
    return Colors.red;
  }

  IconData _batteryIcon(int level) {
    if (level > 90) return Icons.battery_full;
    if (level > 60) return Icons.battery_6_bar;
    if (level > 40) return Icons.battery_4_bar;
    if (level > 20) return Icons.battery_2_bar;
    return Icons.battery_alert;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: generalBackground,
      body: SafeArea(
        child: FutureBuilder<String>(
          future: _nameFuture,
          builder: (context, snapshot) {
            final greeting = 'Hej ${snapshot.data ?? 'Bruger'}';

            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(height: 48.h),
                            Center(
                              child: Column(
                                children: [
                                  Image.asset(
                                    'assets/logo/logo_ocutune.png',
                                    height: 100.h,
                                    color: Colors.white70,
                                  ),
                                  SizedBox(height: 16.h),
                                  Text(
                                    greeting,
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 22.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 48.h),

                            // Sensorindstillinger med live batteriindikator
                            ValueListenableBuilder<int>(
                              valueListenable: BleController.batteryNotifier,
                              builder: (context, battery, _) {
                                final connected = battery > 0;

                                return OcutunePatientDashboardTile(
                                  label: 'Sensorindstillinger',
                                  iconAsset: 'assets/icon/BLE-sensor-ikon.png',
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/patient_sensor_settings',
                                      arguments: widget.patientId,
                                    );
                                  },
                                  trailingWidget: connected
                                      ? Row(
                                    children: [
                                      Icon(
                                        _batteryIcon(battery),
                                        color: _batteryColor(battery),
                                        size: 20.sp,
                                      ),
                                      SizedBox(width: 6.w),
                                      Text(
                                        '$battery%',
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          color: _batteryColor(battery),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  )
                                      : null,
                                );
                              },
                            ),

                            // Aktivitetsknap
                            OcutunePatientDashboardTile(
                              label: 'Registrér en aktivitet',
                              iconAsset: 'assets/icon/activity-log-icon.png',
                              onPressed: () {
                                Navigator.pushNamed(context, '/patient/activities');
                              },
                            ),

                            // Kontaktknap
                            OcutunePatientDashboardTile(
                              label: 'Kontakt din behandler',
                              iconAsset: 'assets/icon/mail-outline.png',
                              onPressed: () {
                                Navigator.pushNamed(context, '/patient/inbox');
                              },
                            ),

                            const Spacer(),

                            // Log ud knap
                            Center(
                              child: SizedBox(
                                width: 100.w,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    await AuthStorage.logout();
                                    if (!context.mounted) return;
                                    Navigator.pushNamedAndRemoveUntil(
                                        context, '/login', (_) => false);
                                  },
                                  icon: const Icon(Icons.logout),
                                  label: const Text('Log ud'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    foregroundColor: Colors.white70,
                                    padding: EdgeInsets.symmetric(vertical: 12.h),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 32.h),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
