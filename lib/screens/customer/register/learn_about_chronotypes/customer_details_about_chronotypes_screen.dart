import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;

import '../../../../widgets/customer_widgets/customer_app_bar.dart';
import '/theme/colors.dart';
import 'package:ocutune_light_logger/models/rmeq_chronotype_model.dart';

class AboutChronotypeScreen extends StatefulWidget {
  final String chronotypeId;

  const AboutChronotypeScreen({
    super.key,
    required this.chronotypeId,
  });

  @override
  State<AboutChronotypeScreen> createState() =>
      _AboutChronotypeScreenState();
}

class _AboutChronotypeScreenState
    extends State<AboutChronotypeScreen> {
  ChronotypeModel? chronotype;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchChronotype();
  }

  Future<void> fetchChronotype() async {
    final url = Uri.parse(
        'https://ocutune2025.ddns.net/api/chronotypes/${widget.chronotypeId}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data =
      json.decode(response.body) as Map<String, dynamic>;
      setState(() {
        chronotype = ChronotypeModel.fromJson(data);
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
        title: 'Kronotype detaljer',
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : chronotype == null
            ? const Center(
          child: Text("Ingen data fundet",
              style: TextStyle(
                  color: Colors.white70)),
        )
            : SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.center,
            children: [
              Text(
                chronotype!.title,
                style: TextStyle(
                  fontSize: 38.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 10.h),
              if (chronotype!.imageUrl != null)
                Image.network(
                  chronotype!.imageUrl!,
                  height: 200.h,
                  errorBuilder:
                      (_, __, ___) =>
                  const Icon(
                    Icons.broken_image,
                    color: Colors.white70,
                  ),
                ),
              SizedBox(height: 24.h),
              Text(
                chronotype!.shortDescription,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15.sp,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                chronotype!.longDescription ??
                    'Ingen beskrivelse tilgængelig.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
