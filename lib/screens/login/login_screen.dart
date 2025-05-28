import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/widgets/ocutune_textfield.dart';
import 'package:ocutune_light_logger/widgets/ocutune_button.dart';
import 'package:ocutune_light_logger/widgets/ocutune_card.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: generalBackground,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 50.h),
                OcutuneCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/logo/logo_ocutune.png',
                        width: 100.w,
                        color: Colors.white70,
                      ),
                      SizedBox(height: 32.h),
                      OcutuneTextField(
                        label: 'E-mail',
                        controller: emailController,
                        labelStyle: TextStyle(fontSize: 16.sp),
                      ),
                      SizedBox(height: 16.h),
                      OcutuneTextField(
                        label: 'Adgangskode',
                        isPassword: true,
                        controller: passwordController,
                        labelStyle: TextStyle(fontSize: 16.sp),
                      ),
                      SizedBox(height: 24.h),
                      OcutuneButton(
                        text: 'Log ind',
                        onPressed: () {
                          // handle sign in
                        },
                        type: OcutuneButtonType.primary,
                      ),
                      SizedBox(height: 1.h),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'Glemt adgangskode?',
                          style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/register');
                        },
                        child: Text(
                          'Ikke registreret? Opret bruger',
                          style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10.h),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/chooseAccess');
                  },
                  child: Text(
                    'Kliniker eller patient? Log ind her',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
                SizedBox(height: 1.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
