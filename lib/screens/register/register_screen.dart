import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '/theme/colors.dart';
import '/widgets/ocutune_button.dart';
import '/widgets/ocutune_textfield.dart';
import '/widgets/ocutune_card.dart';

import 'dart:io';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isIOS = Platform.isIOS;

    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final agreement = ValueNotifier(false);

    final formFields = ValueListenableBuilder<bool>(
      valueListenable: agreement,
      builder: (context, agreed, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account Setup',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          OcutuneTextField(label: 'First name', controller: firstNameController),
          const SizedBox(height: 16),
          OcutuneTextField(label: 'Last name', controller: lastNameController),
          const SizedBox(height: 16),
          OcutuneTextField(label: 'E-mail', controller: emailController),
          const SizedBox(height: 16),
          OcutuneTextField(label: 'Password', controller: passwordController, isPassword: true),
          const SizedBox(height: 16),
          OcutuneTextField(label: 'Confirm password', controller: confirmPasswordController, isPassword: true),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: agreed,
                onChanged: (value) => agreement.value = value ?? false,
                activeColor: Colors.white,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: RichText(
                    text: TextSpan(
                      text: 'I agree with the ',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      children: [
                        TextSpan(
                          text: 'Terms Conditions',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            color: Colors.white,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.pushNamed(context, '/terms');
                            },
                        ),
                        const TextSpan(text: ' & '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            color: Colors.white,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.pushNamed(context, '/privacy');
                            },
                        ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 64),
        ],
      ),
    );

    final contentWithButton = Stack(
      children: [
        OcutuneCard(child: formFields),
        Positioned(
          bottom: 24,
          right: 24,
          child: OcutuneButton(
            type: OcutuneButtonType.floatingIcon,
            onPressed: () {
              if (!agreement.value) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("You must accept the terms to continue")),
                );
                return;
              }
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ),
      ],
    );

    return isIOS
        ? Material(
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          backgroundColor: lightGray,
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(CupertinoIcons.back, color: Colors.white),
          ),
          middle: const Text(''),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Center(child: contentWithButton),
          ),
        ),
      ),
    )
        : Scaffold(
      backgroundColor: lightGray,
      appBar: AppBar(
        backgroundColor: lightGray,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Center(child: contentWithButton),
        ),
      ),
    );

  }
}
