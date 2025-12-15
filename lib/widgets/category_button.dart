import 'package:flutter/material.dart';

/// CategoryButton
///
/// A small reusable widget that shows a rounded icon box and a label below it.
/// Used on the Home screen to display item categories in a horizontal list.
class CategoryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const CategoryButton(this.label, this.icon, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    // The container provides a rounded colored background for the icon.
    // The label is displayed below the icon and centered.
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
