// lib/public_app/screens/donate_home_screen.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class DonateHomeScreen extends StatelessWidget {
  const DonateHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donate to MISK')),
      body: Padding(
        padding: const EdgeInsets.all(MiskTheme.spacingMedium),
        child: ListView(
          children: [
            const Text('Choose a method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: MiskTheme.spacingSmall),
            _DonateOption(
              icon: Icons.account_balance,
              title: 'Bank Transfer (NEFT/IMPS) — Recommended',
              subtitle: 'No gateway fees. Get account details and submit your transfer reference.',
              onTap: () {}, // TODO: implement Bank Transfer flow
            ),
            _DonateOption(
              icon: Icons.qr_code_2,
              title: 'UPI (VPA/QR)',
              subtitle: 'Fast and simple. Your bank may charge a small fee.',
              onTap: () {}, // TODO: implement UPI flow
            ),
            _DonateOption(
              icon: Icons.payment,
              title: 'Razorpay (UPI/Card/Netbanking)',
              subtitle: 'Instant confirmation and receipt. Fees may apply (option to cover fees).',
              onTap: () {}, // TODO: implement Razorpay flow
            ),
            const SizedBox(height: MiskTheme.spacingLarge),
            const Text(
              'Note: Confirmed vs bank-reconciled totals are tracked transparently. '
              'Large donations (≥ ₹10,000) require PAN and address.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonateOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DonateOption({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MiskTheme.borderRadiusLarge)),
      margin: const EdgeInsets.symmetric(vertical: MiskTheme.spacingSmall),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

