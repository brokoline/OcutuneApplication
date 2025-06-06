import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '/theme/colors.dart';
import 'package:ocutune_light_logger/models/remq_chronotype_model.dart';

class AboutChronotypeScreen extends StatefulWidget {
  final String chronotypeId;  // STRING: lark, dove, owl

  const AboutChronotypeScreen({super.key, required this.chronotypeId});

  @override
  State<AboutChronotypeScreen> createState() =>
      _AboutChronotypeScreenState();
}

class _AboutChronotypeScreenState extends State<AboutChronotypeScreen> {
  Chronotype? chronotype;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchChronotype();
  }

  Future<void> fetchChronotype() async {
    final url = Uri.parse('https://ocutune2025.ddns.net/api/chronotypes/${widget.chronotypeId}',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      setState(() {
        chronotype = Chronotype.fromJson(data);
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : chronotype == null
          ? const Center(
        child: Text("Ingen data fundet",
            style: TextStyle(color: Colors.white70)),
      )
          : Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              chronotype!.title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            if (chronotype!.imageUrl != null)
              Image.network(
                chronotype!.imageUrl!,
                height: 260,
                errorBuilder: (_, __, ___) =>
                const Icon(Icons.broken_image,
                    color: Colors.white),
              ),
            const SizedBox(height: 24),
            Text(
              chronotype!.shortDescription,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 15),
            ),
            const SizedBox(height: 16),
            Text(
              chronotype!.longDescription ??
                  'Ingen beskrivelse tilgængelig.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
