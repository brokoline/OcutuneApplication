import 'package:flutter/material.dart';
import '../services/auth_storage.dart';
import '/theme/colors.dart';
import 'package:ocutune_light_logger/screens/simulated_mitid_login_screen.dart';

class ChooseAccessScreen extends StatefulWidget {
  const ChooseAccessScreen({super.key});

  @override
  State<ChooseAccessScreen> createState() => _ChooseAccessScreenState();
}

class _ChooseAccessScreenState extends State<ChooseAccessScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final role = await AuthStorage.getUserRole();
    final id = await AuthStorage.getUserId();

    print('🧠 Rolle fundet: $role');
    print('🆔 ID fundet: $id');

    if (role == 'patient' && id != null) {
      Navigator.pushReplacementNamed(context, '/patient/dashboard', arguments: id);
    } else if (role == 'clinician' && id != null) {
      Navigator.pushReplacementNamed(context, '/clinician');
    } else {
      print('🟡 Ingen gemt login – vis adgangsvalg');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: generalBackground,
      appBar: AppBar(
        backgroundColor: generalBackground,
        elevation: 0,
        toolbarHeight: 64,
        iconTheme: const IconThemeData(color: Colors.white70),
        title: const Text(
          'Hvordan vil du logge ind?',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Center(
              child: Image.asset(
                'assets/logo/logo_ocutune.png',
                height: 110,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
              child: Column(
                children: [
                  _accessButton(
                    context,
                    title: 'MitID',
                    subtitle: 'Log ind som patient med MitID',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SimulatedLoginScreen(
                            title: 'MitID Privat Login',
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _accessButton(
                    context,
                    title: 'MitID Erhverv',
                    subtitle: 'Log ind som kliniker med MitID Erhverv',
                    color: Colors.indigo,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SimulatedLoginScreen(
                            title: 'MitID Erhverv Login',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _accessButton(
      BuildContext context, {
        required String title,
        required String subtitle,
        required Color color,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: color.withAlpha((255 * 0.9).round()),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
