import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../controller/customer_register_controller.dart';
import '../../../widgets/customer_widgets/customer_app_bar.dart';
import '../../../widgets/customer_widgets/customer_register_form_field_widget.dart';
import '/theme/colors.dart';
import '/widgets/ocutune_button.dart';
import '/widgets/ocutune_card.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final agreement = ValueNotifier(false);

    return Scaffold(
      backgroundColor: generalBackground,
      resizeToAvoidBottomInset: true,
      appBar: const CustomerAppBar(
        showBackButton: true,
        title: 'Opret konto',
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 24.h),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: IntrinsicHeight(
                        child: OcutuneCard(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 20.h,
                              horizontal: 16.w,
                            ),
                            child: RegisterFormFields(
                              firstNameController: firstNameController,
                              lastNameController: lastNameController,
                              emailController: emailController,
                              passwordController: passwordController,
                              confirmPasswordController: confirmPasswordController,
                              agreement: agreement,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 100.h), // plads til floating button
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 24.h, right: 8.w),
        child: OcutuneButton(
          type: OcutuneButtonType.floatingIcon,
          onPressed: () {
            RegisterController.handleRegister(
              context: context,
              firstNameController: firstNameController,
              lastNameController: lastNameController,
              emailController: emailController,
              passwordController: passwordController,
              confirmPasswordController: confirmPasswordController,
              agreement: agreement,
            );
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
