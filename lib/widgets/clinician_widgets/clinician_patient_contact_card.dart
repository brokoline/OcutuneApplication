import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import '../../../theme/colors.dart';
import '../../models/patient_model.dart';

class PatientContactCard extends StatelessWidget {
  final Patient patient;

  const PatientContactCard({
    super.key,
    required this.patient,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: generalBox, // ✅ bruger generalBox nu
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            if (patient.phone != null && patient.phone!.isNotEmpty)
              _buildInfoRow(Icons.phone, patient.phone!),
            if (patient.email != null && patient.email!.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 12.h),
                child: _buildInfoRow(Icons.email, patient.email!),
              ),
            if (patient.street != null && patient.street!.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 12.h),
                child: _buildInfoRow(Icons.home, patient.street!),
              ),
            if (patient.zipCode != null && patient.city != null)
              Padding(
                padding: EdgeInsets.only(top: 4.h),
                child: _buildInfoRow(
                  null,
                  '${patient.zipCode} ${patient.city}',
                  customIcon: Icon(Ionicons.location_outline, size: 20.w, color: Colors.blue.shade200),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData? icon, String text, {Widget? customIcon}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null || customIcon != null)
          Padding(
            padding: EdgeInsets.only(right: 12.w, top: 2.h),
            child: customIcon ?? Icon(icon, size: 20.w, color: Colors.blue.shade200),
          ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15.sp,
              color: Colors.white,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
