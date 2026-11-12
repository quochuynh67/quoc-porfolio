import 'package:flutter/material.dart';

class NavigationTextButton extends StatelessWidget {
  final VoidCallback onTap;
  final String text;

  const NavigationTextButton(
      {super.key, required this.onTap, required this.text});

  @override
  Widget build(BuildContext context) {
    return TextButton(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: const StadiumBorder(),
          foregroundColor: Colors.cyanAccent,
        ),
        onPressed: onTap,
        child: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .labelMedium!
              .copyWith(fontWeight: FontWeight.bold, color: Colors.white),
        ));
  }
}
