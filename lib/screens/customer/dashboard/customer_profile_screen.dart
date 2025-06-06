// lib/screens/customer/dashboard/customer_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Til at formattere datoer pænt
import 'package:ocutune_light_logger/theme/colors.dart';

import '../../../models/customer_model.dart';
import '../../../models/rmeq_chronotype_model.dart';

class CustomerProfileScreen extends StatelessWidget {
  final Customer profile;
  final ChronotypeModel? chronoModel;

  const CustomerProfileScreen({
    Key? key,
    required this.profile,
    required this.chronoModel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ➊: De “øverste” felter: avatar, navn, rMEQ/MEQ, chronotype‐titel og kort beskrivelse
    final String fullName = '${profile.firstName} ${profile.lastName}';
    final int rmeq = profile.rmeqScore;
    final int meq = profile.meqScore ?? 0;

    // Træk felter fra ChronotypeModel (kan være null)
    final String chronoTitle = chronoModel?.title ?? 'Ukendt';
    final String imageUrl = chronoModel?.fullImageUrl ?? '';
    final String? shortDesc = chronoModel?.shortDescription;

    final ImageProvider? avatarImage =
    imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null;

    // ➋: Formater registreringsdato, så den fx vises som “4. jun. 2025”
    String registrationFormatted;
    if (profile.registrationDate != null) {
      registrationFormatted = DateFormat.yMMMd().format(profile.registrationDate);
    } else {
      registrationFormatted = 'Ukendt';
    }

    // ➌: Konverter køns‐enum til menneskelæselig tekst (første bogstav stort)
    String genderText;
    switch (profile.gender) {
      case Gender.male:
        genderText = 'Mand';
        break;
      case Gender.female:
        genderText = 'Kvinde';
        break;
      case Gender.other:
        genderText = 'Andet';
        break;
    }

    return Scaffold(
      backgroundColor: generalBackground,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ─── Avatar + Navn + rMEQ/MEQ + Chronotype ─────────────────────────────
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white24,
              backgroundImage: avatarImage,
              child: avatarImage == null
                  ? const Icon(Icons.person, size: 50, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              fullName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'rMEQ: $rmeq   /   MEQ: $meq',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Chronotype: $chronoTitle',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            if (shortDesc != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  shortDesc,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ─── “Profiloplysninger” i en Card ────────────────────────────────────
            Card(
              color: Colors.white24,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Column(
                  children: [
                    // E-mail
                    ListTile(
                      leading: const Icon(Icons.email, color: Colors.white70),
                      title: const Text(
                        'E-mail',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      subtitle: Text(
                        profile.email,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                    const Divider(color: Colors.white30, indent: 16, endIndent: 16),

                    // Fødselsår / Fødselsdato
                    ListTile(
                      leading: const Icon(Icons.cake, color: Colors.white70),
                      title: const Text(
                        'Fødselsår',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      subtitle: Text(
                        profile.birthYear.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                    const Divider(color: Colors.white30, indent: 16, endIndent: 16),

                    // Køn
                    ListTile(
                      leading: const Icon(Icons.person_outline, color: Colors.white70),
                      title: const Text(
                        'Køn',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      subtitle: Text(
                        genderText,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                    const Divider(color: Colors.white30, indent: 16, endIndent: 16),

                    // Registreringsdato
                    ListTile(
                      leading: const Icon(Icons.date_range, color: Colors.white70),
                      title: const Text(
                        'Registreret',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      subtitle: Text(
                        registrationFormatted,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            // Her kan du fx tilføje flere “sektioner” eller knapper,
            // som fx “Skift adgangskode”, “Log ud” osv.
          ],
        ),
      ),
    );
  }
}
