import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class AllComponentsPage extends StatelessWidget {
  const AllComponentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return fluent.ScaffoldPage(
      header: const fluent.PageHeader(
        title: Text('All Components CMD'),
      ),
      content: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            Text(
              'Installation Components',
              style: fluent.FluentTheme.of(context).typography.title,
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 8),
            Text(
              'Browse and install individual components from our comprehensive library',
              style: fluent.FluentTheme.of(context).typography.body,
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 32),

            // 1. AI Development
            _buildCategorySection(
              context,
              '1. AI Development',
              'Machine Learning and AI development tools',
              [
                {'name': 'Jupyter', 'script': 'jupyter.ps1', 'description': 'Interactive computing environment'},
                {'name': 'PyTorch', 'script': 'pytorch.ps1', 'description': 'Deep learning framework'},
                {'name': 'TensorFlow', 'script': 'tensorflow.ps1', 'description': 'Machine learning platform'},
              ],
              fluent.FluentIcons.robot,
              const Color(0xFF4CAF50),
              'ai-development',
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 32),

            // 2. Android Development
            _buildCategorySection(
              context,
              '2. Android Development',
              'Android app development tools and SDK',
              [
                {'name': 'ADB', 'script': 'adb.ps1', 'description': 'Android Debug Bridge'},
                {'name': 'Android SDK', 'script': 'android-sdk.ps1', 'description': 'Android Software Development Kit'},
                {'name': 'Android Studio', 'script': 'android-studio.ps1', 'description': 'Official Android IDE'},
              ],
              fluent.FluentIcons.phone,
              const Color(0xFF4CAF50),
              'android-development',
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 32),

            // 3. Backend Development
            _buildCategorySection(
              context,
              '3. Backend Development',
              'Server-side programming languages and runtimes',
              [
                {'name': '.NET', 'script': 'dotnet.ps1', 'description': 'Microsoft development platform'},
                {'name': 'Go', 'script': 'go.ps1', 'description': 'Google programming language'},
                {'name': 'Java', 'script': 'java.ps1', 'description': 'Java Development Kit'},
                {'name': 'Python', 'script': 'python.ps1', 'description': 'Python programming language'},
                {'name': 'Rust', 'script': 'rust.ps1', 'description': 'Systems programming language'},
              ],
              fluent.FluentIcons.server,
              const Color(0xFF2196F3),
              'backend-development',
            ).animate().fadeIn(delay: 500.ms),

            const SizedBox(height: 32),

            // 4. Basic Development
            _buildCategorySection(
              context,
              '4. Basic Development',
              'Essential development tools',
              [
                {'name': 'Git', 'script': 'git.ps1', 'description': 'Version control system'},
              ],
              fluent.FluentIcons.developer_tools,
              const Color(0xFFF44336),
              'basic-development',
            ).animate().fadeIn(delay: 600.ms),

            const SizedBox(height: 32),

            // 5. Browsers
            _buildCategorySection(
              context,
              '5. Browsers',
              'Web browsers for development and testing',
              [
                {'name': 'Chrome', 'script': 'chrome.ps1', 'description': 'Google Chrome browser'},
                {'name': 'Edge', 'script': 'edge.ps1', 'description': 'Microsoft Edge browser'},
                {'name': 'Firefox', 'script': 'firefox.ps1', 'description': 'Mozilla Firefox browser'},
              ],
              fluent.FluentIcons.globe,
              const Color(0xFFFF9800),
              'browsers',
            ).animate().fadeIn(delay: 700.ms),

            const SizedBox(height: 32),

            // 6. Cloud Development
            _buildCategorySection(
              context,
              '6. Cloud Development',
              'Cloud platform tools and CLI utilities',
              [
                {'name': 'AWS CLI', 'script': 'aws-cli.ps1', 'description': 'Amazon Web Services CLI'},
                {'name': 'Azure CLI', 'script': 'azure-cli.ps1', 'description': 'Microsoft Azure CLI'},
                {'name': 'Google Cloud CLI', 'script': 'gcloud.ps1', 'description': 'Google Cloud Platform CLI'},
                {'name': 'Kubectl', 'script': 'kubectl.ps1', 'description': 'Kubernetes command-line tool'},
              ],
              fluent.FluentIcons.cloud,
              const Color(0xFF9C27B0),
              'cloud-development',
            ).animate().fadeIn(delay: 800.ms),

            const SizedBox(height: 32),

            // 7. Containers
            _buildCategorySection(
              context,
              '7. Containers',
              'Containerization and orchestration tools',
              [
                {'name': 'Docker', 'script': 'docker.ps1', 'description': 'Container platform'},
                {'name': 'Docker Compose', 'script': 'docker-compose.ps1', 'description': 'Multi-container Docker applications'},
                {'name': 'Kubernetes', 'script': 'kubernetes.ps1', 'description': 'Container orchestration'},
              ],
              fluent.FluentIcons.processing,
              const Color(0xFF607D8B),
              'containers',
            ).animate().fadeIn(delay: 900.ms),

            const SizedBox(height: 32),

            // 8. Cross-Platform Flutter
            _buildCategorySection(
              context,
              '8. Cross-Platform Flutter',
              'Flutter framework for cross-platform development',
              [
                {'name': 'Dart', 'script': 'dart.ps1', 'description': 'Dart programming language'},
                {'name': 'Flutter', 'script': 'flutter.ps1', 'description': 'Flutter framework'},
                {'name': 'Flutter Doctor', 'script': 'flutter-doctor.ps1', 'description': 'Flutter environment checker'},
              ],
              fluent.FluentIcons.devices4,
              const Color(0xFF2196F3),
              'cross-platform-flutter',
            ).animate().fadeIn(delay: 1000.ms),

            const SizedBox(height: 32),

            // 9. Cross-Platform React Native
            _buildCategorySection(
              context,
              '9. Cross-Platform React Native',
              'React Native for mobile app development',
              [
                {'name': 'Hermes', 'script': 'hermes.ps1', 'description': 'JavaScript engine for React Native'},
                {'name': 'Metro', 'script': 'metro.ps1', 'description': 'JavaScript bundler for React Native'},
                {'name': 'React Native', 'script': 'react-native.ps1', 'description': 'React Native framework'},
              ],
              fluent.FluentIcons.devices3,
              const Color(0xFF61DAFB),
              'cross-platform-react-native',
            ).animate().fadeIn(delay: 1100.ms),

            const SizedBox(height: 32),

            // 10. Databases
            _buildCategorySection(
              context,
              '10. Databases',
              'Database management systems',
              [
                {'name': 'MongoDB', 'script': 'mongodb.ps1', 'description': 'NoSQL document database'},
                {'name': 'MySQL', 'script': 'mysql.ps1', 'description': 'Relational database management system'},
                {'name': 'PostgreSQL', 'script': 'postgresql.ps1', 'description': 'Advanced relational database'},
              ],
              fluent.FluentIcons.database,
              const Color(0xFF4CAF50),
              'databases',
            ).animate().fadeIn(delay: 1200.ms),

            const SizedBox(height: 32),

            // 11. Package Managers
            _buildCategorySection(
              context,
              '11. Package Managers',
              'Package management tools for Windows',
              [
                {'name': 'Chocolatey', 'script': 'chocolatey.ps1', 'description': 'Package manager for Windows'},
                {'name': 'WinGet', 'script': 'winget.ps1', 'description': 'Windows Package Manager'},
              ],
              fluent.FluentIcons.package,
              const Color(0xFFFF5722),
              'package-managers',
            ).animate().fadeIn(delay: 1300.ms),

            const SizedBox(height: 32),

            // 12. Server Development
            _buildCategorySection(
              context,
              '12. Server Development',
              'Web servers and development stacks',
              [
                {'name': 'Apache', 'script': 'apache.ps1', 'description': 'Apache HTTP Server'},
                {'name': 'Nginx', 'script': 'nginx.ps1', 'description': 'High-performance web server'},
                {'name': 'XAMPP', 'script': 'xampp.ps1', 'description': 'Complete web development stack'},
              ],
              fluent.FluentIcons.server_enviroment,
              const Color(0xFF795548),
              'server-development',
            ).animate().fadeIn(delay: 1400.ms),

            const SizedBox(height: 32),

            // 13. Web Development
            _buildCategorySection(
              context,
              '13. Web Development',
              'Web development tools and runtimes',
              [
                {'name': 'Node.js', 'script': 'nodejs.ps1', 'description': 'JavaScript runtime environment'},
              ],
              fluent.FluentIcons.globe,
              const Color(0xFF4CAF50),
              'web-development',
            ).animate().fadeIn(delay: 1500.ms),

            const SizedBox(height: 32),

            // 14. Windows Development
            _buildCategorySection(
              context,
              '14. Windows Development',
              'Windows-specific development tools',
              [
                {'name': 'PowerShell', 'script': 'powershell.ps1', 'description': 'PowerShell scripting environment'},
                {'name': 'Visual Studio', 'script': 'visual-studio.ps1', 'description': 'Microsoft Visual Studio IDE'},
                {'name': 'VS Code', 'script': 'vscode.ps1', 'description': 'Visual Studio Code editor'},
              ],
              fluent.FluentIcons.developer_tools,
              const Color(0xFF0078D4),
              'windows-development',
            ).animate().fadeIn(delay: 1600.ms),

            const SizedBox(height: 32),

            // 15. WSL Development
            _buildCategorySection(
              context,
              '15. WSL Development',
              'Windows Subsystem for Linux',
              [
                {'name': 'WSL', 'script': 'wsl.ps1', 'description': 'Windows Subsystem for Linux'},
                {'name': 'Ubuntu', 'script': 'ubuntu.ps1', 'description': 'Ubuntu Linux distribution'},
                {'name': 'Kali Linux', 'script': 'kali.ps1', 'description': 'Kali Linux distribution'},
              ],
              fluent.FluentIcons.developer_tools,
              const Color(0xFFE95420),
              'wsl-development',
            ).animate().fadeIn(delay: 1700.ms),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    String title,
    String description,
    List<Map<String, String>> componentData,
    IconData icon,
    Color color,
    String categoryPath,
  ) {
    return Container(
      width: double.infinity,
      child: fluent.Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      size: 24,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  fluent.Button(
                    onPressed: () => _installAllInCategory(context, title, categoryPath),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(fluent.FluentIcons.installation, size: 14),
                        const SizedBox(width: 6),
                        const Text('Install All'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...componentData.map((comp) => _buildComponentItem(
                context,
                comp['name']!,
                comp['script']!,
                comp['description']!,
              )).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComponentItem(BuildContext context, String name, String scriptFile, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and description
          Row(
            children: [
              Icon(
                fluent.FluentIcons.package,
                size: 18,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Action buttons row
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildActionButton(
                'Test',
                fluent.FluentIcons.test_case,
                Colors.blue,
                () => _executeComponentAction(context, name, scriptFile, 'test'),
              ),
              _buildActionButton(
                'Version',
                fluent.FluentIcons.info,
                Colors.purple,
                () => _executeComponentAction(context, name, scriptFile, 'version'),
              ),
              _buildActionButton(
                'Status',
                fluent.FluentIcons.status_circle_checkmark,
                Colors.green,
                () => _executeComponentAction(context, name, scriptFile, 'status'),
              ),
              _buildActionButton(
                'Path',
                fluent.FluentIcons.folder_open,
                Colors.orange,
                () => _executeComponentAction(context, name, scriptFile, 'path'),
              ),
              _buildActionButton(
                'Install',
                fluent.FluentIcons.installation,
                Colors.teal,
                () => _executeComponentAction(context, name, scriptFile, 'install'),
              ),
              _buildActionButton(
                'Update',
                fluent.FluentIcons.update_restore,
                Colors.indigo,
                () => _executeComponentAction(context, name, scriptFile, 'update'),
              ),
              _buildActionButton(
                'Reinstall',
                fluent.FluentIcons.refresh,
                Colors.red,
                () => _executeComponentAction(context, name, scriptFile, 'reinstall'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return fluent.Button(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color),
          ),
        ],
      ),
    );
  }

  void _executeComponentAction(BuildContext context, String componentName, String scriptFile, String action) async {
    // Generate the appropriate script name based on action
    String actionScriptFile = _getActionScriptName(scriptFile, action);
    
    final result = await fluent.showDialog<bool>(
      context: context,
      builder: (context) => fluent.ContentDialog(
        title: Text('${_getActionTitle(action)} $componentName'),
        content: Text(
          '${_getActionDescription(action, componentName)}\n\n'
          'This action will run in an external PowerShell terminal.\n\n'
          'Do you want to continue?',
        ),
        actions: [
          fluent.Button(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          fluent.FilledButton(
            child: Text(_getActionTitle(action)),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (result == true) {
      _executeComponentActionScript(context, componentName, actionScriptFile, action);
    }
  }

  String _getActionScriptName(String baseScriptFile, String action) {
    // Remove .ps1 extension and add action suffix
    String baseName = baseScriptFile.replaceAll('.ps1', '');
    switch (action) {
      case 'test':
        return '$baseName-test.ps1';
      case 'version':
        return '$baseName-version.ps1';
      case 'status':
        return '$baseName-status.ps1';
      case 'path':
        return '$baseName-path.ps1';
      case 'install':
        return baseScriptFile; // Use original script for install
      case 'update':
        return '$baseName-update.ps1';
      case 'reinstall':
        return '$baseName-reinstall.ps1';
      default:
        return baseScriptFile;
    }
  }

  String _getActionTitle(String action) {
    switch (action) {
      case 'test':
        return 'Test';
      case 'version':
        return 'Check Version';
      case 'status':
        return 'Check Status';
      case 'path':
        return 'Show Path';
      case 'install':
        return 'Install';
      case 'update':
        return 'Update';
      case 'reinstall':
        return 'Reinstall';
      default:
        return 'Execute';
    }
  }

  String _getActionDescription(String action, String componentName) {
    switch (action) {
      case 'test':
        return 'This will test if $componentName is working correctly.';
      case 'version':
        return 'This will check the installed version of $componentName.';
      case 'status':
        return 'This will check the installation status of $componentName.';
      case 'path':
        return 'This will show the installation path of $componentName.';
      case 'install':
        return 'This will install $componentName on your system.';
      case 'update':
        return 'This will update $componentName to the latest version.';
      case 'reinstall':
        return 'This will completely reinstall $componentName.';
      default:
        return 'This will execute an action for $componentName.';
    }
  }

  void _executeComponentActionScript(BuildContext context, String componentName, String scriptFile, String action) async {
    try {
      // Launch script in external terminal with action parameter
      await _runScriptByNameWithAction(scriptFile, action);
      
      // Show success notification
      if (context.mounted) {
        fluent.displayInfoBar(
          context,
          builder: (context, close) => fluent.InfoBar(
            title: Text('${_getActionTitle(action)} Script Launched'),
            content: Text('$componentName ${action} script has been launched in external terminal.'),
            severity: fluent.InfoBarSeverity.success,
            onClose: close,
          ),
        );
      }
    } catch (e) {
      // Show error notification
      if (context.mounted) {
        fluent.displayInfoBar(
          context,
          builder: (context, close) => fluent.InfoBar(
            title: Text('${_getActionTitle(action)} Script Error'),
            content: Text('Failed to launch ${action} script: $e'),
            severity: fluent.InfoBarSeverity.error,
            onClose: close,
          ),
        );
      }
    }
  }

  void _installAllInCategory(BuildContext context, String categoryName, String categoryPath) async {
    final result = await fluent.showDialog<bool>(
      context: context,
      builder: (context) => fluent.ContentDialog(
        title: Text('Install All $categoryName'),
        content: Text(
          'This will install all components in the $categoryName category.\n\n'
          'This process may take several minutes and requires administrator privileges.\n\n'
          'Do you want to continue?',
        ),
        actions: [
          fluent.Button(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          fluent.FilledButton(
            child: const Text('Install All'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (result == true) {
      _executeCategoryInstallation(context, categoryName, categoryPath);
    }
  }

  void _installSingleComponent(BuildContext context, String componentName, String scriptFile) async {
    final result = await fluent.showDialog<bool>(
      context: context,
      builder: (context) => fluent.ContentDialog(
        title: Text('Install $componentName'),
        content: Text(
          'This will install $componentName on your system.\n\n'
          'The installation requires administrator privileges and may take a few minutes.\n\n'
          'Do you want to continue?',
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
      _executeComponentInstallation(context, componentName, scriptFile);
    }
  }

  void _executeCategoryInstallation(BuildContext context, String categoryName, String categoryPath) async {
    try {
      // Execute the category installation script in external terminal
      final scriptPath = path.join('windows_scripts', 'core', categoryPath, 'install-all.ps1');
      await _runScript(scriptPath);
      
      // Show success notification
      if (context.mounted) {
        fluent.displayInfoBar(
          context,
          builder: (context, close) => fluent.InfoBar(
            title: const Text('Script Launched'),
            content: Text('$categoryName installation script has been launched in external terminal.'),
            severity: fluent.InfoBarSeverity.success,
            onClose: close,
          ),
        );
      }
    } catch (e) {
      // Show error notification
      if (context.mounted) {
        fluent.displayInfoBar(
          context,
          builder: (context, close) => fluent.InfoBar(
            title: const Text('Launch Error'),
            content: Text('Failed to launch installation script: $e'),
            severity: fluent.InfoBarSeverity.error,
            onClose: close,
          ),
        );
      }
    }
  }

  void _executeComponentInstallation(BuildContext context, String componentName, String scriptFile) async {
    try {
      // Launch script in external terminal
      await _runScriptByName(scriptFile);
      
      // Show success notification
      if (context.mounted) {
        fluent.displayInfoBar(
          context,
          builder: (context, close) => fluent.InfoBar(
            title: const Text('Script Launched'),
            content: Text('$componentName installation script has been launched in external terminal.'),
            severity: fluent.InfoBarSeverity.success,
            onClose: close,
          ),
        );
      }
    } catch (e) {
      // Show error notification
      if (context.mounted) {
        fluent.displayInfoBar(
          context,
          builder: (context, close) => fluent.InfoBar(
            title: const Text('Launch Error'),
            content: Text('Failed to launch installation script: $e'),
            severity: fluent.InfoBarSeverity.error,
            onClose: close,
          ),
        );
      }
    }
  }

  Future<void> _runScript(String scriptPath) async {
    // Run PowerShell script in external terminal window
    final process = await Process.start(
      'powershell.exe',
      [
        '-ExecutionPolicy',
        'Bypass',
        '-Command',
        'Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -NoExit -Command \\"& \'$scriptPath\'; Write-Host \'Script execution completed. Press any key to exit...\'; Read-Host\\"" -Verb RunAs'
      ],
      runInShell: true,
    );

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw Exception('Failed to launch external terminal for script $scriptPath');
    }
  }

  Future<void> _runScriptWithParams(String scriptPath, List<String> params) async {
    // Build parameter string for PowerShell
    final paramString = params.map((param) => '-$param').join(' ');
    
    // Run PowerShell script in external terminal window with parameters
    final process = await Process.start(
      'powershell.exe',
      [
        '-ExecutionPolicy',
        'Bypass',
        '-Command',
        'Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -NoExit -Command \\"& \'$scriptPath\' $paramString; Write-Host \'Script execution completed. Press any key to exit...\'; Read-Host\\"" -Verb RunAs'
      ],
      runInShell: true,
    );

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw Exception('Failed to launch external terminal for script $scriptPath with parameters');
    }
  }

  Future<void> _runScriptByNameWithAction(String scriptFileName, String action) async {
    // First, try to find the script in core subdirectories
    final coreDir = Directory(path.join('windows_scripts', 'core'));
    
    if (coreDir.existsSync()) {
      for (final entity in coreDir.listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith(scriptFileName)) {
          await _runScriptWithParams(entity.path, ['Action $action']);
          return;
        }
      }
    }
    
    // Fallback: try common script locations
    final fallbackPaths = [
      path.join('windows_scripts', scriptFileName),
      path.join('windows_scripts', 'scripts', scriptFileName),
      path.join('windows_scripts', 'core', scriptFileName),
    ];
    
    for (final fallbackPath in fallbackPaths) {
      final file = File(fallbackPath);
      if (file.existsSync()) {
        await _runScriptWithParams(file.path, ['Action $action']);
        return;
      }
    }
    
    throw Exception('Script $scriptFileName not found in any search location');
  }

  Future<void> _runScriptByName(String scriptFileName) async {
    // First, try to find the script in core subdirectories
    final coreDir = Directory(path.join('windows_scripts', 'core'));
    
    if (coreDir.existsSync()) {
      for (final entity in coreDir.listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith(scriptFileName)) {
          await _runScript(entity.path);
          return;
        }
      }
    }
    
    // Fallback: try common script locations
    final fallbackPaths = [
      path.join('windows_scripts', scriptFileName),
      path.join('windows_scripts', 'scripts', scriptFileName),
      path.join('windows_scripts', 'core', scriptFileName),
    ];
    
    for (final fallbackPath in fallbackPaths) {
      final file = File(fallbackPath);
      if (file.existsSync()) {
        await _runScript(file.path);
        return;
      }
    }
    
    throw Exception('Script $scriptFileName not found in any search location');
  }
}