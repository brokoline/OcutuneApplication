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

  Widget _sectionTitle(String text) {
    return Padding(
      padding: EdgeInsets.only(top: 24.h, bottom: 8.h),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
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
      textAlign: TextAlign.start,
    );
  }

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
• Forskning: Gyldige data til studier i lysbiologi og bæredygtigt design.''',
                  ),

                  _sectionTitle('Vores teknologi'),
                  _bodyText(
                    '''• Sensorenhed: Kompakt hardware til bæring eller montering.
• App & Dashboard: Realtids-visualisering og avancerede analyser.
• API: Integrer rådata direkte i egne systemer.''',
                  ),

                  _sectionTitle('Fordele ved Ocutune'),
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(2),
                      1: FlexColumnWidth(3),
                    },
                    children: [
                      TableRow(children: [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          child: Text('Høj præcision',
                              style: TextStyle(fontSize: 14.sp, color: Colors.white)),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          child: Text('Professionel kalibrering sikrer nøjagtighed',
                              style:
                              TextStyle(fontSize: 14.sp, color: Colors.white70)),
                        ),
                      ]),
                      TableRow(children: [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          child: Text('Brugervenligt dashboard',
                              style: TextStyle(fontSize: 14.sp, color: Colors.white)),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          child: Text('Intuitiv data- og grafvisning',
                              style:
                              TextStyle(fontSize: 14.sp, color: Colors.white70)),
                        ),
                      ]),
                      TableRow(children: [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          child: Text('Skræddersyede alarmer',
                              style: TextStyle(fontSize: 14.sp, color: Colors.white)),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          child: Text('Notifikation ved for meget/få eksponering',
                              style:
                              TextStyle(fontSize: 14.sp, color: Colors.white70)),
                        ),
                      ]),
                      TableRow(children: [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          child: Text('Skalerbar løsning',
                              style: TextStyle(fontSize: 14.sp, color: Colors.white)),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          child: Text('Fra enkeltbrug til store installationer',
                              style:
                              TextStyle(fontSize: 14.sp, color: Colors.white70)),
                        ),
                      ]),
                    ],
                  ),

                  _sectionTitle('Kom i gang'),
                  GestureDetector(
                    onTap: () => _launchLink('https://ocutune.com'),
                    child: Text('• Besøg vores hjemmeside',
                        style: TextStyle(fontSize: 14.sp, color: Colors.white70)),
                  ),

                  _sectionTitle('Kontakt os'),
                  GestureDetector(
                    onTap: () => _launchLink('mailto:info@ocutune.com'),
                    child: Text('• Email: info@ocutune.com',
                        style: TextStyle(fontSize: 14.sp, color: Colors.white70)),
                  ),
                  GestureDetector(
                    onTap: () => _launchLink('tel:+4512345678'),
                    child: Text('• Telefon: +45 12 34 56 78',
                        style: TextStyle(fontSize: 14.sp, color: Colors.white70)),
                  ),

                  SizedBox(height: 32.h),

                  // --- Partners carousel ---
                  PartnersCarousel(
                    assetPaths: const [
                      'assets/partners/partner_lyhne_design.png',
                      'assets/partners/partner_eu.png',
                      'assets/partners/partner_holscher_design.png',
                      'assets/partners/partner_belid_lighting_group.png',
                      'assets/partners/partner_good_light_group.png',
                      'assets/partners/partner_vejdirektoratet.png',
                      'assets/partners/partner_dtu.png',
                      'assets/partners/partner_saga.png',
                    ],
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

/// Auto-scrolling, farvefiltreret carousel på bunden
class PartnersCarousel extends StatefulWidget {
  final List<String> assetPaths;
  const PartnersCarousel({Key? key, required this.assetPaths})
      : super(key: key);

  @override
  State<PartnersCarousel> createState() => _PartnersCarouselState();
}

class _PartnersCarouselState extends State<PartnersCarousel> {
  late final PageController _ctrl;
  late final Timer _timer;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = PageController(viewportFraction: 0.3);

    // Auto-scroll hver 3. sekund
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_ctrl.hasClients) return;
      final next = (_current + 1) % widget.assetPaths.length;
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
    return Column(
      children: [
        SizedBox(
          height: 80.h,
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left,
                    size: 32.sp, color: Colors.white70),
                onPressed: () => _ctrl.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeIn,
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _ctrl,
                  itemCount: widget.assetPaths.length,
                  onPageChanged: (i) => setState(() => _current = i),
                  itemBuilder: (_, i) => Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Colors.white70,
                        BlendMode.srcIn,
                      ),
                      child: Image.asset(
                        widget.assetPaths[i],
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right,
                    size: 32.sp, color: Colors.white70),
                onPressed: () => _ctrl.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeIn,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.assetPaths.length, (i) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              width: _current == i ? 10.w : 6.w,
              height: _current == i ? 10.w : 6.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _current == i ? Colors.white : Colors.white38,
              ),
            );
          }),
        ),
      ],
    );
  }
}
