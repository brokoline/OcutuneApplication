import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/services/services/api_services.dart';

import '../../../widgets/customer_widgets/customer_app_bar.dart';
import '../../../widgets/customer_widgets/customer_nav_bar.dart';
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
    print('🔍 _submit() called - oldPw=$oldPw, newPw=$newPw, confirmPw=$confirmPw');

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
      print('🌐 Calling ApiService.changePassword...');
      print('▶️ Sending JWT: "${widget.jwtToken}"');
      await ApiService.changePassword(
        oldPassword: oldPw,
        newPassword: newPw,
        jwtToken: widget.jwtToken,
      );
      print('✅ changePassword completed successfully');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adgangskode opdateret')),
      );
      Navigator.of(context).pop();
    } catch (e, st) {
      print('❌ changePassword error: $e\n$st');
      _showError('Fejl: $e');
    } finally {
      setState(() => _loading = false);
      print('🔧 _submit() finished, loading=$_loading');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  int _currentIndex = 4;
  void _onNavTap(int index) {
    print('🔧 _onNavTap: $index');
    // TODO: implement navigation
  }

  @override
  Widget build(BuildContext context) {
    print('🔧 build CustomerChangePasswordScreen');
    // width: 85% of screen
    final double contentWidth = 0.85.sw;

    return Scaffold(
      backgroundColor: generalBackground,
      appBar: CustomerAppBar(
        title: 'Skift adgangskode',
        showBackButton: true,
      ),
      body: Center(
        child: SizedBox(
          width: contentWidth,
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
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
