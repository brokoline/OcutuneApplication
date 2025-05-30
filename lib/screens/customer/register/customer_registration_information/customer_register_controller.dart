// lib/screens/customer/register/customer_register_controller.dart

import 'package:flutter/material.dart';
import '../../../../services/auth_storage.dart';
import '../../../../services/services/customer_data_service.dart';
import '../../../../utils/validators.dart';
import '../../../../utils/ui_helpers.dart';  // <-- genindsæt showError her

class RegisterController {
  static Future<void> handleRegister({
    required BuildContext context,
    required TextEditingController firstNameController,
    required TextEditingController lastNameController,
    required TextEditingController emailController,
    required TextEditingController passwordController,
    required TextEditingController confirmPasswordController,
    required ValueNotifier<bool> agreement,
  }) async {
    final firstName       = firstNameController.text.trim();
    final lastName        = lastNameController.text.trim();
    final email           = emailController.text.trim();
    final password        = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    // 1) Navne-validering
    if (firstName.isEmpty || lastName.isEmpty) {
      showError(context, "Udfyld venligst både fornavn og efternavn");
      return;
    }

    // 2) Email-validering
    if (!Validators.isValidEmail(email)) {
      showError(context, "Indtast en gyldig e-mailadresse");
      return;
    }

    // 3) Kodeords-længde
    if (password.length < 6) {
      showError(context, "Adgangskoden skal være mindst 6 tegn");
      return;
    }

    // 4) Kodeords-match
    if (password != confirmPassword) {
      showError(context, "Adgangskoderne matcher ikke");
      return;
    }

    // 5) Accept af vilkår
    if (!agreement.value) {
      showError(context, "Du skal acceptere vilkårene for at fortsætte");
      return;
    }

    // 6) Eksistende email
    if (await AuthStorage.emailExists(email)) {
      showError(context, "Denne e-mail er allerede registreret");
      return;
    }

    // --- Opret grunddata i currentCustomerResponse ---
    updateBasicInfo(
      firstName: firstName,
      lastName:  lastName,
      email:     email,
      gender:    '',
      birthYear: '',
    );

    // --- Sæt password immutabelt via copyWith ---
    final resp = currentCustomerResponse;
    if (resp != null) {
      currentCustomerResponse = resp.copyWith(password: password);
    }

    // Gå videre til næste skærm
    Navigator.pushNamed(context, '/genderage');
  }
}
