import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter_animate/flutter_animate.dart';

class SoftwareInstallationPage extends StatefulWidget {
  const SoftwareInstallationPage({super.key});

  @override
  State<SoftwareInstallationPage> createState() => _SoftwareInstallationPageState();
}

class _SoftwareInstallationPageState extends State<SoftwareInstallationPage> {
  @override
  Widget build(BuildContext context) {
    return fluent.ScaffoldPage(
      header: const fluent.PageHeader(
        title: Text('Software Installation'),
      ),
      content: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Software Installation',
              style: fluent.FluentTheme.of(context).typography.titleLarge,
            ).animate().fadeIn().slideY(begin: -0.2),
            const SizedBox(height: 8),
            Text(
              'Install and manage software packages',
              style: fluent.FluentTheme.of(context).typography.body,
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      fluent.FluentIcons.installation,
                      size: 64,
                      color: Colors.grey.shade400,
                    ).animate().scale(delay: 300.ms),
                    const SizedBox(height: 16),
                    Text(
                      'Software Installation Features',
                      style: fluent.FluentTheme.of(context).typography.subtitle,
                    ).animate().fadeIn(delay: 400.ms),
                    const SizedBox(height: 8),
                    Text(
                      'Coming Soon - Advanced software installation and management features',
                      style: fluent.FluentTheme.of(context).typography.caption,
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 500.ms),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}