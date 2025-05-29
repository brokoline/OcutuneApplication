import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '/widgets/universal/ocutune_textfield.dart';

class RegisterFormFields extends StatelessWidget {
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final ValueNotifier<bool> agreement;

  const RegisterFormFields({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.agreement,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: agreement,
      builder: (context, agreed, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OcutuneTextField(label: 'Fornavn', controller: firstNameController),
          SizedBox(height: 16.h),
          OcutuneTextField(label: 'Efternavn', controller: lastNameController),
          SizedBox(height: 16.h),
          OcutuneTextField(label: 'E-mail', controller: emailController),
          SizedBox(height: 16.h),
          OcutuneTextField(
            label: 'Adgangskode',
            controller: passwordController,
            isPassword: true,
          ),
          SizedBox(height: 16.h),
          OcutuneTextField(
            label: 'Bekræft adgangskode',
            controller: confirmPasswordController,
            isPassword: true,
          ),
          SizedBox(height: 24.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: agreement.value,
                onChanged: (value) => agreement.value = value ?? false,
                activeColor: Colors.white70,
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 4.h),
                  child: RichText(
                    text: TextSpan(
                      text: 'Jeg accepterer ',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13.sp,
                      ),
                      children: [
                        TextSpan(
                          text: 'Vilkår og betingelser',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            color: Colors.white70,
                            fontSize: 13.sp,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => Navigator.pushNamed(context, '/terms'),
                        ),
                        TextSpan(
                          text: ' og ',
                          style: TextStyle(fontSize: 13.sp),
                        ),
                        TextSpan(
                          text: 'Privatlivspolitik',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            color: Colors.white70,
                            fontSize: 13.sp,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => Navigator.pushNamed(context, '/privacy'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
