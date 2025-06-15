import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../widgets/customer_widgets/customer_app_bar.dart';
import '/theme/colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  Text _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.bold,
        color: Colors.white70,
      ),
    );
  }

  Text _buildParagraph(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14.sp,
        color: Colors.white70,
        height: 1.6,
      ),
    );
  }

  Widget _buildBulletList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map((item) => Padding(
        padding: EdgeInsets.only(bottom: 8.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("•  ",
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.white70,
                )),
            Expanded(
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.white70,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: generalBackground,
      appBar: const CustomerAppBar(
        showBackButton: true,
        title: 'Privatlivspolitik',
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildParagraph(
                    "Denne app er klassificeret som medicinsk udstyr (klasse IIa) i henhold til EU-forordningen 2017/745 (MDR). "
                        "Derfor gælder der særlige krav til beskyttelse og behandling af dine personoplysninger, herunder helbredsoplysninger."),
                SizedBox(height: 24.h),

                _buildSectionTitle("1. Data vi indsamler"),
                SizedBox(height: 8.h),
                _buildParagraph("Vi indsamler følgende oplysninger for at kunne levere appens funktioner:"),
                SizedBox(height: 8.h),
                _buildBulletList([
                  "Personlige oplysninger: navn, køn, fødselsår, email",
                  "Kronotype: som du selv angiver",
                  "Aktivitetsdata: du manuelt indtaster",
                  "Lyseksponeringsdata: fra enhedens lyslogger (hvis tilladt)",
                  "Helbredsrelaterede data: døgnrytmevurderinger",
                ]),
                SizedBox(height: 24.h),

                _buildSectionTitle("2. Formål med databehandling"),
                SizedBox(height: 8.h),
                _buildBulletList([
                  "At levere medicinsk vurdering og algoritmisk rådgivning relateret til din døgnrytme og lyseksponering",
                  "At tilbyde individuelt tilpassede sundhedsrelevante anbefalinger",
                  "At dokumentere appens ydeevne som medicinsk udstyr (jf. MDR)",
                  "At videreudvikle og kvalitetssikre algoritmer og funktioner",
                ]),
                SizedBox(height: 24.h),

                _buildSectionTitle("3. Retsgrundlag (GDPR art. 6 og 9)"),
                SizedBox(height: 8.h),
                _buildBulletList([
                  "Dit udtrykkelige samtykke (art. 6.1.a og 9.2.a)",
                  "Behandling af helbredsoplysninger med henblik på sundhedsydelser (art. 9.2.h), i relevant omfang",
                  "Overholdelse af krav til medicinsk dokumentation og sikkerhed (MDR)",
                ]),
                SizedBox(height: 24.h),

                _buildSectionTitle("4. Opbevaring og sikkerhed"),
                SizedBox(height: 8.h),
                _buildParagraph(
                    "Data opbevares sikkert og i overensstemmelse med GDPR og MDR. "
                        "Helbredsdata krypteres og logges med revisionsspor, som krævet for medicinske produkter."),
                SizedBox(height: 24.h),

                _buildSectionTitle("5. Sletning og anonymisering"),
                SizedBox(height: 8.h),
                _buildParagraph(
                    "Ved sletning af din brugerprofil slettes dine personoplysninger permanent. "
                        "Vi forbeholder os retten til at beholde anonymiserede, ikke-identificerbare data (fx lyseksponering, kronotype og aktivitetsmønstre) "
                        "til forsknings-, udviklings- og kvalitetsformål."),
                SizedBox(height: 24.h),

                _buildSectionTitle("6. Dine rettigheder"),
                SizedBox(height: 8.h),
                _buildBulletList([
                  "Indsigt i dine data",
                  "At få dine data rettet eller slettet",
                  "At trække dit samtykke tilbage",
                  "At klage til Datatilsynet",
                ]),
                SizedBox(height: 24.h),

                _buildSectionTitle("7. Kontakt"),
                SizedBox(height: 8.h),
                _buildParagraph(
                    "For spørgsmål til dine data, kontakt os på: privatlivspolitik@ocutune.com"),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
