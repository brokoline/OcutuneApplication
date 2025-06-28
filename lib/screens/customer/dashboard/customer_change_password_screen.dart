import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/services/services/api_services.dart';
import 'package:ocutune_light_logger/widgets/customer_widgets/customer_app_bar.dart';
import 'package:ocutune_light_logger/widgets/customer_widgets/customer_nav_bar.dart';

import '../customer_root_controller.dart';
import '../../../widgets/universal/ocutune_textfield.dart';

class CustomerChangePasswordScreen extends StatefulWidget {
  final String jwtToken;
  const CustomerChangePasswordScreen({super.key, required this.jwtToken});

  @override
  State<CustomerChangePasswordScreen> createState() => _CustomerChangePasswordScreenState();
}

class _CustomerChangePasswordScreenState extends State<CustomerChangePasswordScreen> {
  final _oldPwController = TextEditingController();
  final _newPwController = TextEditingController();
  final _confirmPwController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _oldPwController.dispose();
    _newPwController.dispose();
    _confirmPwController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final oldPw = _oldPwController.text;
    final newPw = _newPwController.text;
    final confirmPw = _confirmPwController.text;

    if (oldPw.isEmpty) {
      _showError('Indtast din nuværende adgangskode');
      return;
    }
    if (newPw.length < 6) {
      _showError('Ny adgangskode skal være mindst 6 tegn');
      return;
    }
    if (newPw != confirmPw) {
      _showError('Adgangskoderne matcher ikke');
      return;
    }

    setState(() => _loading = true);
    try {
      await ApiService.changePassword(
        oldPassword: oldPw,
        newPassword: newPw,
        jwtToken: widget.jwtToken,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adgangskode opdateret')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      _showError('Fejl: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _onNavTap(int index) {
    // 1) Skift fane i dashboard-controller
    Provider.of<CustomerRootController>(context, listen: false).setIndex(index);
    // 2) Luk alle undersider og kom tilbage til root
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    // content width: 85% of screen
    final double contentWidth = 0.85.sw;

    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      builder: (_, __) => Scaffold(
        backgroundColor: generalBackground,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(80.h),
          child: CustomerAppBar(
            title: 'Skift adgangskode',
            showBackButton: true,
          ),
        ),

        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              top: 32.h,
              left: (MediaQuery.of(context).size.width - contentWidth) / 2,
              right: (MediaQuery.of(context).size.width - contentWidth) / 2,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Her kan du ændre din adgangskode',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30.h),
                OcutuneTextField(
                  label: 'Gammel adgangskode',
                  controller: _oldPwController,
                  obscureText: true,
                ),
                SizedBox(height: 20.h),
                OcutuneTextField(
                  label: 'Ny adgangskode',
                  controller: _newPwController,
                  obscureText: true,
                ),
                SizedBox(height: 20.h),
                OcutuneTextField(
                  label: 'Bekræft ny adgangskode',
                  controller: _confirmPwController,
                  obscureText: true,
                ),
                SizedBox(height: 40.h),
                SizedBox(
                  width: contentWidth,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: generalBox,
                      foregroundColor: Colors.white70,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    child: _loading
                        ? SizedBox(
                      height: 24.h,
                      width: 24.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white70,
                      ),
                    )
                        : Text(
                      'Opdater adgangskode',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ),
        bottomNavigationBar: CustomerNavBar(
          currentIndex: context.watch<CustomerRootController>().currentIndex,
          onTap: _onNavTap,
        ),
      ),
    );
  }
}
