import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/widgets/customer_widgets/customer_app_bar.dart';
import 'package:ocutune_light_logger/widgets/customer_widgets/customer_nav_bar.dart';

import '../../../models/customer_model.dart';
import '../../../models/rmeq_chronotype_model.dart';
import '../../../services/services/api_services.dart';
import '../../../widgets/universal/confirm_dialog.dart';
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
    final String fullName = '${profile.firstName} ${profile.lastName}';
    final int rmeq = profile.rmeqScore;
    final int meq = profile.meqScore ?? 0;
    final String chronoTitle = chronoModel?.title ?? 'Ukendt';
    final String? shortDesc = chronoModel?.shortDescription;
    final String registrationFormatted =
    DateFormat('dd/MM/yyyy').format(profile.registrationDate);

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
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 8.h),
                _buildAvatar(),
                SizedBox(height: 6.h),
                Text(
                  fullName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'rMEQ: $rmeq | MEQ: $meq',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  chronoTitle,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 13.sp,
                  ),
                ),
                if (shortDesc != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    shortDesc,
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                SizedBox(height: 12.h),
                _buildInfoCard(registrationFormatted, genderText),
                SizedBox(height: 12.h),
                _buildDeleteButton(context),
                SizedBox(height: 8.h),
              ],
            ),
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

  Widget _buildAvatar() {
    final String imageUrl = chronoModel?.fullImageUrl ?? '';
    final ImageProvider? avatarImage =
    imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null;

    return CircleAvatar(
      radius: 40.r,
      backgroundColor: generalBox,
      backgroundImage: avatarImage,
      child: avatarImage == null
          ? Icon(Icons.person, size: 40.r, color: Colors.white)
          : null,
    );
  }

  Widget _buildInfoCard(String registration, String gender) {
    return Card(
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
            _infoTile(Icons.cake, 'Fødselsår', profile.birthYear.toString()),
            _divider(),
            _infoTile(Icons.person_outline, 'Køn', gender),
            _divider(),
            _infoTile(Icons.date_range, 'Registreret', registration),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return Center(
      child: InkWell(
        borderRadius: BorderRadius.circular(4.r),
        onTap: () {
          showDialog<bool>(
            context: context,
            builder: (_) => ConfirmDialog(
              title: 'Slet bruger',
              message: 'Er du sikker på, at du vil slette din konto permanent?',
              confirmText: 'Ja',
              onConfirm: () async {
                Navigator.of(context).pop(); // Luk dialog
                try {
                  await ApiService.deleteCustomer(profile.id.toString());
                  Navigator.of(context).pushReplacementNamed('/login');
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Kunne ikke slette bruger: \$e')),
                  );
                }
              },
            ),
          );
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_outline, size: 18.sp, color: Colors.redAccent),
              SizedBox(width: 3.w),
              Text(
                'Slet bruger',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
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
