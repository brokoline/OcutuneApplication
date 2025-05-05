import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '/theme/colors.dart';
import 'package:ocutune_light_logger/models/chronotype.dart';

class LearnAboutChronotypesScreen extends StatefulWidget {
  const LearnAboutChronotypesScreen({super.key});

  @override
  State<LearnAboutChronotypesScreen> createState() => _LearnAboutChronotypesScreenState();
}

class _LearnAboutChronotypesScreenState extends State<LearnAboutChronotypesScreen> {
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
      setState(() {
        chronotypes = data.map((json) => Chronotype.fromJson(json)).toList();
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
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
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
                  const Icon(
                      Icons.info_outline, size: 36, color: Colors.white60),
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
                  ...chronotypes.map((type) => _buildChronoCard(context, type))
                      .toList(),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChronoCard(BuildContext context, Chronotype type) {
    String routeName;

    switch (type.title.toLowerCase()) {
      case 'lærke':
      case 'lark':
        routeName = '/learnLark';
        break;
      case 'due':
      case 'dove':
        routeName = '/learnDove';
        break;
      case 'natugle':
      case 'night owl':
        routeName = '/learnNightOwl';
        break;
      default:
        routeName = '/';
    }

    return Center(
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, routeName),
        child: Container(
          width: 250,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white24),
            borderRadius: BorderRadius.circular(16),
            color: Colors.transparent,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(
                type.imageUrl,
                width: 28,
                height: 28,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.broken_image, color: Colors.white70),
              ),
              const SizedBox(width: 12),
              Text(
                "Hvad er en ${type.title.toLowerCase()}?",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}