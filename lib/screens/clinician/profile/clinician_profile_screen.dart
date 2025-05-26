import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../theme/colors.dart' as Colors;

class ProfilePlaceholder extends StatelessWidget {
  const ProfilePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Profil kommer snart...',
        style: TextStyle(color: Colors.white, fontSize: 16.sp),
      ),
    );
  }
}
