import 'package:flutter/material.dart';
import 'app_shell.dart';

class BackOrHomeButton extends StatelessWidget {
  const BackOrHomeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    if (canPop) {
      return const BackButton();
    }
    return IconButton(
      tooltip: 'Home',
      icon: const Icon(Icons.home_outlined),
      onPressed: () {
        // Switch to Dashboard tab (index 0)
        AppShell.goToTab(0);
      },
    );
  }
}

