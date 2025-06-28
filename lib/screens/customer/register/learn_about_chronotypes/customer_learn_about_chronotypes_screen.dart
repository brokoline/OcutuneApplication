import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;

import '../../../../widgets/customer_widgets/customer_app_bar.dart';
import '/theme/colors.dart';
import '/widgets/universal/ocutune_icon_button.dart';
import 'package:ocutune_light_logger/models/rmeq_chronotype_model.dart';

class LearnAboutChronotypesScreen extends StatefulWidget {
  const LearnAboutChronotypesScreen({super.key});

  @override
  State<LearnAboutChronotypesScreen> createState() =>
      _LearnAboutChronotypesScreenState();
}

class _LearnAboutChronotypesScreenState
    extends State<LearnAboutChronotypesScreen> {
  List<ChronotypeModel> chronotypes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchChronotypes();
  }

  Future<void> fetchChronotypes() async {
    final url =
    Uri.parse('https://ocutune2025.ddns.net/api/chronotypes');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List<dynamic>;
      setState(() {
        chronotypes = data
            .map((j) =>
            ChronotypeModel.fromJson(j as Map<String, dynamic>))
            .toList();
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kunne ikke hente data.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: generalBackground,
      appBar: const CustomerAppBar(
        showBackButton: true,
        title: 'Lær om kronotyper',
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                24.w, 8.h, 24.w, 16.h),
            child: ConstrainedBox(
              constraints:
              BoxConstraints(maxWidth: 400.w),
              child: Column(
                children: [
                  SizedBox(height: 32.h),
                  Text(
                    "Vil du lære mere om de\nforskellige kronotyper?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Icon(Icons.info_outline,
                      size: 36.w,
                      color: Colors.white60),
                  SizedBox(height: 16.h),
                  Text(
                    "Vidste du, at din kronotype ikke kun\npåvirker din søvn – men også hvornår du\n"
                        "er mest kreativ og produktiv?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 15.sp,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 36.h),
                  ...chronotypes.map((type) {
                    return Padding(
                      padding: EdgeInsets.only(
                          bottom: 16.h),
                      child: OcutuneIconButton(
                        label:
                        "Hvad er en ${type.title.toLowerCase()}?",
                        imageUrl: type.imageUrl ?? '',
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/aboutChronotype',
                            arguments: type.typeKey,
                          );
                        },
                      ),
                    );
                  }),
                  SizedBox(height: 32.h),
                  Text(
                    "Selv præsidenter og berømte\niværksættere planlægger deres dag efter\n"
                        "deres biologiske ur!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      height: 1.5,
                      fontSize: 15.sp,
                    ),
                  ),
                  SizedBox(height: 32.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
