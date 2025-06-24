import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../services/auth_storage.dart';
import '../../../theme/colors.dart';

class ClinicianProfileScreen extends StatelessWidget {
  const ClinicianProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: generalBackground,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<String>(
                future: AuthStorage.getClinicianName(),
                builder: (context, snapshot) {
                  return Center(
                    child: Text(
                      'Din profil',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 24.h),

              // Første card - Klinikoplysninger
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: generalBox,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: darkGray),
                ),
                padding: EdgeInsets.all(16.w),
                margin: EdgeInsets.only(bottom: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Klinikoplysninger',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'Her vil dine klinikoplysninger og tilknyttede personale vises når systemet er fuldt integreret.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              // Andet card - Patienttilknytning
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: generalBox,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: darkGray),
                ),
                padding: EdgeInsets.all(16.w),
                margin: EdgeInsets.only(bottom: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Patienttilknytning',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'Du vil kunne registrere nye patienter til Ocutune her, når vi har integreret persondataregistret.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              // Spacer for at skubbe indholdet op
              const Spacer(),

              // Log ud knap
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: GestureDetector(
                  onTap: () async {
                    await AuthStorage.logout();
                    Navigator.of(context).pushReplacementNamed('/login');
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.exit_to_app,
                        color: Colors.white70,
                        size: 24.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Log ud',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Version
              Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Center(
                  child: Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}