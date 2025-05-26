import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../models/patient_model.dart';
import '../../../theme/colors.dart';

class PatientInfoCard extends StatelessWidget {
  final Patient patient;

  const PatientInfoCard({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    final fullName = '${patient.firstName} ${patient.lastName}';

    return Card(
      elevation: 2,
      color: generalBox, // ✅ bruger din definerede farve
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            _buildInfoRow('Navn', fullName),
            _buildDivider(),
            _buildInfoRow('CPR', patient.cpr ?? ''),
            if (patient.street != null && patient.street!.isNotEmpty) ...[
              _buildDivider(),
              _buildInfoRow('Adresse', patient.street!),
            ],
            if (patient.zipCode != null && patient.city != null) ...[
              _buildDivider(),
              _buildInfoRow('Postnummer & By', '${patient.zipCode} ${patient.city}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white70,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1.h,
      thickness: 0.5,
      color: Colors.grey.withAlpha(100),
    );
  }
}