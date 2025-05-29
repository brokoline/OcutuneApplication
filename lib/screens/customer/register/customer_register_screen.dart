import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'customer_register_controller.dart';
import '../../../widgets/customer_widgets/customer_app_bar.dart';
import '../../../widgets/customer_widgets/customer_register_form_field_widget.dart';
import '/theme/colors.dart';
import '../../../widgets/ocutune_next_step_button.dart';
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

          return SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 24.w,
              right: 24.w,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
              top: keyboardOpen ? 12.h : 24.h,
            ),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OcutuneCard(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 8.h,
                        horizontal: 6.w,
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
                SizedBox(height: 100.h),
              ],
            ),
          );
        },
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
