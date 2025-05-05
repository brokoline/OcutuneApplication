import 'package:flutter/material.dart';
import '/theme/colors.dart';
import '/widgets/ocutune_button.dart';

class GenderAgeScreen extends StatefulWidget {
  const GenderAgeScreen({super.key});

  @override
  State<GenderAgeScreen> createState() => GenderAgeScreenState();
}

class GenderAgeScreenState extends State<GenderAgeScreen> {
  String? selectedYear;
  String? selectedGender;

  final List<String> years = List.generate(
    DateTime.now().year - 1925 + 1,
        (index) => (1925 + index).toString(),
  );

  final List<String> genders = ['Mand', 'Kvinde', 'Ikke angivet'];

  @override
  void initState() {
    super.initState();
    selectedYear = '2000'; // 👈 starter scroll her
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGray,
      appBar: AppBar(
        backgroundColor: lightGray,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 32),
                      const Text(
                        "Hvornår er du født?",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedYear,
                            dropdownColor: darkGray,
                            isExpanded: true,
                            hint: const Text("Vælg år", style: TextStyle(color: Colors.white70)),
                            iconEnabledColor: Colors.white,
                            style: const TextStyle(color: Colors.white),
                            menuMaxHeight: 180,
                            items: years.map((year) {
                              return DropdownMenuItem(
                                value: year,
                                child: Text(year),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedYear = value;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                      const Text(
                        "Hvad er dit køn?",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedGender,
                            dropdownColor: darkGray,
                            isExpanded: true,
                            hint: const Text("Vælg køn", style: TextStyle(color: Colors.white70)),
                            iconEnabledColor: Colors.white,
                            style: const TextStyle(color: Colors.white),
                            menuMaxHeight: 250,
                            items: genders.map((gender) {
                              return DropdownMenuItem(
                                value: gender,
                                child: Text(gender),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedGender = value;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 24,
              right: 24,
              child: OcutuneButton(
                type: OcutuneButtonType.floatingIcon,
                onPressed: () {
                  if (selectedYear == null || selectedGender == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Vælg både år og køn")),
                    );
                    return;
                  }

                  print('Fødselsår: $selectedYear');
                  print('Køn: $selectedGender');

                  Navigator.pushNamed(context, '/chooseChronotype');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
