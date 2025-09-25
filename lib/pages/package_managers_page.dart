import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:io';

class PackageManagerInfo {
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final String scriptFile;
  bool isInstalled;

  PackageManagerInfo({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.scriptFile,
    this.isInstalled = false,
  });
}

class PackageManagersPage extends StatefulWidget {
  const PackageManagersPage({super.key});

  @override
  State<PackageManagersPage> createState() => _PackageManagersPageState();
}

class _PackageManagersPageState extends State<PackageManagersPage> {
  final List<PackageManagerInfo> packageManagers = [
    PackageManagerInfo(
      name: 'Chocolatey',
      description: 'The Package Manager for Windows - Great for desktop apps & dev tools',
      icon: fluent.FluentIcons.package,
      color: const Color(0xFF8B4513),
      scriptFile: 'install-chocolatey.ps1',
      isInstalled: false,
    ),
    PackageManagerInfo(
      name: 'Scoop',
      description: 'Command-line installer - Focuses on portable apps & dev tools',
      icon: fluent.FluentIcons.command_prompt,
      color: const Color(0xFF4CAF50),
      scriptFile: 'install-scoop.ps1',
      isInstalled: false,
    ),
    PackageManagerInfo(
      name: 'WinGet',
      description: 'Microsoft\'s official package manager - Built into Windows 10/11',
      icon: fluent.FluentIcons.download,
      color: const Color(0xFF0078D4),
      scriptFile: 'install-winget.ps1',
      isInstalled: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return fluent.ScaffoldPage(
      header: const fluent.PageHeader(
        title: Text('Package Managers'),
      ),
      content: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Install and manage package managers for Windows',
              style: fluent.FluentTheme.of(context).typography.subtitle,
            ).animate().fadeIn().slideY(begin: -0.2),
            const SizedBox(height: 24),
            
            // Interactive Installer Card
            fluent.Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            fluent.FluentIcons.code_edit,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Interactive Package Manager Installer',
                                style: fluent.FluentTheme.of(context).typography.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Firebase CLI-style interactive menu for package manager installation',
                                style: fluent.FluentTheme.of(context).typography.body?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        fluent.FilledButton(
                          onPressed: () => _runInteractiveInstaller(),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(fluent.FluentIcons.play, size: 16),
                              SizedBox(width: 8),
                              Text('Run Interactive Installer'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
            
            const SizedBox(height: 32),
            
            Text(
              'Individual Package Managers',
              style: fluent.FluentTheme.of(context).typography.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Package Manager Cards
            Expanded(
              child: ListView.builder(
                itemCount: packageManagers.length,
                itemBuilder: (context, index) {
                  final pm = packageManagers[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: fluent.Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: pm.color,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                pm.icon,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pm.name,
                                    style: fluent.FluentTheme.of(context).typography.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    pm.description,
                                    style: fluent.FluentTheme.of(context).typography.body?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                fluent.Button(
                                  onPressed: () => _checkPackageManager(pm),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(fluent.FluentIcons.search, size: 16),
                                      SizedBox(width: 8),
                                      Text('Check'),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                fluent.FilledButton(
                                  onPressed: () => _installPackageManager(pm),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(fluent.FluentIcons.download, size: 16),
                                      const SizedBox(width: 8),
                                      Text('Install ${pm.name}'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: Duration(milliseconds: 300 + (index * 100))).slideX(begin: -0.1),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runInteractiveInstaller() async {
    try {
      // Show confirmation dialog
      final result = await fluent.showDialog<bool>(
        context: context,
        builder: (context) => fluent.ContentDialog(
          title: const Text('Run Interactive Installer'),
          content: const Text(
            'This will launch the Firebase CLI-style interactive package manager installer. '
            'The installer will guide you through selecting and installing package managers.\n\n'
            'Do you want to continue?'
          ),
          actions: [
            fluent.Button(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            fluent.FilledButton(
              child: const Text('Run Installer'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      );

      if (result == true) {
        // Show running info bar
        if (mounted) {
          fluent.displayInfoBar(
            context,
            builder: (context, close) => fluent.InfoBar(
              title: const Text('Running Interactive Installer'),
              content: const Text('The interactive package manager installer is starting...'),
              severity: fluent.InfoBarSeverity.info,
              onClose: close,
            ),
          );
        }

        // Determine script path
        String scriptPath = 'windows_scripts\\sub-script\\install-package-manager.ps1';
        
        // Check if file exists in current directory
        File scriptFile = File(scriptPath);
        if (!await scriptFile.exists()) {
          // Try alternative path
          scriptPath = 'sub-script\\install-package-manager.ps1';
          scriptFile = File(scriptPath);
        }

        if (await scriptFile.exists()) {
          // Run the interactive installer script with PowerShell
          final result = await Process.run(
            'powershell.exe',
            [
              '-ExecutionPolicy', 'Bypass',
              '-File', scriptPath,
            ],
            runInShell: true,
          );

          if (mounted) {
            if (result.exitCode == 0) {
              fluent.displayInfoBar(
                context,
                builder: (context, close) => fluent.InfoBar(
                  title: const Text('Interactive Installer Completed'),
                  content: const Text('The package manager installation process has completed successfully.'),
                  severity: fluent.InfoBarSeverity.success,
                  onClose: close,
                ),
              );
            } else {
              fluent.displayInfoBar(
                context,
                builder: (context, close) => fluent.InfoBar(
                  title: const Text('Installation Failed'),
                  content: Text('The installer failed with exit code: ${result.exitCode}'),
                  severity: fluent.InfoBarSeverity.error,
                  onClose: close,
                ),
              );
            }
          }
        } else {
          if (mounted) {
            fluent.displayInfoBar(
              context,
              builder: (context, close) => fluent.InfoBar(
                title: const Text('Script Not Found'),
                content: const Text('Could not find the interactive installer script.'),
                severity: fluent.InfoBarSeverity.error,
                onClose: close,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        fluent.displayInfoBar(
          context,
          builder: (context, close) => fluent.InfoBar(
            title: const Text('Error'),
            content: Text('Failed to run interactive installer: $e'),
            severity: fluent.InfoBarSeverity.error,
            onClose: close,
          ),
        );
      }
    }
  }

  Future<void> _installPackageManager(PackageManagerInfo pm) async {
    try {
      // Show confirmation dialog
      final result = await fluent.showDialog<bool>(
        context: context,
        builder: (context) => fluent.ContentDialog(
          title: Text('Install ${pm.name}'),
          content: Text(
            'This will install ${pm.name} package manager on your system. '
            'The installation requires administrator privileges.\n\n'
            'Do you want to continue?'
          ),
          actions: [
            fluent.Button(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            fluent.FilledButton(
              child: const Text('Install'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      );

      if (result == true) {
        // Show running info bar
        if (mounted) {
          fluent.displayInfoBar(
            context,
            builder: (context, close) => fluent.InfoBar(
              title: Text('Installing ${pm.name}'),
              content: const Text('Package manager installation is in progress...'),
              severity: fluent.InfoBarSeverity.info,
              onClose: close,
            ),
          );
        }

        // Determine script path based on package manager
        String scriptPath = 'windows_scripts\\script\\package-managers\\${pm.scriptFile}';
        
        // Check if file exists in current directory
        File scriptFile = File(scriptPath);
        if (!await scriptFile.exists()) {
          // Try alternative paths
          List<String> alternativePaths = [
            'script\\package-managers\\${pm.scriptFile}',
            'package-managers\\${pm.scriptFile}',
            pm.scriptFile,
          ];
          
          for (String altPath in alternativePaths) {
            scriptFile = File(altPath);
            if (await scriptFile.exists()) {
              scriptPath = altPath;
              break;
            }
          }
        }

        if (await scriptFile.exists()) {
          // Run the package manager installation script with PowerShell
          final result = await Process.run(
            'powershell.exe',
            [
              '-ExecutionPolicy', 'Bypass',
              '-File', scriptPath,
            ],
            runInShell: true,
          );

          if (mounted) {
            if (result.exitCode == 0) {
              setState(() {
                pm.isInstalled = true;
              });
              fluent.displayInfoBar(
                context,
                builder: (context, close) => fluent.InfoBar(
                  title: Text('${pm.name} Installed'),
                  content: Text('${pm.name} has been installed successfully.'),
                  severity: fluent.InfoBarSeverity.success,
                  onClose: close,
                ),
              );
            } else {
              fluent.displayInfoBar(
                context,
                builder: (context, close) => fluent.InfoBar(
                  title: const Text('Installation Failed'),
                  content: Text('${pm.name} installation failed with exit code: ${result.exitCode}'),
                  severity: fluent.InfoBarSeverity.error,
                  onClose: close,
                ),
              );
            }
          }
        } else {
          if (mounted) {
            fluent.displayInfoBar(
              context,
              builder: (context, close) => fluent.InfoBar(
                title: const Text('Script Not Found'),
                content: Text('Could not find the installation script for ${pm.name}.'),
                severity: fluent.InfoBarSeverity.error,
                onClose: close,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        fluent.displayInfoBar(
          context,
          builder: (context, close) => fluent.InfoBar(
            title: const Text('Error'),
            content: Text('Failed to install ${pm.name}: $e'),
            severity: fluent.InfoBarSeverity.error,
            onClose: close,
          ),
        );
      }
    }
  }

  Future<void> _checkPackageManager(PackageManagerInfo pm) async {
    try {
      // Show checking info bar
      if (mounted) {
        fluent.displayInfoBar(
          context,
          builder: (context, close) => fluent.InfoBar(
            title: Text('Checking ${pm.name}'),
            content: const Text('Verifying package manager installation...'),
            severity: fluent.InfoBarSeverity.info,
            onClose: close,
          ),
        );
      }

      // Check if package manager is installed by running a simple command
      String command;
      switch (pm.name.toLowerCase()) {
        case 'chocolatey':
          command = 'choco --version';
          break;
        case 'scoop':
          command = 'scoop --version';
          break;
        case 'winget':
          command = 'winget --version';
          break;
        default:
          command = '${pm.name.toLowerCase()} --version';
      }

      final result = await Process.run(
        'powershell.exe',
        ['-Command', command],
        runInShell: true,
      );

      if (mounted) {
        if (result.exitCode == 0) {
          setState(() {
            pm.isInstalled = true;
          });
          fluent.displayInfoBar(
            context,
            builder: (context, close) => fluent.InfoBar(
              title: Text('${pm.name} Found'),
              content: Text('${pm.name} is installed and working correctly.'),
              severity: fluent.InfoBarSeverity.success,
              onClose: close,
            ),
          );
        } else {
          setState(() {
            pm.isInstalled = false;
          });
          fluent.displayInfoBar(
            context,
            builder: (context, close) => fluent.InfoBar(
              title: Text('${pm.name} Not Found'),
              content: Text('${pm.name} is not installed or not in PATH.'),
              severity: fluent.InfoBarSeverity.warning,
              onClose: close,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        fluent.displayInfoBar(
          context,
          builder: (context, close) => fluent.InfoBar(
            title: const Text('Check Failed'),
            content: Text('Failed to check ${pm.name}: $e'),
            severity: fluent.InfoBarSeverity.error,
            onClose: close,
          ),
        );
      }
    }
  }
}