import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter_animate/flutter_animate.dart';

class SystemSettingsPage extends StatefulWidget {
  const SystemSettingsPage({super.key});

  @override
  State<SystemSettingsPage> createState() => _SystemSettingsPageState();
}

class _SystemSettingsPageState extends State<SystemSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return fluent.ScaffoldPage(
      header: const fluent.PageHeader(
        title: Text('System Settings'),
      ),
      content: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Settings',
              style: fluent.FluentTheme.of(context).typography.titleLarge,
            ).animate().fadeIn().slideY(begin: -0.2),
            const SizedBox(height: 8),
            Text(
              'Configure system settings and preferences',
              style: fluent.FluentTheme.of(context).typography.body,
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      fluent.FluentIcons.settings,
                      size: 64,
                      color: Colors.grey.shade400,
                    ).animate().scale(delay: 300.ms),
                    const SizedBox(height: 16),
                    Text(
                      'System Configuration',
                      style: fluent.FluentTheme.of(context).typography.subtitle,
                    ).animate().fadeIn(delay: 400.ms),
                    const SizedBox(height: 8),
                    Text(
                      'Coming Soon - System settings and configuration options',
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