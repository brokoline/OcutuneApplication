import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import '/widgets/ocutune_textfield.dart';

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
          const SizedBox(height: 16),
          OcutuneTextField(label: 'Efternavn', controller: lastNameController),
          const SizedBox(height: 16),
          OcutuneTextField(label: 'E-mail', controller: emailController),
          const SizedBox(height: 16),
          OcutuneTextField(label: 'Adgangskode', controller: passwordController, isPassword: true),
          const SizedBox(height: 16),
          OcutuneTextField(label: 'Bekræft adgangskode', controller: confirmPasswordController, isPassword: true),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: agreement.value,
                onChanged: (value) => agreement.value = value ?? false,
                activeColor: Colors.white,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: RichText(
                    text: TextSpan(
                      text: 'Jeg accepterer ',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      children: [
                        TextSpan(
                          text: 'Vilkår og betingelser',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            color: Colors.white,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => Navigator.pushNamed(context, '/terms'),
                        ),
                        const TextSpan(text: ' og '),
                        TextSpan(
                          text: 'Privatlivspolitik',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            color: Colors.white,
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
