import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'dart:io';
import 'package:path/path.dart' as path;

class ScriptInfo {
  final String name;
  final String description;
  final String fileName;
  final String category;
  final IconData icon;
  final Color color;

  ScriptInfo({
    required this.name,
    required this.description,
    required this.fileName,
    required this.category,
    required this.icon,
    required this.color,
  });
}

class ScriptsPage extends StatefulWidget {
  const ScriptsPage({super.key});

  @override
  State<ScriptsPage> createState() => _ScriptsPageState();
}

class _ScriptsPageState extends State<ScriptsPage> {
  final List<ScriptInfo> scripts = [
    // Package Managers
    ScriptInfo(
      name: 'Install Chocolatey',
      description: 'Install Chocolatey package manager with PowerShell functions',
      fileName: 'package-managers/install-chocolatey.ps1',
      category: 'Package Managers',
      icon: fluent.FluentIcons.package,
      color: const Color(0xFF8B4513),
    ),
    ScriptInfo(
      name: 'Install Chocolatey (Enhanced)',
      description: 'Enhanced Chocolatey installation with additional features',
      fileName: 'package-managers/install-chocolatey-enhanced.ps1',
      category: 'Package Managers',
      icon: fluent.FluentIcons.package,
      color: const Color(0xFF8B4513),
    ),
    ScriptInfo(
      name: 'Install Scoop',
      description: 'Install Scoop command-line installer for Windows',
      fileName: 'package-managers/install-scoop.ps1',
      category: 'Package Managers',
      icon: fluent.FluentIcons.command_prompt,
      color: const Color(0xFF4CAF50),
    ),
    ScriptInfo(
      name: 'Install Scoop (Fixed)',
      description: 'Fixed version of Scoop installer with enhanced compatibility',
      fileName: 'package-managers/install-scoop-fixed.ps1',
      category: 'Package Managers',
      icon: fluent.FluentIcons.repair,
      color: const Color(0xFF4CAF50),
    ),
    ScriptInfo(
      name: 'Install WinGet',
      description: 'Install Windows Package Manager with auto-elevation',
      fileName: 'package-managers/install-winget.ps1',
      category: 'Package Managers',
      icon: fluent.FluentIcons.download,
      color: const Color(0xFF0078D4),
    ),
    ScriptInfo(
      name: 'Install WinGet (Fixed)',
      description: 'Fixed version of WinGet installer with enhanced compatibility',
      fileName: 'package-managers/install-winget-fixed.ps1',
      category: 'Package Managers',
      icon: fluent.FluentIcons.repair,
      color: const Color(0xFF0078D4),
    ),
    ScriptInfo(
      name: 'Install WinGet (Simple)',
      description: 'Simplified WinGet installation script',
      fileName: 'package-managers/install-winget-simple.ps1',
      category: 'Package Managers',
      icon: fluent.FluentIcons.download,
      color: const Color(0xFF0078D4),
    ),
    
    // Development Tools
    ScriptInfo(
      name: 'Install Git',
      description: 'Install Git version control system',
      fileName: 'development/install-git.ps1',
      category: 'Development',
      icon: fluent.FluentIcons.branch_fork,
      color: const Color(0xFFE74C3C),
    ),
    ScriptInfo(
      name: 'Install GitHub CLI',
      description: 'Install GitHub command-line interface with multiple methods',
      fileName: 'development/install-github-cli.ps1',
      category: 'Development',
      icon: fluent.FluentIcons.developer_tools,
      color: const Color(0xFF333333),
    ),
    ScriptInfo(
      name: 'Install Node.js',
      description: 'Install Node.js JavaScript runtime environment',
      fileName: 'development/install-nodejs.ps1',
      category: 'Development',
      icon: fluent.FluentIcons.code,
      color: const Color(0xFF68A063),
    ),
    ScriptInfo(
      name: 'Install Python',
      description: 'Install Python programming language',
      fileName: 'development/install-python.ps1',
      category: 'Development',
      icon: fluent.FluentIcons.developer_tools,
      color: const Color(0xFF3776AB),
    ),
    ScriptInfo(
      name: 'Install Python (Enhanced)',
      description: 'Enhanced Python installation with additional packages',
      fileName: 'development/install-python-enhanced.ps1',
      category: 'Development',
      icon: fluent.FluentIcons.developer_tools,
      color: const Color(0xFF3776AB),
    ),
    ScriptInfo(
      name: 'Install PostgreSQL',
      description: 'Install PostgreSQL database server',
      fileName: 'development/install-postgresql.ps1',
      category: 'Development',
      icon: fluent.FluentIcons.database,
      color: const Color(0xFF336791),
    ),
    ScriptInfo(
      name: 'Install XAMPP',
      description: 'Install XAMPP web development stack',
      fileName: 'development/install-xampp.ps1',
      category: 'Development',
      icon: fluent.FluentIcons.globe,
      color: const Color(0xFFFB7A24),
    ),
    ScriptInfo(
      name: 'Install Development Tools',
      description: 'Comprehensive Windows development tools installation',
      fileName: 'development/install-dev-tools-windows.ps1',
      category: 'Development',
      icon: fluent.FluentIcons.developer_tools,
      color: const Color(0xFF107C10),
    ),
    ScriptInfo(
      name: 'Install Visual Studio',
      description: 'Install Visual Studio IDE for Windows development',
      fileName: 'development/install-visual-studio.ps1',
      category: 'Development',
      icon: fluent.FluentIcons.developer_tools,
      color: const Color(0xFF5C2D91),
    ),
    ScriptInfo(
      name: 'Install Essential Dev Tools',
      description: 'Install essential development tools for Windows',
      fileName: 'install-essential-dev-tools.ps1',
      category: 'Development',
      icon: fluent.FluentIcons.developer_tools,
      color: const Color(0xFF107C10),
    ),
    
    // Android Development
    ScriptInfo(
      name: 'Install Android Studio',
      description: 'Install Android Studio IDE with SDK setup',
      fileName: 'android-development/install-android-studio.ps1',
      category: 'Android Development',
      icon: fluent.FluentIcons.phone,
      color: const Color(0xFF3DDC84),
    ),
    ScriptInfo(
      name: 'Install Android Studio (Enhanced)',
      description: 'Enhanced Android Studio installation with additional tools',
      fileName: 'android-development/install-android-studio-enhanced.ps1',
      category: 'Android Development',
      icon: fluent.FluentIcons.phone,
      color: const Color(0xFF3DDC84),
    ),
    ScriptInfo(
      name: 'Install Flutter',
      description: 'Install Flutter SDK with environment setup and doctor check',
      fileName: 'android-development/install-flutter.ps1',
      category: 'Android Development',
      icon: fluent.FluentIcons.developer_tools,
      color: const Color(0xFF02569B),
    ),
    ScriptInfo(
      name: 'Install React Native',
      description: 'Install React Native CLI with Node.js and Java dependencies',
      fileName: 'android-development/install-react-native.ps1',
      category: 'Android Development',
      icon: fluent.FluentIcons.code,
      color: const Color(0xFF61DAFB),
    ),
    
    // AI Development
    ScriptInfo(
      name: 'Install AI Development Stack',
      description: 'Complete AI/ML development environment setup',
      fileName: 'ai-development/install-ai-development-stack.ps1',
      category: 'AI Development',
      icon: fluent.FluentIcons.robot,
      color: const Color(0xFF9C27B0),
    ),
    ScriptInfo(
      name: 'Install AI ML Tools',
      description: 'Install AI and machine learning tools and frameworks',
      fileName: 'ai-development/install-ai-ml-tools.ps1',
      category: 'AI Development',
      icon: fluent.FluentIcons.robot,
      color: const Color(0xFF9C27B0),
    ),
    ScriptInfo(
      name: 'Install AI GPU Setup',
      description: 'Setup GPU acceleration for AI development',
      fileName: 'ai-development/install-ai-gpu-setup.ps1',
      category: 'AI Development',
      icon: fluent.FluentIcons.processing,
      color: const Color(0xFF76B900),
    ),
    ScriptInfo(
      name: 'Install AWS AI Stack',
      description: 'Install AWS AI and machine learning services',
      fileName: 'ai-development/install-aws-ai-stack.ps1',
      category: 'AI Development',
      icon: fluent.FluentIcons.cloud,
      color: const Color(0xFFFF9900),
    ),
    ScriptInfo(
      name: 'Install Azure AI Stack',
      description: 'Install Azure AI and cognitive services',
      fileName: 'ai-development/install-azure-ai-stack.ps1',
      category: 'AI Development',
      icon: fluent.FluentIcons.cloud,
      color: const Color(0xFF0078D4),
    ),
    ScriptInfo(
      name: 'Install GCP AI Stack',
      description: 'Install Google Cloud AI and ML services',
      fileName: 'ai-development/install-gcp-ai-stack.ps1',
      category: 'AI Development',
      icon: fluent.FluentIcons.cloud,
      color: const Color(0xFF4285F4),
    ),
    
    // Cloud Development
    ScriptInfo(
      name: 'Install AWS CLI (Enhanced)',
      description: 'Enhanced AWS CLI installation with configuration',
      fileName: 'cloud/install-aws-cli-enhanced.ps1',
      category: 'Cloud Development',
      icon: fluent.FluentIcons.cloud,
      color: const Color(0xFFFF9900),
    ),
    ScriptInfo(
      name: 'Install Azure CLI (Enhanced)',
      description: 'Enhanced Azure CLI installation with extensions',
      fileName: 'cloud/install-azure-cli-enhanced.ps1',
      category: 'Cloud Development',
      icon: fluent.FluentIcons.cloud,
      color: const Color(0xFF0078D4),
    ),
    ScriptInfo(
      name: 'Install Google Cloud SDK (Enhanced)',
      description: 'Enhanced Google Cloud SDK with additional components',
      fileName: 'cloud/install-google-cloud-sdk-enhanced.ps1',
      category: 'Cloud Development',
      icon: fluent.FluentIcons.cloud,
      color: const Color(0xFF4285F4),
    ),
    ScriptInfo(
      name: 'Install Cloud Development Stack',
      description: 'Complete cloud development environment setup',
      fileName: 'cloud/install-cloud-development-stack.ps1',
      category: 'Cloud Development',
      icon: fluent.FluentIcons.cloud,
      color: const Color(0xFF2196F3),
    ),
    
    // Web Development
    ScriptInfo(
      name: 'Install Web Development Stack',
      description: 'Complete web development environment setup',
      fileName: 'web-dev/install-web-development-stack.ps1',
      category: 'Web Development',
      icon: fluent.FluentIcons.globe,
      color: const Color(0xFFE34F26),
    ),
    ScriptInfo(
      name: 'Install Web Stack Runtimes',
      description: 'Install Node.js, Python, and other web runtimes',
      fileName: 'web-development/install-web-stack-runtimes.ps1',
      category: 'Web Development',
      icon: fluent.FluentIcons.code,
      color: const Color(0xFF68A063),
    ),
    ScriptInfo(
      name: 'Install Editors IDEs',
      description: 'Install web development editors and IDEs',
      fileName: 'web-development/install-editors-ides.ps1',
      category: 'Web Development',
      icon: fluent.FluentIcons.code_edit,
      color: const Color(0xFF007ACC),
    ),
    ScriptInfo(
      name: 'Install Browsers Testing',
      description: 'Install browsers for web development and testing',
      fileName: 'web-development/install-browsers-testing.ps1',
      category: 'Web Development',
      icon: fluent.FluentIcons.globe,
      color: const Color(0xFF0078D4),
    ),
    ScriptInfo(
      name: 'Install VS Code (Enhanced)',
      description: 'Enhanced VS Code installation with extensions',
      fileName: 'web-dev/install-vscode-enhanced.ps1',
      category: 'Web Development',
      icon: fluent.FluentIcons.code,
      color: const Color(0xFF007ACC),
    ),
    
    // Applications & IDEs
    ScriptInfo(
      name: 'Install Browsers',
      description: 'Install popular web browsers',
      fileName: 'apps/install-browsers.ps1',
      category: 'Applications',
      icon: fluent.FluentIcons.globe,
      color: const Color(0xFF0078D4),
    ),
    ScriptInfo(
      name: 'Install Browsers (Enhanced)',
      description: 'Enhanced browser installation with additional tools',
      fileName: 'apps/install-browsers-enhanced.ps1',
      category: 'Applications',
      icon: fluent.FluentIcons.globe,
      color: const Color(0xFF0078D4),
    ),
    ScriptInfo(
      name: 'Install IDEs',
      description: 'Install popular integrated development environments',
      fileName: 'apps/install-ides.ps1',
      category: 'Applications',
      icon: fluent.FluentIcons.code_edit,
      color: const Color(0xFF007ACC),
    ),
    ScriptInfo(
      name: 'Install VS Code',
      description: 'Install Visual Studio Code editor',
      fileName: 'apps/install-vscode.ps1',
      category: 'Applications',
      icon: fluent.FluentIcons.code,
      color: const Color(0xFF007ACC),
    ),
    ScriptInfo(
      name: 'Install Windows Terminal',
      description: 'Install Windows Terminal with modern features',
      fileName: 'apps/install-windows-terminal.ps1',
      category: 'Applications',
      icon: fluent.FluentIcons.command_prompt,
      color: const Color(0xFF0078D4),
    ),
    
    // Containers
    ScriptInfo(
      name: 'Install Docker',
      description: 'Install Docker Desktop for Windows',
      fileName: 'containers/install-docker.ps1',
      category: 'Containers',
      icon: fluent.FluentIcons.processing,
      color: const Color(0xFF2496ED),
    ),
    
    // System Tools
    ScriptInfo(
      name: 'Install WSL',
      description: 'Install Windows Subsystem for Linux',
      fileName: 'development/install-wsl.ps1',
      category: 'System Tools',
      icon: fluent.FluentIcons.command_prompt,
      color: const Color(0xFFE95420),
    ),
    ScriptInfo(
      name: 'Install WSL2 Ubuntu',
      description: 'Install WSL2 with Ubuntu distribution',
      fileName: 'development/install-wsl2-ubuntu.ps1',
      category: 'System Tools',
      icon: fluent.FluentIcons.command_prompt,
      color: const Color(0xFFE95420),
    ),
    ScriptInfo(
      name: 'Install WSL2 Kali KEX',
      description: 'Install WSL2 with Kali Linux and KEX desktop',
      fileName: 'development/install-wsl2-kali-kex.ps1',
      category: 'System Tools',
      icon: fluent.FluentIcons.command_prompt,
      color: const Color(0xFF557C94),
    ),
    
    // Server Development
    ScriptInfo(
      name: 'Install Server Stack',
      description: 'Install complete server development stack',
      fileName: 'server/install-server-stack.ps1',
      category: 'Server Development',
      icon: fluent.FluentIcons.server,
      color: const Color(0xFF2E8B57),
    ),
    ScriptInfo(
      name: 'Install Node.js LTS (Server)',
      description: 'Install Node.js LTS for server development',
      fileName: 'server/install-nodejs-lts.ps1',
      category: 'Server Development',
      icon: fluent.FluentIcons.code,
      color: const Color(0xFF68A063),
    ),
    ScriptInfo(
      name: 'Install PostgreSQL (Server)',
      description: 'Install PostgreSQL for server development',
      fileName: 'server/install-postgresql.ps1',
      category: 'Server Development',
      icon: fluent.FluentIcons.database,
      color: const Color(0xFF336791),
    ),
    ScriptInfo(
      name: 'Install Python 3.13 (Server)',
      description: 'Install Python 3.13 for server development',
      fileName: 'server/install-python313.ps1',
      category: 'Server Development',
      icon: fluent.FluentIcons.developer_tools,
      color: const Color(0xFF3776AB),
    ),
  ];

  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final filteredScripts = scripts.where((script) {
      final matchesSearch = script.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          script.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'All' || script.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    final categories = ['All'] + scripts.map((s) => s.category).toSet().toList()..sort();
    final groupedScripts = <String, List<ScriptInfo>>{};
    
    for (final script in filteredScripts) {
      groupedScripts.putIfAbsent(script.category, () => []).add(script);
    }

    return fluent.ScaffoldPage(
      header: fluent.PageHeader(
        title: const Text('PowerShell Scripts'),
        commandBar: fluent.CommandBar(
          primaryItems: [
            fluent.CommandBarButton(
              icon: const Icon(fluent.FluentIcons.refresh),
              label: const Text('Refresh'),
              onPressed: () {
                setState(() {});
              },
            ),
          ],
        ),
      ),
      content: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search and Filter Row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: fluent.TextBox(
                    placeholder: 'Search scripts...',
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Icon(fluent.FluentIcons.search),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: fluent.ComboBox<String>(
                    placeholder: const Text('Category'),
                    value: _selectedCategory,
                    items: categories.map((category) {
                      return fluent.ComboBoxItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value ?? 'All';
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Scripts Grid
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: groupedScripts.entries.map((entry) {
                    final category = entry.key;
                    final categoryScripts = entry.value;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Row(
                            children: [
                              Icon(
                                _getCategoryIcon(category),
                                color: _getCategoryColor(category),
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                category,
                                style: fluent.FluentTheme.of(context).typography.subtitle,
                              ),
                              const SizedBox(width: 8),
                              fluent.Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(category).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${categoryScripts.length}',
                                  style: TextStyle(
                                    color: _getCategoryColor(category),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 1.2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: categoryScripts.length,
                          itemBuilder: (context, index) {
                            final script = categoryScripts[index];
                            return _buildScriptCard(script);
                          },
                        ),
                        const SizedBox(height: 32),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScriptCard(ScriptInfo script) {
    return fluent.Card(
      child: fluent.Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  script.icon,
                  color: script.color,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    script.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                script.description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: fluent.FilledButton(
                onPressed: () => _runScript(script),
                child: const Text('Run Script'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Package Managers':
        return fluent.FluentIcons.package;
      case 'Development':
        return fluent.FluentIcons.developer_tools;
      case 'Android Development':
        return fluent.FluentIcons.phone;
      case 'AI Development':
        return fluent.FluentIcons.robot;
      case 'Cloud Development':
        return fluent.FluentIcons.cloud;
      case 'Web Development':
        return fluent.FluentIcons.globe;
      case 'Applications':
        return fluent.FluentIcons.app_icon_default;
      case 'Containers':
        return fluent.FluentIcons.processing;
      case 'System Tools':
        return fluent.FluentIcons.settings;
      case 'Server Development':
        return fluent.FluentIcons.server;
      default:
        return fluent.FluentIcons.code;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Package Managers':
        return const Color(0xFF8B4513);
      case 'Development':
        return const Color(0xFF107C10);
      case 'Android Development':
        return const Color(0xFF3DDC84);
      case 'AI Development':
        return const Color(0xFF9C27B0);
      case 'Cloud Development':
        return const Color(0xFF2196F3);
      case 'Web Development':
        return const Color(0xFFE34F26);
      case 'Applications':
        return const Color(0xFF0078D4);
      case 'Containers':
        return const Color(0xFF2496ED);
      case 'System Tools':
        return const Color(0xFFE95420);
      case 'Server Development':
        return const Color(0xFF2E8B57);
      default:
        return const Color(0xFF666666);
    }
  }

  void _runScript(ScriptInfo script) async {
    try {
      // Get the script path
      final scriptPath = path.join(
        Directory.current.path,
        'windows_scripts',
        'script',
        script.fileName,
      );

      // Check if script exists
      if (!File(scriptPath).existsSync()) {
        _showErrorDialog('Script not found: ${script.fileName}');
        return;
      }

      // Show confirmation dialog
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => fluent.ContentDialog(
          title: const Text('Run Script'),
          content: Text('Are you sure you want to run "${script.name}"?\n\nThis will execute: ${script.fileName}'),
          actions: [
            fluent.Button(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            fluent.FilledButton(
              child: const Text('Run'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      );

      if (result == true) {
        // Show progress dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => fluent.ContentDialog(
            title: const Text('Running Script'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const fluent.ProgressRing(),
                const SizedBox(height: 16),
                Text('Executing ${script.name}...'),
              ],
            ),
          ),
        );

        // Execute the script
        final process = await Process.start(
          'powershell.exe',
          ['-ExecutionPolicy', 'Bypass', '-File', scriptPath],
          runInShell: true,
        );

        final exitCode = await process.exitCode;
        Navigator.of(context).pop(); // Close progress dialog

        if (exitCode == 0) {
          _showSuccessDialog('Script executed successfully!');
        } else {
          _showErrorDialog('Script execution failed with exit code: $exitCode');
        }
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close progress dialog if open
      _showErrorDialog('Error running script: $e');
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => fluent.ContentDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          fluent.FilledButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => fluent.ContentDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          fluent.FilledButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}