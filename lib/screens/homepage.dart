import 'package:flutter/material.dart';

import '../widgets/status_card.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [StatusCard(message: 'Tudo bem', temperature: 4.2)],
      ),
    );
  }
}
