import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '/theme/colors.dart';
import '/widgets/ocutune_icon_button.dart';
import 'package:ocutune_light_logger/models/chronotype_model.dart';

class LearnAboutChronotypesScreen extends StatefulWidget {
  const LearnAboutChronotypesScreen({super.key});

  @override
  State<LearnAboutChronotypesScreen> createState() =>
      _LearnAboutChronotypesScreenState();
}

class _LearnAboutChronotypesScreenState
    extends State<LearnAboutChronotypesScreen> {
  List<Chronotype> chronotypes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchChronotypes();
  }

  Future<void> fetchChronotypes() async {
    final url = Uri.parse('https://ocutune2025.ddns.net/chronotypes');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List<dynamic>;
      setState(() {
        chronotypes = data
            .map((j) => Chronotype.fromJson(j as Map<String, dynamic>))
            .toList();
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kunne ikke hente data.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: generalBackground,
      appBar: AppBar(
        backgroundColor: generalBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  const Text(
                    "Vil du lære mere om de\nforskellige kronotyper?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Icon(Icons.info_outline,
                      size: 36, color: Colors.white60),
                  const SizedBox(height: 16),
                  const Text(
                    "Vidste du, at din kronotype ikke kun\npåvirker din søvn – men også hvornår du\ner mest kreativ og produktiv?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 36),
                  ...chronotypes.map((type) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: OcutuneIconButton(
                        label: "Hvad er en ${type.title.toLowerCase()}?",
                        imageUrl: type.imageUrl ?? '',
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/aboutChronotype',
                            arguments: type.typeKey,
                          );
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 32),
                  const Text(
                    "Selv præsidenter og berømte\niværksættere planlægger deres dag efter\nderes biologiske ur!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      height: 1.5,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
