import 'package:flutter/material.dart';

import '../widgets/discogs_token_section.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: const [
        DiscogsTokenSection(),
      ],
    );
  }
}
