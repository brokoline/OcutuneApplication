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
    final String fullName = '${profile.firstName} ${profile.lastName}';
    final int rmeq = profile.rmeqScore;
    final int meq = profile.meqScore ?? 0;

    final String chronoTitle = chronoModel?.title ?? 'Ukendt';
    final String imageUrl = chronoModel?.fullImageUrl ?? '';
    final String? shortDesc = chronoModel?.shortDescription;
    final ImageProvider? avatarImage =
    imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null;

    // Formater registreringsdato som dd/MM/yyyy
    final String registrationFormatted =
    DateFormat('dd/MM/yyyy').format(profile.registrationDate);

    // Konverter køns‐enum til tekst
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

    return Scaffold(
      backgroundColor: generalBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            // Avatar
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white24,
              backgroundImage: avatarImage,
              child: avatarImage == null
                  ? const Icon(Icons.person, size: 40, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 8),
            // Navn
            Text(
              fullName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            // Scores
            Text(
              'rMEQ: $rmeq | MEQ: $meq',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            // Chronotype titel
            Text(
              chronoTitle,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 13,
              ),
            ),
            if (shortDesc != null) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
            const SizedBox(height: 16),

            // Profiloplysninger i kompakt kort
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                color: Colors.white24,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _infoTile(Icons.email, 'E-mail', profile.email),
                      _divider(),
                      _infoTile(Icons.cake, 'Fødselsår', profile.birthYear.toString()),
                      _divider(),
                      _infoTile(Icons.person_outline, 'Køn', genderText),
                      _divider(),
                      _infoTile(Icons.date_range, 'Registreret', registrationFormatted),
                    ],
                  ),
                ),
              ),
            ),
            // Fyld resten af pladsen, så card ligger øverst
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: Colors.white70, size: 20),
      title: Text(
        label,
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }

  Widget _divider() {
    return const Divider(
      color: Colors.white30,
      height: 1,
      indent: 16,
      endIndent: 16,
    );
  }
}
