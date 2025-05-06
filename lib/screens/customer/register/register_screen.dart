import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '/theme/colors.dart';
import '/widgets/ocutune_button.dart';
import '/widgets/ocutune_textfield.dart';
import '/widgets/ocutune_card.dart';

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
            'Opret konto',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
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
                value: agreed,
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
                            ..onTap = () {
                              Navigator.pushNamed(context, '/terms');
                            },
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
                  const SnackBar(content: Text("Du skal acceptere vilkårene for at fortsætte")),
                );
                return;
              }
              Navigator.pushNamed(context, '/genderage');
            },
          ),
        ),
      ],
    );

    return isIOS
        ? Material(
      child: CupertinoPageScaffold(
        backgroundColor: lightGray,
        navigationBar: CupertinoNavigationBar(
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
