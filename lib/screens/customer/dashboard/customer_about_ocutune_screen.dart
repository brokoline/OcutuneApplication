import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/widgets/customer_widgets/customer_app_bar.dart';
import 'package:ocutune_light_logger/widgets/customer_widgets/customer_nav_bar.dart';
import '../customer_root_controller.dart';

class CustomerAboutOcutuneScreen extends StatelessWidget {
  const CustomerAboutOcutuneScreen({super.key});

  void _onNavTap(BuildContext context, int index) {
    Provider.of<CustomerRootController>(context, listen: false).setIndex(index);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: EdgeInsets.only(top: 24.h, bottom: 8.h),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _bodyText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14.sp,
        height: 1.4,
        color: Colors.white70,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double contentWidth = 0.85.sw;

    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      builder: (_, __) => Scaffold(
        backgroundColor: generalBackground,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(80.h),
          child: CustomerAppBar(title: 'Om Ocutune', showBackButton: true),
        ),
        body: Center(
          child: SizedBox(
            width: contentWidth,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: 80.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Hvem er vi?'),
                  _bodyText(
                      'Ocutune er en dansk virksomhed dedikeret til at udvikle intelligente løsninger til præcis måling og logning af lys. Vores team kombinerer ekspertise inden for optik, sensorteknologi og softwareudvikling for at levere pålidelige data om lys til forskning, arbejdsmiljø og meget mere.'),

                  _sectionTitle('Vores mission'),
                  _bodyText(
                      'Vi ønsker at skabe større indsigt i, hvordan lys påvirker mennesker og miljøer. Ved at levere data om både intensitet og spektral sammensætning kan vores brugere træffe bedre beslutninger – fra optimering af kontorbelysning til forbedring af søvnhygiejne.'),

                  _sectionTitle('Hvad er lyslogning?'),
                  _bodyText(
                      '''Lyslogning er processen med kontinuerligt at registrere og gemme lysforhold:

• Intensitet (lux)
• Spektral sammensætning (farver)
• Tidsstempling af eksponering

Dette giver et komplet billede af lysmiljøet over tid.'''),

                  _sectionTitle('Hvorfor lyslogning?'),
                  _bodyText(
                      '''• Søvn & velvære: Naturlig døgnrytme styres af lys, og korrekt eksponering kan forbedre søvnkvalitet.
• Arbejdsmiljø: Optimeret belysning øger trivsel og produktivitet.
• Indendørs landbrug: Planters vækst afhænger af både lysintensitet og spektrum.
• Forskning: Gyldige data til studier i lysbiologi og bæredygtigt design.'''),

                  _sectionTitle('Vores teknologi'),
                  _bodyText(
                      '''• Sensorenhed: Kompakt hardware til bæring eller montering.
• App & Dashboard: Realtids-visualisering og avancerede analyser.
• API: Integrer rådata direkte i egne systemer.'''),

                  _sectionTitle('Fordele ved Ocutune'),
                  Table(
                    columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(3)},
                    children: [
                      TableRow(children: [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          child: Text('Høj præcision', style: TextStyle(fontSize: 14.sp, color: Colors.white)),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          child: Text('Professionel kalibrering sikrer nøjagtighed', style: TextStyle(fontSize: 14.sp, color: Colors.white70)),
                        ),
                      ]),
                      TableRow(children: [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          child: Text('Brugervenligt dashboard', style: TextStyle(fontSize: 14.sp, color: Colors.white)),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          child: Text('Intuitiv data- og grafvisning', style: TextStyle(fontSize: 14.sp, color: Colors.white70)),
                        ),
                      ]),
                      TableRow(children: [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          child: Text('Skræddersyede alarmer', style: TextStyle(fontSize: 14.sp, color: Colors.white)),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          child: Text('Notifikation ved for meget/få eksponering', style: TextStyle(fontSize: 14.sp, color: Colors.white70)),
                        ),
                      ]),
                      TableRow(children: [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          child: Text('Skalerbar løsning', style: TextStyle(fontSize: 14.sp, color: Colors.white)),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          child: Text('Fra enkeltbrug til store installationer', style: TextStyle(fontSize: 14.sp, color: Colors.white70)),
                        ),
                      ]),
                    ],
                  ),

                  _sectionTitle('Kom i gang'),
                  GestureDetector(
                    onTap: () => _launchLink(context, 'https://ocutune.com'),
                    child: Text('• Besøg vores hjemmeside', style: TextStyle(fontSize: 14.sp, color: Colors.blue, decoration: TextDecoration.underline)),
                  ),
                  GestureDetector(
                    onTap: () => _launchLink(context, 'https://ocutune.com/app-ios'),
                    child: Text('• Download app (iOS)', style: TextStyle(fontSize: 14.sp, color: Colors.blue, decoration: TextDecoration.underline)),
                  ),
                  GestureDetector(
                    onTap: () => _launchLink(context, 'https://ocutune.com/app-android'),
                    child: Text('• Download app (Android)', style: TextStyle(fontSize: 14.sp, color: Colors.blue, decoration: TextDecoration.underline)),
                  ),

                  _sectionTitle('Kontakt os'),
                  GestureDetector(
                    onTap: () => _launchLink(context, 'mailto:info@ocutune.com'),
                    child: Text('• Email: info@ocutune.com', style: TextStyle(fontSize: 14.sp, color: Colors.blue, decoration: TextDecoration.underline)),
                  ),
                  GestureDetector(
                    onTap: () => _launchLink(context, 'tel:+4512345678'),
                    child: Text('• Telefon: +45 12 34 56 78', style: TextStyle(fontSize: 14.sp, color: Colors.blue, decoration: TextDecoration.underline)),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: CustomerNavBar(
          currentIndex: context.watch<CustomerRootController>().currentIndex,
          onTap: (idx) => _onNavTap(context, idx),
        ),
      ),
    );
  }

  void _launchLink(BuildContext context, String url) {
    // TODO: Implement link handling (f.eks. ApiService.launchUrl eller webview)
  }
}
