// lib/widgets/universal/simulated_mitid_box.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../services/services/api_services.dart';

class SimulatedMitIDBox extends StatefulWidget {
  final String title;

  /// Controller til bruger‐ID‐feltet (step 1).
  final TextEditingController controller;

  /// Controller til adgangskode‐feltet (step 2).
  final TextEditingController passwordController;

  /// Loader‐flag, viser spinner på knappen.
  final bool isLoading;

  /// Event når login endeligt udføres.
  final void Function(String userId, String password)? onContinue;

  /// Fejlmelding fra overordnet skærm (f.eks. forkert credentials).
  final String? errorMessage;

  const SimulatedMitIDBox({
    super.key,
    required this.title,
    required this.controller,
    required this.passwordController,
    required this.isLoading,
    this.onContinue,
    this.errorMessage,
  });

  @override
  State<SimulatedMitIDBox> createState() => _SimulatedMitIDBoxState();
}

class _SimulatedMitIDBoxState extends State<SimulatedMitIDBox> {
  bool rememberMe = false;
  bool isStepTwo = false;
  String? localError;

  String? _validatedUserId;

  Future<bool> _validateUserId(String userId) async {
    try {
      final resp = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/auth/sim-check-userid'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'sim_userid': userId}),
      );
      return resp.statusCode == 200;
    } catch (e) {
      setState(() => localError = 'Netværksfejl ved validering');
      return false;
    }
  }

  void _handlePrimaryAction() async {
    if (!isStepTwo) {
      final uid = widget.controller.text.trim();
      if (uid.isEmpty) {
        setState(() => localError = 'Udfyld Bruger‐ID');
        return;
      }
      setState(() => localError = null);
      final ok = await _validateUserId(uid);
      if (ok) {
        setState(() {
          isStepTwo = true;
          _validatedUserId = uid;
        });
      } else {
        setState(() => localError = 'Bruger‐ID blev ikke fundet');
      }
    } else {
      final pwd = widget.passwordController.text.trim();
      if (_validatedUserId == null || pwd.isEmpty) {
        setState(() => localError = 'Udfyld både bruger‐ID og adgangskode');
        return;
      }
      widget.onContinue?.call(_validatedUserId!, pwd);
    }
  }

  void _handleCancel() {
    Navigator.popUntil(context, ModalRoute.withName('/chooseAccess'));
  }

  void _showDialogBox({
    required String title,
    required String content,
    required String buttonText,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        backgroundColor: const Color(0xFF2B2B2B),
        title:
        Text(title, style: TextStyle(color: Colors.white, fontSize: 16.sp)),
        content: Text(
          content,
          style:
          TextStyle(color: Colors.white70, fontSize: 14.sp, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(buttonText,
                style:
                TextStyle(color: const Color(0xFF7F7FBF), fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    _showDialogBox(
      title: 'Hjælp (?!?!)',
      content:
      'Dette er et simuleret MitID‐login.\n\nVi kan desværre ikke hjælpe dig…',
      buttonText: 'Got it',
    );
  }

  void _showForgotDialog() {
    _showDialogBox(
      title: 'Glemt bruger‐ID?',
      content:
      'Tror du vi har adgang til CPR‐registret? Vi husker intet her…',
      buttonText: 'Faiiiiiiir nok',
    );
  }

  void _showRememberMeDialog() {
    _showDialogBox(
      title: 'Husk mig?',
      content: 'Bare log ind korrekt, så slipper du for besværet næste gang',
      buttonText: 'Got it!',
    );
  }

  @override
  Widget build(BuildContext context) {
    // kombiner extern og lokal fejl
    final combinedError = widget.errorMessage ?? localError;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 360.w),
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6.r),
            boxShadow: [
              BoxShadow(
                color: const Color.fromRGBO(0, 0, 0, 0.2),
                blurRadius: 12.r,
                offset: Offset(0, 6.h),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(widget.title,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16.sp,
                            color: Colors.black87)),
                  ),
                  SizedBox(width: 12.w),
                  Image.asset('assets/icon/mitid_logo.png', height: 28.h),
                ],
              ),
              Divider(height: 32.h),
              SizedBox(height: 8.h),
              Text(isStepTwo ? 'Adgangskode' : 'BRUGER‐ID',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.sp,
                      color: Colors.black87)),
              SizedBox(height: 8.h),
              TextField(
                controller:
                isStepTwo ? widget.passwordController : widget.controller,
                obscureText: isStepTwo,
                enabled: !widget.isLoading,
                style: TextStyle(fontSize: 16.sp, color: Colors.black87),
                decoration: InputDecoration(
                  suffixIcon:
                  Icon(isStepTwo ? Icons.lock : Icons.vpn_key, size: 20.sp),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4.r)),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                    BorderSide(color: const Color(0xFF0051A4), width: 2.w),
                  ),
                  isDense: true,
                ),
              ),
              if (combinedError != null)
                Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: Text(combinedError,
                      style: TextStyle(color: Colors.red, fontSize: 13.sp)),
                ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.isLoading ? null : _handlePrimaryAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.r)),
                  ),
                  child: widget.isLoading
                      ? SizedBox(
                    height: 20.h,
                    width: 20.w,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isStepTwo ? 'LOG IND' : 'FORTSÆT',
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      SizedBox(width: 8.w),
                      Icon(isStepTwo ? Icons.login : Icons.arrow_forward,
                          size: 18.sp),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              SizedBox(
                height: 32.h,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Opacity(
                    opacity: isStepTwo ? 0 : 1,
                    child: GestureDetector(
                      onTap: isStepTwo ? null : _showForgotDialog,
                      child: Text('Glemt bruger‐ID?',
                          style: TextStyle(
                              color: const Color(0xFF0051A4),
                              fontSize: 14.sp)),
                    ),
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() => rememberMe = !rememberMe);
                  _showRememberMeDialog();
                },
                child: Row(
                  children: [
                    Checkbox(
                      value: rememberMe,
                      onChanged: (v) => setState(() => rememberMe = v ?? false),
                      activeColor: const Color(0xFF0051A4),
                      visualDensity: VisualDensity.compact,
                    ),
                    Expanded(
                      child: Text('Husk mig på denne enhed',
                          style: TextStyle(
                              fontSize: 13.sp, color: Colors.black87)),
                    ),
                  ],
                ),
              ),
              Divider(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _handleCancel,
                    child:
                    Text('Afbryd', style: TextStyle(color: Colors.black87)),
                  ),
                  TextButton(
                    onPressed: _showHelpDialog,
                    child:
                    Text('Hjælp', style: TextStyle(color: Colors.black87)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
