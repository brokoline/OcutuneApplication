import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/widgets/customer_widgets/customer_app_bar.dart';
import 'package:ocutune_light_logger/widgets/customer_widgets/customer_nav_bar.dart';

import '../../../models/customer_model.dart';
import '../../../models/rmeq_chronotype_model.dart';
import '../customer_root_controller.dart';

class CustomerProfileScreen extends StatelessWidget {
  final Customer profile;
  final ChronotypeModel? chronoModel;

  const CustomerProfileScreen({
    super.key,
    required this.profile,
    required this.chronoModel,
  });

  @override
  Widget build(BuildContext context) {
    // Prepare profile data
    final String fullName = '${profile.firstName} ${profile.lastName}';
    final int rmeq = profile.rmeqScore;
    final int meq = profile.meqScore ?? 0;
    final String chronoTitle = chronoModel?.title ?? 'Ukendt';
    final String imageUrl = chronoModel?.fullImageUrl ?? '';
    final String? shortDesc = chronoModel?.shortDescription;
    final ImageProvider? avatarImage =
    imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null;

    // Format registration date
    final String registrationFormatted =
    DateFormat('dd/MM/yyyy').format(profile.registrationDate);

    // Convert gender enum to text
    String genderText;
    switch (profile.gender) {
      case Gender.male:
        genderText = 'Mand';
        break;
      case Gender.female:
        genderText = 'Kvinde';
        break;
      default:
        genderText = 'Andet';
    }

    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      builder: (_, __) => Scaffold(
        backgroundColor: generalBackground,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(80.h),
          child: CustomerAppBar(
            title: 'Profil',
            showBackButton: true,
          ),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 16.h),
              // Avatar
              CircleAvatar(
                radius: 40.r,
                backgroundColor: generalBox,
                backgroundImage: avatarImage,
                child: avatarImage == null
                    ? Icon(Icons.person, size: 40.r, color: Colors.white)
                    : null,
              ),
              SizedBox(height: 8.h),
              // Name
              Text(
                fullName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4.h),
              // Scores
              Text(
                'rMEQ: $rmeq | MEQ: $meq',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 4.h),
              // Chronotype title
              Text(
                chronoTitle,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13.sp,
                ),
              ),
              if (shortDesc != null) ...[
                SizedBox(height: 6.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Text(
                    shortDesc,
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              SizedBox(height: 16.h),
              // Profile details card
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Card(
                  color: generalBox,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _infoTile(Icons.email, 'E-mail', profile.email),
                        _divider(),
                        _infoTile(
                            Icons.cake, 'Fødselsår', profile.birthYear.toString()),
                        _divider(),
                        _infoTile(Icons.person_outline, 'Køn', genderText),
                        _divider(),
                        _infoTile(Icons.date_range, 'Registreret', registrationFormatted),
                      ],
                    ),
                  ),
                ),
              ),
              Spacer(),
            ],
          ),
        ),
        bottomNavigationBar: Consumer<CustomerRootController>(
          builder: (context, ctrl, _) => CustomerNavBar(
            currentIndex: ctrl.currentIndex,
            onTap: (idx) {
              ctrl.setIndex(idx);
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: Colors.white70, size: 20.sp),
      title: Text(
        label,
        style: TextStyle(color: Colors.white70, fontSize: 12.sp),
      ),
      subtitle: Text(
        value,
        style: TextStyle(color: Colors.white, fontSize: 14.sp),
      ),
    );
  }

  Widget _divider() {
    return Divider(
      color: Colors.white30,
      height: 1,
      indent: 16.w,
      endIndent: 16.w,
    );
  }
}