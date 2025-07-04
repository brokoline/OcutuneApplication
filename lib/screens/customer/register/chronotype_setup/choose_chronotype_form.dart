import 'package:flutter/material.dart';
import '../../../../widgets/universal/ocutune_next_step_button.dart';
import 'package:ocutune_light_logger/models/rmeq_chronotype_model.dart';
import 'choose_chronotype_controller.dart';

class ChooseChronotypeForm extends StatefulWidget {
  const ChooseChronotypeForm({super.key});

  @override
  _ChooseChronotypeFormState createState() => _ChooseChronotypeFormState();
}

class _ChooseChronotypeFormState extends State<ChooseChronotypeForm> {
  String? selectedChronotype;
  List<ChronotypeModel> chronotypes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChronotypes();
  }

  Future<void> _loadChronotypes() async {
    try {
      final types = await ChooseChronotypeController.fetchChronotypes();
      if (!mounted) return;
      setState(() {
        chronotypes = types;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ChooseChronotypeController.showError(context, "Kunne ikke hente data.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : SafeArea(
      child: LayoutBuilder(
        builder: (ctx, constraints) => SingleChildScrollView(
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
                          color: Colors.white,
                        ),
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
                    // Chronotype cards
                    ...chronotypes.map(_buildChronoCard),
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
                            setState(() => selectedChronotype = null);
                            Navigator.pushNamed(context, '/questions');
                          },
                          child: const Text("Test dig selv"),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OcutuneButton(
                        type: OcutuneButtonType.floatingIcon,
                        onPressed: () => ChooseChronotypeController.goToNextScreen(
                            context, selectedChronotype),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChronoCard(ChronotypeModel type) {
    final isSelected = selectedChronotype == type.typeKey;
    return GestureDetector(
      onTap: () => setState(() => selectedChronotype = type.typeKey),
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
              child: () {
                final raw = type.imageUrl ?? "";
                final displayUrl = raw.startsWith("http")
                    ? raw
                    : "https://ocutune2025.ddns.net/images/$raw";

                if (displayUrl.isEmpty) {
                  return const SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.white70,
                        size: 24,
                      ),
                    ),
                  );
                }

                return SizedBox(
                  width: 48,
                  height: 48,
                  child: Image.network(
                    displayUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                    errorBuilder: (ctx, err, st) => const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.white70,
                        size: 24,
                      ),
                    ),
                  ),
                );
              }(),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
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
