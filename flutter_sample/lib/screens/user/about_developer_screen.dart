import 'package:flutter/material.dart';

class AboutDeveloperScreen extends StatelessWidget {
  static const routeName = '/about-developer';

  const AboutDeveloperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('About the Developer')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Developer',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _infoRow(context, 'Name', 'Esrom Basazinaw'),
                  _infoRow(context, 'Role', 'Flutter Developer'),
                  _infoRow(context, 'Location', 'Addis Ababa, Ethiopia'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contact',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _infoRow(context, 'Email', '12yemom@gmail.com'),
                  _infoRow(context, 'Phone', '+251 934046279'),
                  _infoRow(context, 'Website', 'https://esrombasazinaw.com'),
                  _infoRow(
                    context,
                    'LinkedIn',
                    'www.linkedin.com/in/esrom-basazinew-65102a339',
                  ),
                  _infoRow(context, 'Telegram', 'https://t.me/yemom21'),
                  _infoRow(
                    context,
                    'Instagram',
                    'https://instagram.com/12yemom',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About the App',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This app helps users explore categories and enjoy music and lyrics.\n'
                    'It supports admin management for content updates and approvals.',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
