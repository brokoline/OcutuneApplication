import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ocutune_light_logger/services/auth_storage.dart';
import 'package:ocutune_light_logger/controller/ble_controller.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/widgets/universal/ocutune_patient_dashboard_tile.dart';

class PatientDashboardScreen extends StatefulWidget {
  final String patientId;

  const PatientDashboardScreen({
    super.key,
    required this.patientId,
  });

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  late Future<String> _nameFuture;

  @override
  void initState() {
    super.initState();
    // Fetch user name
    _nameFuture = AuthStorage.getName().then((name) {
      final trimmed = name.trim();
      return (trimmed.isEmpty ? 'Bruger' : trimmed.split(' ').first);
    });
    BleController().monitorBluetoothState();
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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: generalBackground,
        foregroundColor: Colors.white70,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            color: Colors.white70,
            onPressed: () async {
              await AuthStorage.logout();
              if (!mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                    (_) => false,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<String>(
          future: _nameFuture,
          builder: (context, snapshot) {
            final greeting = 'Hej ${snapshot.data ?? 'Bruger'}';
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                  MediaQuery.of(context).size.height - kToolbarHeight - 32.h,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 18.h),
                      Center(
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/logo/logo_ocutune.png',
                              height: 100.h,
                              color: Colors.white70,
                            ),
                            SizedBox(height: 20.h),
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
                      SizedBox(height: 18.h),

                      ValueListenableBuilder<DiscoveredDevice?>(
                        valueListenable: BleController.connectedDeviceNotifier,
                        builder: (context, connectedDevice, _) {
                          final isConnected = connectedDevice != null;
                          return Padding(
                            padding: EdgeInsets.only(bottom: 12.h),
                            child: Material(
                              color: generalBox,
                              borderRadius: BorderRadius.circular(16.r),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16.r),
                                splashColor: const Color.fromRGBO(255, 255, 255, 0.15),
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/patient_sensor_settings',
                                    arguments: widget.patientId,
                                  );
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16.w, vertical: 18.h),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.25),
                                      width: 1.2.w,
                                    ),
                                    borderRadius: BorderRadius.circular(16.r),
                                  ),
                                  child: Row(
                                    children: [
                                      Image.asset(
                                        'assets/icon/BLE-sensor-ikon.png',
                                        width: 48.w,
                                        height: 48.h,
                                        color: Colors.white70,
                                      ),
                                      SizedBox(width: 16.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Sensorforbindelse',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 16.sp,
                                                fontWeight:
                                                FontWeight.w600,
                                              ),
                                            ),
                                            if (!isConnected)
                                              Padding(
                                                padding: EdgeInsets.only(
                                                    top: 4.h),
                                                child: Text(
                                                  'Ikke forbundet',
                                                  style: TextStyle(
                                                    fontSize: 13.sp,
                                                    color:
                                                    Colors.redAccent,
                                                    fontWeight:
                                                    FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),

                                      if (isConnected)
                                        ValueListenableBuilder<int>(
                                          valueListenable:
                                          BleController.batteryNotifier,
                                          builder: (context, battery, _) {
                                            final color =
                                            _batteryColor(battery);
                                            return Row(
                                              mainAxisSize:
                                              MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  _batteryIcon(battery),
                                                  color: color,
                                                  size: 20.sp,
                                                ),
                                                SizedBox(width: 6.w),
                                                Text(
                                                  '$battery%',
                                                  style: TextStyle(
                                                    fontSize: 13.sp,
                                                    color: color,
                                                    fontWeight:
                                                    FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: 12.h),

                      OcutunePatientDashboardTile(
                        label: 'Registrér en aktivitet',
                        iconAsset: 'assets/icon/activity-log-icon.png',
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/patient/activities',
                          );
                        },
                      ),

                      OcutunePatientDashboardTile(
                        label: 'Indbakke',
                        iconAsset: 'assets/icon/mail-outline.png',
                        onPressed: () async {
                          final jwt =
                          await AuthStorage.getTokenPayload();
                          final patientId = jwt['id'];
                          Navigator.pushNamed(
                            context,
                            '/patient/inbox',
                            arguments: patientId,
                          );
                        },
                      ),

                      Spacer(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
