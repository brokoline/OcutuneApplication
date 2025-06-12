import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

import '../../../theme/colors.dart';
import '../../../widgets/customer_widgets/customer_app_bar.dart';
import '../../../widgets/customer_widgets/customer_nav_bar.dart';
import '../../../widgets/customer_widgets/drop_down_menu_widget.dart';
import '../../../widgets/universal/ocutune_textfield.dart';


class CustomerReportIssueScreen extends StatefulWidget {
  const CustomerReportIssueScreen({Key? key}) : super(key: key);

  @override
  State<CustomerReportIssueScreen> createState() => _CustomerReportIssueScreenState();
}

class _CustomerReportIssueScreenState extends State<CustomerReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedProblemType;
  String? _problemTypeError;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  DateTime? _selectedDate;
  File? _attachedImage;
  final ImagePicker _picker = ImagePicker();

  final List<String> _problemTypes = [
    'Tabt forbindelse til lyslogger',
    'App crasher',
    'Notifikation ikke modtaget',
    'Andet',
  ];

  @override
  Widget build(BuildContext context) {
    final accent = generalBox;

    return Scaffold(
      backgroundColor: generalBackground,
      appBar: CustomerAppBar(
        title: 'Indrapporter problem',
        showBackButton: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Problemtype dropdown
                  OcutuneDropdown<String>(
                    value: _selectedProblemType,
                    hintText: "Vælg type problem",
                    items: _problemTypes
                        .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedProblemType = value;
                        _problemTypeError = null;
                      });
                    },
                  ),
                  if (_problemTypeError != null)
                    Padding(
                      padding: EdgeInsets.only(top: 4.h, left: 4.w),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _problemTypeError!,
                          style: TextStyle(color: Colors.red, fontSize: 13.sp),
                        ),
                      ),
                    ),
                  SizedBox(height: 16.h),

                  // Beskrivelse
                  OcutuneTextField(
                    controller: _descriptionController,
                    label: 'Beskrivelse',
                    maxLines: 3,
                    obscureText: false,
                  ),
                  SizedBox(height: 16.h),

                  // Vedhæft billede (mere tydelig!)
                  Center(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        elevation: 2,
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp),
                      ),
                      onPressed: () async {
                        final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          setState(() {
                            _attachedImage = File(image.path);
                          });
                        }
                      },
                      icon: Icon(Icons.attach_file, size: 20.sp, color: Colors.white),
                      label: Text(
                        'Vedhæft skærmbillede',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15.sp),
                      ),
                    ),
                  ),
                  if (_attachedImage != null)
                    Padding(
                      padding: EdgeInsets.only(top: 10.h, bottom: 8.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: Image.file(
                              _attachedImage!,
                              width: 46.w,
                              height: 46.w,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 140.w),
                            child: Text(
                              _attachedImage!.path.split('/').last,
                              style: TextStyle(color: Colors.white70, fontSize: 13.sp),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.white70, size: 20.sp),
                            onPressed: () {
                              setState(() {
                                _attachedImage = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                  SizedBox(height: 14.h),

                  // Vælg dato/tidspunkt
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2023),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: accent,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate = picked;
                        });
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
                      margin: EdgeInsets.only(bottom: 2.h),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        border: Border.all(color: Colors.white24),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: accent, size: 20.sp),
                          SizedBox(width: 12.w),
                          Text(
                            _selectedDate == null
                                ? "Vælg tidspunkt/dato"
                                : "${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 15.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Kontaktoplysninger (valgfrit)
                  SizedBox(height: 16.h),
                  OcutuneTextField(
                    controller: _contactController,
                    label: 'Kontaktoplysninger (valgfrit)',
                    maxLines: 1,
                    obscureText: false,
                  ),

                  // Indsend-knap
                  SizedBox(height: 24.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 13.h),
                      ),
                      onPressed: () {
                        setState(() {
                          _problemTypeError = _selectedProblemType == null ? 'Vælg type problem' : null;
                        });
                        if (_formKey.currentState!.validate() && _selectedProblemType != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Tak for din indrapportering!"),
                              backgroundColor: accent,
                            ),
                          );
                        }
                      },
                      child: Text(
                        'Indsend',
                        style: TextStyle(color: Colors.white, fontSize: 17.sp),
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomerNavBar(
        currentIndex: 4,
        onTap: (idx) {
          // Skift side logik - matcher dine andre sider:
          if (idx == 0) Navigator.pushReplacementNamed(context, '/customer_home');
          if (idx == 1) Navigator.pushReplacementNamed(context, '/customer_light');
          if (idx == 2) Navigator.pushReplacementNamed(context, '/customer_devices');
          if (idx == 3) Navigator.pushReplacementNamed(context, '/customer_info');
          if (idx == 4) Navigator.pushReplacementNamed(context, '/customer_settings');
        },
      ),
    );
  }
}
