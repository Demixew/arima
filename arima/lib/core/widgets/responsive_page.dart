import 'package:flutter/material.dart';

class ResponsivePage extends StatelessWidget {
  const ResponsivePage({
    required this.sidebar,
    required this.content,
    this.panel,
    super.key,
  });

  final Widget sidebar;
  final Widget content;
  final Widget? panel;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final bool large = width >= 1100;
    final bool medium = width >= 760;

    if (large) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(width: 280, child: sidebar),
          const SizedBox(width: 24),
          Expanded(child: content),
          if (panel != null) ...<Widget>[
            const SizedBox(width: 24),
            SizedBox(width: 320, child: panel),
          ],
        ],
      );
    }

    if (medium) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(width: 240, child: sidebar),
          const SizedBox(width: 20),
          Expanded(child: content),
        ],
      );
    }

    return Column(
      children: <Widget>[
        sidebar,
        const SizedBox(height: 16),
        content,
        if (panel != null) ...<Widget>[
          const SizedBox(height: 16),
          panel!,
        ],
      ],
    );
  }
}
