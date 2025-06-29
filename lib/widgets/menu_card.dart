import 'package:flutter/material.dart';

// widgets/menu_card.dart
class MenuCard extends StatelessWidget {
  const MenuCard({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.gradient,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(                               // ใช้ Ink เพื่อให้ ripple โค้งตาม
          decoration: BoxDecoration(
            gradient: gradient ??
                LinearGradient(
                  colors: [Colors.white, Colors.grey.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.07),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 48, color: Colors.teal),
                const SizedBox(height: 8),
                Text(label,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      );
}

