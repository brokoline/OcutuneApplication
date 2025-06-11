import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/colors.dart';
import '../../../widgets/customer_widgets/customer_app_bar.dart';
import '../../../widgets/customer_widgets/customer_nav_bar.dart';
import '../../../widgets/universal/ocutune_textfield.dart';
import '../../../widgets/universal/drop_down_menu_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CustomerReportIssueScreen extends StatefulWidget {
  const CustomerReportIssueScreen({Key? key}) : super(key: key);

  @override
  State<CustomerReportIssueScreen> createState() => _CustomerReportIssueScreenState();
}

class _CustomerReportIssueScreenState extends State<CustomerReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedProblemType;
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
    return Scaffold(
      backgroundColor: generalBackground,
      appBar: const CustomerAppBar(
        title: 'Indrapporter problem',
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
          child: Center(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  decoration: BoxDecoration(
                    color: generalBox,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Problemtype dropdown
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: DropDownMenuWidget(
                          title: "Type problem",
                          value: _selectedProblemType,
                          items: _problemTypes,
                          onChanged: (value) => setState(() => _selectedProblemType = value),
                          validator: (value) => value == null ? 'Vælg type problem' : null,
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // Beskrivelse
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: OcutuneTextField(
                          controller: _descriptionController,
                          label: 'Beskrivelse',
                          maxLength: 200,
                          maxLines: 3,
                          validator: (value) =>
                          value == null || value.isEmpty ? 'Påkrævet' : null,
                          obscureText: false,
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // Vedhæft billede
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: accent, width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                              ),
                              onPressed: () async {
                                final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                                if (image != null) {
                                  setState(() {
                                    _attachedImage = File(image.path);
                                  });
                                }
                              },
                              icon: Icon(Icons.attach_file, color: accent, size: 22.sp),
                              label: Text('Vedhæft skærmbillede (valgfrit)', style: TextStyle(color: accent)),
                            ),
                            if (_attachedImage != null)
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8.r),
                                    child: Image.file(
                                      _attachedImage!,
                                      width: 56.w,
                                      height: 56.w,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Text(
                                      _attachedImage!.path.split('/').last,
                                      style: TextStyle(color: Colors.white54, fontSize: 13.sp),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.close, color: Colors.white54),
                                    onPressed: () {
                                      setState(() {
                                        _attachedImage = null;
                                      });
                                    },
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // Vælg dato/tidspunkt
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: GestureDetector(
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
                            padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 12.w),
                            decoration: BoxDecoration(
                              color: generalBackground,
                              border: Border.all(color: Colors.white24),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, color: accent, size: 22.sp),
                                SizedBox(width: 12.w),
                                Text(
                                  _selectedDate == null
                                      ? "Vælg tidspunkt/dato"
                                      : "${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // Kontaktoplysninger (valgfrit)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: OcutuneTextField(
                          controller: _contactController,
                          label: 'Kontaktoplysninger (valgfrit)',
                          maxLines: 1,
                          obscureText: false,
                          validator: (value) => null,
                        ),
                      ),
                      SizedBox(height: 32.h),

                      // Indsend-knap
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                          ),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Tak for din indrapportering!"),
                                  backgroundColor: accent,
                                ),
                              );
                              // evt. clear felter/pop page
                            }
                          },
                          child: Text(
                            'Indsend',
                            style: TextStyle(color: Colors.white, fontSize: 17.sp),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomerNavBar(
        currentIndex: 4,
        onTap: (idx) {
          // Navigér til den relevante side hvis nødvendigt
        },
      ),
    );
  }
}
