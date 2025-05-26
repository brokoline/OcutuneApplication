import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '/theme/colors.dart';
import '/widgets/ocutune_button.dart';
import '/widgets/ocutune_textfield.dart';
import '/widgets/ocutune_card.dart';
import '../../../services/services/user_data_service.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  Future<bool> emailExists(String email) async {
    final url = Uri.parse('https://ocutune.ddns.net/check-email');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );
      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body);
        return jsonBody['exists'] == true;
      } else {
        return false;
      }
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final agreement = ValueNotifier(false);

    bool isValidEmail(String email) {
      final emailRegex = RegExp(r"^[^@]+@[^@]+\.[^@]+$");
      return emailRegex.hasMatch(email);
    }

    void showError(BuildContext context, String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
    }

    final formFields = ValueListenableBuilder<bool>(
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

    return Scaffold(
      backgroundColor: generalBackground,
      appBar: AppBar(
        backgroundColor: generalBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 48),
                  const Text(
                    'Opret konto',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: OcutuneCard(child: formFields),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 24,
              right: 24,
              child: OcutuneButton(
                type: OcutuneButtonType.floatingIcon,
                onPressed: () async {
                  final firstName = firstNameController.text.trim();
                  final lastName = lastNameController.text.trim();
                  final email = emailController.text.trim();
                  final password = passwordController.text;
                  final confirmPassword = confirmPasswordController.text;

                  if (firstName.isEmpty || lastName.isEmpty) {
                    showError(context, "Udfyld venligst både fornavn og efternavn");
                    return;
                  }

                  if (!isValidEmail(email)) {
                    showError(context, "Indtast en gyldig e-mailadresse");
                    return;
                  }

                  if (password.length < 6) {
                    showError(context, "Adgangskoden skal være mindst 6 tegn");
                    return;
                  }

                  if (password != confirmPassword) {
                    showError(context, "Adgangskoderne matcher ikke");
                    return;
                  }

                  if (!agreement.value) {
                    showError(context, "Du skal acceptere vilkårene for at fortsætte");
                    return;
                  }

                  final exists = await emailExists(email);
                  if (exists) {
                    showError(context, "Denne e-mail er allerede registreret");
                    return;
                  }

                  updateBasicInfo(
                    firstName: firstName,
                    lastName: lastName,
                    email: email,
                    gender: '',
                    birthYear: '',
                  );

                  currentUserResponse?.password = password;
                  Navigator.pushNamed(context, '/genderage');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
