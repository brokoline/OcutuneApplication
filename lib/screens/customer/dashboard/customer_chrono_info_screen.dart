import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ocutune_light_logger/theme/colors.dart';

class CustomerChronotypeInfoScreen extends StatelessWidget {
  const CustomerChronotypeInfoScreen({super.key});

  static final List<_SectionData> _sections = [
    _SectionData(
      icon: Icons.description,
      title: 'De forskellige kronotyper',
      content: '''
Der findes flere kronotyper, som beskriver dine foretrukne sovetider og vågenperioder:

 • Ekstrem Morgenmenneske (Lærke): Vågne før solopgang, træt tidligt om aftenen.
 • Moderat Morgenmenneske: Vågne omkring solopgang, aktiv i formiddags.
 • Neutralt Mellemmenneske: (Due) Fleksibel, tilpasser sig almindelige arbejdstider.
 • Moderat Aftenmenneske: Vågne senere, peak aktivitet om eftermiddagen.
 • Ekstrem Aftenmenneske (Natugle): Vågne sent, mest produktiv sent om aftenen eller natten.

Hver type har fordele og udfordringer i forhold til arbejde, sociale aktiviteter og sundhed.''',
    ),
    _SectionData(
      icon: Icons.schedule,
      title: 'Genetisk grundlag',
      content: '''
Din indre rytme styres af gener og proteiner i feedback-loops:

 • PER og CRY: Regulære periodiske feedbacks, cirka 24 timers cyklus.
 • CLOCK og BMAL1: Danner transkriptionsfaktorkompleks, starter PER/CRY-ekspression.
 • Polymorfismer: Variationer i gener kan gøre dig mere morgen- eller aftenorienteret.

Genetisk test kan afsløre disposition for eksempelvis sent kronotype.''',
    ),
    _SectionData(
      icon: Icons.schedule,
      title: 'Kronobiologi & lys',
      content: '''
Din centrale oscillator (SCN) synkroniseres af lys/mørke:

 • Lys signal fra nethinden til SCN via retinohypothalamiske trakt.
 • Feedback-loop: Gener/proteiner skaber interne rytmer.
 • Morgenlys (blåt spektrum) skubber fase frem (earlier phase);
   Aftenlys (varmt spektrum) skubber tilbage.

At logge lys kan hjælpe med at se, om din døgnrytme stemmer overens med din rutine.''',
    ),
    _SectionData(
      icon: Icons.wb_sunny,
      title: 'Forskelligt lys & spektrum',
      content: '''
Forskellige bølgelængder påvirker kroppen forskelligt:

 • Blåt Lys (~460–490 nm): Maks. melanopsin-sensitivitet, undertrykker melatonin.
 • Grønligt Lys (~500–550 nm): Moderat effekt, lettere at tolerere.
 • Rødt Lys (~620–700 nm): Minimal påvirkning af SCN, fremmer afslapning.
 • Infrarødt (>700 nm): Ingen effekt på circadian system, bruges i terapi.

Brug varmt rødt/orange aftenslys for at fremme DLMO og forbedre søvn.''',
    ),
    _SectionData(
      icon: Icons.remove_red_eye,
      title: 'Melanopsin & melatonin',
      content: '''
Specialiserede ganglieceller i nethinden med melanopsin:

 • Pupilrefleks og vågenhedssignaler.
 • Døgnrytme-justering ved blåt lys.

Melatonin:
 • Begynder at stige ved DLMO under svag belysning (≤10 lux).
 • Top midt på natten, falder mod morgenen.
 • Tidspunkt for DLMO indikerer din søvntid.''',
    ),
    _SectionData(
      icon: Icons.analytics,
      title: 'DLMO & målemetoder',
      content: '''
DLMO er klinisk mål for melatonin-onset:

 • Mål i spyt- eller blodprøver under ≤10 lux.
 • Normaliseret DLMO: 20–22 t om aftenen.
 • Tidlig DLMO: Morgenmenneske; Sen DLMO: Aftenmenneske.

Sammenlign med lyslog for at vurdere interventionstiming.''',
    ),
    _SectionData(
      icon: Icons.quiz,
      title: 'MEQ Test',
      content: '''
Værktøjer til kronotypevurdering:

 • Reduced-Morningness–Eveningness Questionnaire (RMEQ, 5 spørgsmål)
 • Morningness–Eveningness Questionnaire (MEQ, 19 spørgsmål)
 • Scoreinddeling: Ekstrem morgenvendt, moderat, neutral, moderat aftenvendt, ekstrem aftenvendt

Resultater bruges til at designe mere personlige lys- og søvninterventioner.''',
      actionLabel: 'Start MEQ test',
      onActionTap: (ctx) => Navigator.pushNamed(ctx, '/meq_survey'),
    ),
    _SectionData(
      icon: Icons.health_and_safety,
      title: 'Sundhedsimplikationer',
      content: '''
Kronotype og helbred:

 • Social Jetlag: Mismatch mellem biologisk og social tid → øget risiko for metaboliske sygdomme.
 • Depression & Søvnforstyrrelser hyppigere hos aftenmennesker.
 • Lysbehandling kan forbedre humør og søvnkvalitet.

Tilpas arbejds- og søvnplan efter din kronotype for optimal trivsel.''',
    ),
    _SectionData(
      icon: Icons.menu_book,
      title: 'Videre Læsning & Referencer',
      content: '''
• Czeisler et al. (1999): Lavt aftenlys udskyder DLMO
• Burgess et al. (2003): Morgenlys fremmer opvågning
• Roenneberg et al. (2007): Alders- og sæsonvariation i kronotyper
• Gooley et al. (2010): Melanopsins rolle i circadisk respons

Udforsk gerne forskningen og dyk dybere ned i din døgnrytme.''',
      actionLabel: 'Læs Mere',
      onActionTap: (ctx) {
        // TODO: Implementer link
      },
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      builder: (_, __) => Scaffold(
        backgroundColor: generalBackground,
        body: ListView.separated(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
          itemCount: _sections.length,
          separatorBuilder: (_, __) => SizedBox(height: 16.h),
          itemBuilder: (_, i) {
            final sec = _sections[i];
            return Container(
              decoration: BoxDecoration(
                color: generalBox,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  leading: Icon(sec.icon, color: Colors.white70, size: 24.r),
                  title: Text(
                    sec.title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                  childrenPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  children: [
                    Text(
                      sec.content,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                    if (sec.actionLabel != null && sec.onActionTap != null)
                      Padding(
                        padding: EdgeInsets.only(top: 12.h),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: generalBoxHover,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                          ),
                          onPressed: () => sec.onActionTap!(context),
                          child: Text(
                            sec.actionLabel!,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SectionData {
  final IconData icon;
  final String title;
  final String content;
  final String? actionLabel;
  final void Function(BuildContext)? onActionTap;

  _SectionData({
    required this.icon,
    required this.title,
    required this.content,
    this.actionLabel,
    this.onActionTap,
  });
}
