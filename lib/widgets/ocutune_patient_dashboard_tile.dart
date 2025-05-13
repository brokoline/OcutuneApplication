import 'package:flutter/material.dart';
import 'package:ocutune_light_logger/theme/colors.dart';

class OcutunePatientDashboardTile extends StatelessWidget {
  final String label;
  final String? iconAsset;
  final IconData? icon;
  final VoidCallback onPressed;

  const OcutunePatientDashboardTile({
    super.key,
    required this.label,
    this.iconAsset,
    this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    Widget leadingIcon;
    if (iconAsset != null) {
      leadingIcon = Image.asset(
        iconAsset!,
        width: 48,
        height: 48,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image, size: 40, color: Colors.white);
        },
      );
    } else if (icon != null) {
      leadingIcon = Icon(icon, size: 48, color: Colors.white);
    } else {
      leadingIcon = const SizedBox(width: 48, height: 48);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Material(
        color: generalBox, // baggrundsfarve flyttes her
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white.withOpacity(0.2),
          highlightColor: Colors.white.withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                leadingIcon,
                const SizedBox(width: 16),
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
