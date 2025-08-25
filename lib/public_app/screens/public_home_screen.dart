// lib/public_app/screens/public_home_screen.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'donate_home_screen.dart';

class PublicHomeScreen extends StatelessWidget {
  const PublicHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MiSK EWT')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: MiskTheme.miskGold,
            child: const ListTile(
              title: Text('Welcome', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text('Explore initiatives, campaigns, and events', style: TextStyle(color: Colors.white70)),
            ),
          ),
          const SizedBox(height: 16),
          _tile(context, title: 'Initiatives', subtitle: 'See our ongoing work and progress', icon: Icons.flag, onTap: () {
            // TODO: Navigate to public initiatives listing when available
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Initiatives coming soon')));
          }),
          _tile(context, title: 'Campaigns', subtitle: 'Discover campaigns you can support', icon: Icons.campaign, onTap: () {
            // TODO: Navigate to public campaigns listing when available
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Campaigns coming soon')));
          }),
          _tile(context, title: 'Events', subtitle: 'Upcoming events and activities', icon: Icons.event, onTap: () {
            // TODO: Navigate to public events listing when available
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Events coming soon')));
          }),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.volunteer_activism),
            label: const Text('Donate Now'),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DonateHomeScreen()));
            },
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, {required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(backgroundColor: Colors.black12, child: Icon(icon, color: MiskTheme.miskGold)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

