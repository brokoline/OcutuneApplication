import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:ocutune_light_logger/services/services/api_services.dart';
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

  Widget _sectionTitle(String text) => Padding(
    padding: EdgeInsets.only(top: 24.h, bottom: 8.h),
    child: Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white70,
        ),
      ),
    ),
  );

  Widget _bodyText(String text) => Text(
    text,
    style: TextStyle(fontSize: 14.sp, height: 1.4, color: Colors.white70),
    textAlign: TextAlign.start,
  );

  Future<void> _launchLink(String url) async {
    try {
      await ApiService.launchUrl(url);
    } catch (e) {
      debugPrint('Kunne ikke åbne link: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final contentWidth = 0.85.sw;
    const partnerLogos = [
      'assets/partners/partner_lyhne_design.png',
      'assets/partners/partner_eu.png',
      'assets/partners/partner_holscher_design.png',
      'assets/partners/partner_belid_lighting_group.png',
      'assets/partners/partner_good_light_group.png',
      'assets/partners/partner_vejdirektoratet.png',
      'assets/partners/partner_dtu.png',
      'assets/partners/partner_saga.png',
    ];

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
              padding: EdgeInsets.only(bottom: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Hvem er vi?'),
                  _bodyText(
                    'Ocutune er en dansk virksomhed dedikeret til at udvikle intelligente løsninger til præcis måling og logning af lys. Vores team kombinerer ekspertise inden for optik, sensorteknologi og softwareudvikling for at levere pålidelige data om lys til forskning, arbejdsmiljø og meget mere.',
                  ),

                  _sectionTitle('Vores mission'),
                  _bodyText(
                    'Vi ønsker at skabe større indsigt i, hvordan lys påvirker mennesker og miljøer. Ved at levere data om både intensitet og spektral sammensætning kan vores brugere træffe bedre beslutninger – fra optimering af kontorbelysning til forbedring af søvnhygiejne.',
                  ),

                  _sectionTitle('Hvad er lyslogning?'),
                  _bodyText(
                    '''Lyslogning er processen med kontinuerligt at registrere og gemme lysforhold:

• Intensitet (lux)
• Spektral sammensætning (farver)
• Tidsstempling af eksponering

Dette giver et komplet billede af lysmiljøet over tid.''',
                  ),

                  _sectionTitle('Hvorfor lyslogning?'),
                  _bodyText(
                    '''• Søvn & velvære: Naturlig døgnrytme styres af lys, og korrekt eksponering kan forbedre søvnkvalitet.
• Arbejdsmiljø: Optimeret belysning øger trivsel og produktivitet.
• Indendørs landbrug: Planters vækst afhænger af både lysintensitet og spektrum.
• Forskning: Gyldige data fra studier i lysbiologi og bæredygtigt design.''',
                  ),

                  _sectionTitle('Vores teknologi'),
                  _bodyText(
                    '''• Sensorenhed: Kompakt hardware.
• App & Dashboard: Realtids-visualisering og avancerede analyser.
• API: Integrer rådata direkte i egne systemer og opbevarer data på egen server.''',
                  ),

                  _sectionTitle('Kontakt os'),
                  GestureDetector(
                    onTap: () => _launchLink('mailto:info@ocutune.com'),
                    child: Text('• Email: info@ocutune.com',
                        style:
                        TextStyle(fontSize: 14.sp, color: Colors.white70)),
                  ),
                  GestureDetector(
                    onTap: () => _launchLink('tel:+4512345678'),
                    child: Text('• Telefon: +45 12 34 56 78',
                        style:
                        TextStyle(fontSize: 14.sp, color: Colors.white70)),
                  ),

                  // Samarbejdspartnere
                  _sectionTitle('Samarbejdspartnere'),
                  SizedBox(height: 2.h),
                  SizedBox(
                    height: 100.h,
                    child: _SingleLogoCarousel(logos: partnerLogos),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: CustomerNavBar(
          currentIndex: context.watch<CustomerRootController>().currentIndex,
          onTap: (i) => _onNavTap(context, i),
        ),
      ),
    );
  }
}

class _SingleLogoCarousel extends StatefulWidget {
  final List<String> logos;
  const _SingleLogoCarousel({required this.logos});

  @override
  State<_SingleLogoCarousel> createState() => _SingleLogoCarouselState();
}

class _SingleLogoCarouselState extends State<_SingleLogoCarousel> {
  late final PageController _ctrl;
  late final Timer _timer;
  int _current = 0;


  final Set<String> _filterFiles = {
  };
  final Map<String, double> _sizeOverrides = {
  };

  @override
  void initState() {
    super.initState();
    _ctrl = PageController(viewportFraction: 1.0);
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_ctrl.hasClients) return;
      final next = (_current + 1) % widget.logos.length;
      _ctrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _ctrl,
      itemCount: widget.logos.length,
      onPageChanged: (i) => setState(() => _current = i),
      itemBuilder: (_, i) {
        final path = widget.logos[i];
        final file = path.split('/').last;
        final baseWidth = 0.8.sw;
        final mul = _sizeOverrides[file] ?? 1.0;
        final width = baseWidth * mul;

        Widget img = Image.asset(
          path,
          width: width,
          fit: BoxFit.contain,
        );

        if (_filterFiles.contains(file)) {
          return Center(
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Colors.white70,
                BlendMode.srcIn,
              ),
              child: img,
            ),
          );
        }

        return Center(child: img);
      },
    );
  }
}
