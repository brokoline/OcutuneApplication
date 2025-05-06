import 'package:flutter/material.dart';
import '/theme/colors.dart';
import '/widgets/ocutune_button.dart';

class GenderAgeScreen extends StatefulWidget {
  const GenderAgeScreen({super.key});

  @override
  State<GenderAgeScreen> createState() => GenderAgeScreenState();
}

class GenderAgeScreenState extends State<GenderAgeScreen> {
  // Standardår for at rulle midt i listen
  static const String _defaultYear = '2000';
  String? selectedYear = _defaultYear;
  bool _yearChosen = false;

  String? selectedGender;

  final List<String> years = List.generate(
    DateTime.now().year - 1925 + 1,
        (index) => (1925 + index).toString(),
  );
  final List<String> genders = ['Mand', 'Kvinde', 'Ikke angivet'];

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

                      // Årstals-dropdown
                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            // Centreret vertikalt + til venstre horisontalt
                            alignment: AlignmentDirectional.centerStart,

                            // Scroll-menu midt i listen fra starten
                            value: selectedYear,
                            menuMaxHeight: 240,
                            itemHeight: 48,

                            dropdownColor: darkGray,
                            isExpanded: true,

                            // Brug selectedItemBuilder til at vise hint indtil valgt
                            selectedItemBuilder: (context) {
                              return years.map((year) {
                                final isHint = !_yearChosen && year == _defaultYear;
                                return Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Text(
                                    isHint ? 'Vælg fødselsår' : year,
                                    style: TextStyle(
                                      color: isHint ? Colors.white70 : Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                );
                              }).toList();
                            },

                            iconEnabledColor: Colors.white,
                            style: const TextStyle(color: Colors.white),

                            items: years.map((year) {
                              return DropdownMenuItem(
                                value: year,
                                child: Text(year, style: const TextStyle(fontSize: 16)),
                              );
                            }).toList(),

                            onChanged: (value) {
                              setState(() {
                                selectedYear = value;
                                _yearChosen = true;
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

                      // Køns-dropdown
                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            alignment: AlignmentDirectional.centerStart,
                            value: selectedGender,
                            menuMaxHeight: 240,
                            itemHeight: 48,
                            dropdownColor: darkGray,
                            isExpanded: true,
                            hint: const Text(
                              "Vælg køn",
                              style: TextStyle(color: Colors.white70, fontSize: 16),
                            ),
                            iconEnabledColor: Colors.white,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                            items: genders.map((gender) {
                              return DropdownMenuItem(
                                value: gender,
                                child: Text(gender, style: const TextStyle(fontSize: 16)),
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
                  if (!_yearChosen || selectedGender == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Vælg både år og køn")),
                    );
                    return;
                  }
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
