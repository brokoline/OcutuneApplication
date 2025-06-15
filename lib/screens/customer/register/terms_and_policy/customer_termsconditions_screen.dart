import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../widgets/customer_widgets/customer_app_bar.dart';
import '/theme/colors.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

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
        title: 'Vilkår & betingelser',
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle("1. Accept af vilkår"),
                SizedBox(height: 8.h),
                _buildParagraph(
                    "Ved at bruge appen accepterer du disse vilkår. Du må kun bruge appen, hvis du har læst og forstået både denne tekst og privatlivspolitikken."),
                SizedBox(height: 24.h),

                _buildSectionTitle("2. Medicinsk klassificering"),
                SizedBox(height: 8.h),
                _buildParagraph(
                    "Denne app er CE-mærket som medicinsk udstyr i klasse IIa under EU-forordning 2017/745 (MDR). "
                        "Den er designet til at analysere døgnrytmerelaterede sundhedsdata og give algoritmisk genereret sundhedsrelevant vejledning."),
                SizedBox(height: 12.h),
                _buildParagraph(
                    "Appen er ikke en erstatning for professionel medicinsk rådgivning, diagnose eller behandling. "
                        "Den bør kun anvendes som et supplement til vurdering af lys- og døgnrytmeforhold."),
                SizedBox(height: 24.h),

                _buildSectionTitle("3. Brugeransvar og kontraindikationer"),
                SizedBox(height: 8.h),
                _buildParagraph("Appen er ikke egnet til personer med alvorlige psykiske lidelser såsom:"),
                SizedBox(height: 8.h),
                _buildBulletList([
                  "Svær depression",
                  "Bipolar lidelse",
                  "Psykotiske tilstande",
                  "Anden psykisk ustabilitet",
                ]),
                SizedBox(height: 12.h),
                _buildParagraph(
                    "Hvis du er i behandling eller har alvorlige symptomer, bør du kun bruge appen i samråd med en sundhedsprofessionel. "
                        "Udvikleren fraskriver sig ansvar for skade, hvis appen anvendes uden for sit tiltænkte formål."),
                SizedBox(height: 24.h),

                _buildSectionTitle("4. Brugerdata og ansvar"),
                SizedBox(height: 8.h),
                _buildParagraph(
                    "Du er ansvarlig for de data, du indtaster i appen. Fejlagtige eller mangelfulde oplysninger kan påvirke de sundhedsanbefalinger, du modtager. "
                        "Appen leverer udelukkende forslag baseret på indsamlede data og algoritmer."),
                SizedBox(height: 24.h),

                _buildSectionTitle("5. Immaterielle rettigheder"),
                SizedBox(height: 8.h),
                _buildParagraph(
                    "Al kode, indhold og design tilhører udvikleren og må ikke kopieres eller videredistribueres uden skriftlig tilladelse."),
                SizedBox(height: 24.h),

                _buildSectionTitle("6. Ændringer i tjenesten"),
                SizedBox(height: 8.h),
                _buildParagraph(
                    "Vi forbeholder os retten til at opdatere, ændre eller nedlægge appens funktioner. "
                        "Brugerdata behandles fortsat i henhold til gældende regler, selv ved ændringer."),
                SizedBox(height: 24.h),

                _buildSectionTitle("7. Opsigelse og sletning"),
                SizedBox(height: 8.h),
                _buildParagraph(
                    "Du kan til enhver tid stoppe brugen og slette din profil. Data slettes permanent eller anonymiseres som beskrevet i privatlivspolitikken. "
                        "Vi kan suspendere adgang ved brud på vilkårene."),
                SizedBox(height: 24.h),

                _buildSectionTitle("8. Lovvalg og tvister"),
                SizedBox(height: 8.h),
                _buildParagraph(
                    "Disse vilkår er underlagt dansk lovgivning. Eventuelle tvister afgøres ved de danske domstole."),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
