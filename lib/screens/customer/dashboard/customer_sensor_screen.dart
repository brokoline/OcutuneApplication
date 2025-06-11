import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/controller/ble_controller.dart';


import 'customer_sensor_controller.dart';

class CustomerSensorScreen extends StatefulWidget {
  final String customerId;

  const CustomerSensorScreen({super.key, required this.customerId});

  @override
  State<CustomerSensorScreen> createState() => _CustomerSensorScreenState();
}

class _CustomerSensorScreenState extends State<CustomerSensorScreen> {
  late final CustomerSensorController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CustomerSensorController(customerId: widget.customerId);
    _controller.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ---- DYNAMISK BATTERI-IKON & FARVE ----
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
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      builder: (_, __) => Scaffold(
        backgroundColor: generalBackground,
        body: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 16.h),
              Text(
                'Status',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: generalBox,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 1.h),
                    ValueListenableBuilder<bool>(
                      valueListenable: BleController.isBluetoothOn,
                      builder: (context, isOn, _) {
                        if (!isOn) {
                          return Text(
                            'Bluetooth er slået fra.',
                            style: TextStyle(color: Colors.white, fontSize: 15.sp),
                          );
                        }

                        return ValueListenableBuilder<DiscoveredDevice?>(
                          valueListenable: BleController.connectedDeviceNotifier,
                          builder: (context, device, _) {
                            final connected = device != null;
                            return ValueListenableBuilder<int>(
                              valueListenable: BleController.batteryNotifier,
                              builder: (context, battery, _) {
                                return connected
                                    ? Row(
                                  children: [
                                    Text(
                                      'Forbundet til: ${device!.name}  ',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15.sp,
                                      ),
                                    ),
                                    Icon(
                                      _batteryIcon(battery),
                                      color: _batteryColor(battery),
                                      size: 20.sp,
                                    ),
                                    SizedBox(width: 6.w),
                                    Text(
                                      '$battery%',
                                      style: TextStyle(
                                        color: _batteryColor(battery),
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                )
                                    : Text(
                                  _controller.devices.isEmpty
                                      ? 'Bluetooth er slået til.\nIngen sensor forbundet.'
                                      : 'Bluetooth er slået til.\n${_controller.devices.length} enhed(er) fundet.',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 15.sp),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              ValueListenableBuilder<DiscoveredDevice?>(
                valueListenable: BleController.connectedDeviceNotifier,
                builder: (context, device, _) {
                  if (device == null) {
                    return ElevatedButton.icon(
                      onPressed: () =>
                          _controller.requestPermissionsAndScan(context),
                      icon: const Icon(Icons.bluetooth_searching),
                      label: const Text('Søg efter sensor'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white70,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                      ),
                    );
                  }

                  return ElevatedButton.icon(
                    onPressed: () =>
                        _controller.disconnectFromDevice(context),
                    icon: const Icon(Icons.link_off),
                    label: const Text('Afbryd forbindelse'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: defaultBoxRed,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 24.h),
              Text(
                'Tilgængelige enheder',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8.h),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: generalBox,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: ValueListenableBuilder<List<DiscoveredDevice>>(
                    valueListenable: _controller.devicesNotifier,
                    builder: (context, devices, _) {
                      if (devices.isEmpty) {
                        return Center(
                          child: Text(
                            'Ingen enheder fundet',
                            style: TextStyle(color: Colors.white54, fontSize: 14.sp),
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: devices.length,
                        itemBuilder: (context, index) {
                          final device = devices[index];
                          return Column(
                            children: [
                              if (index > 0)
                                const Divider(
                                  height: 1,
                                  thickness: 0.5,
                                  color: Color.fromRGBO(255, 255, 255, 0.1),
                                ),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    final connectedDevice =
                                        BleController.connectedDeviceNotifier.value;
                                    if (connectedDevice == null ||
                                        connectedDevice.id != device.id) {
                                      _controller.connectToDevice(
                                          context, device);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(8.r),
                                  hoverColor: const Color.fromRGBO(
                                      255, 255, 255, 0.1),
                                  splashColor: const Color.fromRGBO(
                                      255, 255, 255, 0.2),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16.w, vertical: 12.h),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.bluetooth,
                                            color: Colors.white70, size: 20),
                                        SizedBox(width: 16.w),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                device.name.isNotEmpty
                                                    ? device.name
                                                    : 'Ukendt enhed',
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 16.sp,
                                                ),
                                              ),
                                              Text(
                                                device.id,
                                                style: TextStyle(
                                                  color: Color.fromRGBO(
                                                      255, 255, 255, 0.6),
                                                  fontSize: 12.sp,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        ValueListenableBuilder<DiscoveredDevice?>(
                                          valueListenable:
                                          BleController.connectedDeviceNotifier,
                                          builder:
                                              (context, connectedDevice, _) {
                                            if (connectedDevice?.id == device.id) {
                                              return const Icon(
                                                Icons.link,
                                                color: Colors.white70,
                                                size: 20,
                                              );
                                            }
                                            return const SizedBox();
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
