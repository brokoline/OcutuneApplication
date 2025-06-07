import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/widgets/customer_widgets/customer_app_bar.dart';
import 'package:ocutune_light_logger/widgets/customer_widgets/customer_nav_bar.dart';


import '../customer_root_controller.dart';

/// Skærm for justering af notifikations-præferencer
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _tooMuchLight      = false;
  bool _tooLittleLight    = false;
  bool _dimLightReminder  = false;
  bool _bedtimeReminder   = false;
  bool _wakeOrDLmoAlarm   = false;
  bool _boostNotification = false;

  Widget _buildSwitch({
    required String            label,
    required bool              value,
    required ValueChanged<bool> onChanged,
  }) {
    return Column(
      children: [
        SwitchListTile(
          title: Text(
            label,
            style: TextStyle(color: Colors.white, fontSize: 16.sp),
          ),
          value: value,
          onChanged: onChanged,
          thumbColor: MaterialStateProperty.resolveWith((states) =>
          states.contains(MaterialState.selected)
              ? Colors.white
              : Colors.white70),
          trackColor: MaterialStateProperty.resolveWith((states) =>
          states.contains(MaterialState.selected)
              ? Colors.white38
              : Colors.white24),
          contentPadding: EdgeInsets.symmetric(horizontal: 20.w),
        ),
        Divider(color: Colors.white24, height: 1.h),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      builder: (_, __) => Scaffold(
        backgroundColor: generalBackground,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(80.h),
          child: CustomerAppBar(
            title: 'Notifikationer',
            showBackButton: true,
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
            children: [
              Card(
                color: generalBox,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  children: [
                    _buildSwitch(
                      label: 'For meget lys på uhensigtsmæssigt tidspunkt',
                      value: _tooMuchLight,
                      onChanged: (v) => setState(() => _tooMuchLight = v),
                    ),
                    _buildSwitch(
                      label: 'For lidt lys på uhensigtsmæssigt tidspunkt',
                      value: _tooLittleLight,
                      onChanged: (v) => setState(() => _tooLittleLight = v),
                    ),
                    _buildSwitch(
                      label: 'DIML-tidspunkt (lys-dæmpning)',
                      value: _dimLightReminder,
                      onChanged: (v) => setState(() => _dimLightReminder = v),
                    ),
                    _buildSwitch(
                      label: 'Påmindelse om sengetid efter DLMO',
                      value: _bedtimeReminder,
                      onChanged: (v) => setState(() => _bedtimeReminder = v),
                    ),
                    _buildSwitch(
                      label: 'Alarm for opvågning efter DLMO',
                      value: _wakeOrDLmoAlarm,
                      onChanged: (v) => setState(() => _wakeOrDLmoAlarm = v),
                    ),
                    _buildSwitch(
                      label: 'Boost-lys start/slut-notifikation',
                      value: _boostNotification,
                      onChanged: (v) => setState(() => _boostNotification = v),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Consumer<CustomerRootController>(
          builder: (context, controller, _) => CustomerNavBar(
            currentIndex: controller.currentIndex,
            onTap: (idx) {
              controller.setIndex(idx);
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ),
      ),
    );
  }
}
