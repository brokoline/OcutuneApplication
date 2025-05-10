import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '/theme/colors.dart';
import '/widgets/ocutune_button.dart';
import '/models/user_data_service.dart';
import '/models/user_response.dart';
import 'package:ocutune_light_logger/models/chronotype.dart';

class ChooseChronotypeScreen extends StatefulWidget {
  const ChooseChronotypeScreen({super.key});

  @override
  State<ChooseChronotypeScreen> createState() => _ChooseChronotypeScreenState();
}

class _ChooseChronotypeScreenState extends State<ChooseChronotypeScreen> {
  String? selectedChronotype;
  List<Chronotype> chronotypes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchChronotypes();
  }

  Future<void> fetchChronotypes() async {
    final url = Uri.parse('https://ocutune.ddns.net/chronotypes');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      if (!mounted) return;
      setState(() {
        chronotypes = data.map((json) => Chronotype.fromJson(json)).toList();
        isLoading = false;
      });
    } else {
      if (!mounted) return;
      setState(() => isLoading = false);
      showError(context, "Kunne ikke hente data.");
    }
  }

  void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red.shade700,
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  void _goToNextScreen() {
    if (selectedChronotype != null) {
      if (currentUserResponse != null) {
        currentUserResponse = UserResponse(
          firstName: currentUserResponse!.firstName,
          lastName: currentUserResponse!.lastName,
          email: currentUserResponse!.email,
          password: currentUserResponse!.password,
          gender: currentUserResponse!.gender,
          birthYear: currentUserResponse!.birthYear,
          answers: [...currentUserResponse!.answers, selectedChronotype!],
          scores: currentUserResponse!.scores,
        );

      }
      Navigator.pushNamed(context, '/doneSetup');
    } else {
      showError(context, "Vælg en kronotype eller tag testen først");
    }
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(
                          child: Text(
                            "Kender du din kronotype?",
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Center(
                          child: Text(
                            "Vælg din kronotype eller fortsæt med en test",
                            style: TextStyle(fontSize: 14, color: Colors.white70),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ...chronotypes.map((type) => _buildChronoCard(type)).toList(),
                        const SizedBox(height: 8),
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/learn'),
                            child: const Text(
                              "Hvad er en kronotype? Lær mere",
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: SizedBox(
                            width: 200,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white24,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(color: Colors.white54),
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  selectedChronotype = null;
                                });
                                Navigator.pushNamed(context, '/Q1');
                              },
                              child: const Text("Tag testen"),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: OcutuneButton(
                            type: OcutuneButtonType.floatingIcon,
                            onPressed: _goToNextScreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildChronoCard(Chronotype type) {
    final isSelected = selectedChronotype == type.title;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedChronotype = type.title;
        });
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? Colors.white : Colors.white24),
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? Colors.white10 : Colors.transparent,
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Image.network(
                type.imageUrl ?? '',
                width: 48,
                height: 48,
                errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.broken_image, color: Colors.white),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    type.shortDescription,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
