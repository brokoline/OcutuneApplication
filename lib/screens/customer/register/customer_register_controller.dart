import 'package:flutter/material.dart';
import '../../../services/auth_storage.dart';
import '../../../services/services/user_data_service.dart';
import '../../../utils/validators.dart';
import '../../../utils/ui_helpers.dart';

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
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (firstName.isEmpty || lastName.isEmpty) {
      showError(context, "Udfyld venligst både fornavn og efternavn");
      return;
    }

    if (!Validators.isValidEmail(email)) {
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

    if (await AuthStorage.emailExists(email)) {
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
  }
}
