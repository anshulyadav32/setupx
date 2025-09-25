import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return fluent.ScaffoldPage(
      header: const fluent.PageHeader(
        title: Text('Dashboard'),
      ),
      content: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to SetupX',
              style: fluent.FluentTheme.of(context).typography.titleLarge,
            ).animate().fadeIn().slideY(begin: -0.2),
            const SizedBox(height: 8),
            Text(
              'Windows',
              style: fluent.FluentTheme.of(context).typography.title?.copyWith(
                color: fluent.FluentTheme.of(context).accentColor,
                fontWeight: FontWeight.w600,
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 16),
            Text(
              'Automate your Windows system setup with ease',
              style: fluent.FluentTheme.of(context).typography.body,
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 48),

            // 1. Install All in One CMD Section
            _buildSectionHeader(context, '1. Install All in One CMD', fluent.FluentIcons.command_prompt),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              child: fluent.Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            fluent.FluentIcons.installation,
                            size: 24,
                            color: const Color(0xFF8B4513),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Complete System Setup',
                            style: fluent.FluentTheme.of(context).typography.bodyStrong,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Install all package managers, development tools, and essential software with a single command.',
                        style: fluent.FluentTheme.of(context).typography.body,
                      ),
                      const SizedBox(height: 16),
                      fluent.FilledButton(
                        onPressed: () => _installAllInOne(context),
                        style: fluent.ButtonStyle(
                          backgroundColor: fluent.ButtonState.all(const Color(0xFF8B4513)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(fluent.FluentIcons.play, size: 16),
                            SizedBox(width: 8),
                            Text('Install All in One'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 32),

            // 2. Install CLI Section
            _buildSectionHeader(context, '2. Install CLI', fluent.FluentIcons.command_prompt),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              child: fluent.Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            fluent.FluentIcons.developer_tools,
                            size: 24,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Command Line Tools',
                            style: fluent.FluentTheme.of(context).typography.bodyStrong,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Install essential command line interfaces and development tools.',
                        style: fluent.FluentTheme.of(context).typography.body,
                      ),
                      const SizedBox(height: 16),
                      fluent.FilledButton(
                        onPressed: () => _installCLI(context),
                        style: fluent.ButtonStyle(
                          backgroundColor: fluent.ButtonState.all(Colors.blue),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(fluent.FluentIcons.command_prompt, size: 16),
                            SizedBox(width: 8),
                            Text('Install CLI Tools'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 48),

            // Modules Section
            _buildSectionHeader(context, 'Modules', fluent.FluentIcons.puzzle),
            const SizedBox(height: 24),

            // 1. Package Manager Subsection
            Text(
              '1. Package Manager',
              style: fluent.FluentTheme.of(context).typography.subtitle?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ).animate().fadeIn(delay: 500.ms),
            const SizedBox(height: 16),
            
            Container(
              width: double.infinity,
              child: fluent.Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            fluent.FluentIcons.package,
                            size: 24,
                            color: const Color(0xFF8B4513),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Package Managers',
                            style: fluent.FluentTheme.of(context).typography.bodyStrong,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Install essential package managers: Chocolatey, Scoop, and WinGet for seamless software management.',
                        style: fluent.FluentTheme.of(context).typography.body,
                      ),
                      const SizedBox(height: 16),
                      fluent.FilledButton(
                        onPressed: () => _installAllPackageManagers(context),
                        style: fluent.ButtonStyle(
                          backgroundColor: fluent.ButtonState.all(const Color(0xFF8B4513)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(fluent.FluentIcons.package, size: 16),
                            SizedBox(width: 8),
                            Text('Install All Package Managers'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 500.ms),
            const SizedBox(height: 32),
            
            // Installation Categories Section - Reorganized
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Development Setup Flow',
                    style: fluent.FluentTheme.of(context).typography.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  // 1. Basic Dev Tools Row
                  _buildCategoryRow(
                    context,
                    '1. Basic Development Tools',
                    [
                      _buildQuickInstallCard(
                        'VS Code',
                        'Code Editor',
                        fluent.FluentIcons.code,
                        const Color(0xFF007ACC),
                        () => _runSingleScript(context, 'install-vscode-enhanced.ps1', 'VS Code'),
                      ),
                      _buildQuickInstallCard(
                        'GitHub CLI',
                        'Git Command Line',
                        fluent.FluentIcons.git_graph,
                        const Color(0xFF24292e),
                        () => _runSingleScript(context, 'install-github-cli.ps1', 'GitHub CLI'),
                      ),
                      _buildQuickInstallCard(
                        'Git',
                        'Version Control',
                        fluent.FluentIcons.git_graph,
                        const Color(0xFFF05032),
                        () => _runSingleScript(context, 'install-git.ps1', 'Git'),
                      ),
                      _buildQuickInstallCard(
                        'Node.js',
                        'JavaScript Runtime',
                        fluent.FluentIcons.code,
                        const Color(0xFF339933),
                        () => _runSingleScript(context, 'install-nodejs-lts.ps1', 'Node.js'),
                      ),
                      _buildQuickInstallCard(
                        'Python',
                        'Programming Language',
                        fluent.FluentIcons.code,
                        const Color(0xFF3776AB),
                        () => _runSingleScript(context, 'install-python-enhanced.ps1', 'Python'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 2. Web Development Row
                  _buildCategoryRow(
                    context,
                    '2. Web Development',
                    [
                      _buildQuickInstallCard(
                        'Web Dev Stack',
                        'React, Vue, Angular',
                        fluent.FluentIcons.globe,
                        const Color(0xFFFF5722),
                        () => _runSingleScript(context, 'install-web-development-stack.ps1', 'Web Dev Stack'),
                      ),
                      _buildQuickInstallCard(
                        'Browsers',
                        'Chrome, Firefox, Edge',
                        fluent.FluentIcons.globe,
                        const Color(0xFF4285F4),
                        () => _runSingleScript(context, 'install-browsers-enhanced.ps1', 'Browsers'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 3. Android Development Row
                  _buildCategoryRow(
                    context,
                    '3. Android Development',
                    [
                      _buildQuickInstallCard(
                        'Android Studio',
                        'Android IDE',
                        fluent.FluentIcons.app_icon_default,
                        const Color(0xFF3DDC84),
                        () => _runSingleScript(context, 'install-android-studio.ps1', 'Android Studio'),
                      ),
                      _buildQuickInstallCard(
                        'Android SDK',
                        'Development Kit',
                        fluent.FluentIcons.developer_tools,
                        const Color(0xFF3DDC84),
                        () => _runSingleScript(context, 'install-android-sdk.ps1', 'Android SDK'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 4. Cross-Platform Development Row
                  _buildCategoryRow(
                    context,
                    '4. Cross-Platform Development',
                    [
                      _buildQuickInstallCard(
                        'Flutter',
                        'Cross-Platform UI',
                        fluent.FluentIcons.app_icon_default,
                        const Color(0xFF02569B),
                        () => _runSingleScript(context, 'install-flutter.ps1', 'Flutter'),
                      ),
                      _buildQuickInstallCard(
                        'React Native',
                        'Mobile Development',
                        fluent.FluentIcons.app_icon_default,
                        const Color(0xFF61DAFB),
                        () => _runSingleScript(context, 'install-react-native.ps1', 'React Native'),
                      ),
                      _buildQuickInstallCard(
                        'Xamarin',
                        'Microsoft Mobile',
                        fluent.FluentIcons.app_icon_default,
                        const Color(0xFF3498DB),
                        () => _runSingleScript(context, 'install-xamarin.ps1', 'Xamarin'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 5. Windows Development Row
                  _buildCategoryRow(
                    context,
                    '5. Windows Development',
                    [
                      _buildQuickInstallCard(
                        'Visual Studio',
                        'Windows IDE',
                        fluent.FluentIcons.app_icon_default,
                        const Color(0xFF5C2D91),
                        () => _runSingleScript(context, 'install-visual-studio.ps1', 'Visual Studio'),
                      ),
                      _buildQuickInstallCard(
                        '.NET SDK',
                        'Microsoft Framework',
                        fluent.FluentIcons.developer_tools,
                        const Color(0xFF512BD4),
                        () => _runSingleScript(context, 'install-dotnet-sdk.ps1', '.NET SDK'),
                      ),
                      _buildQuickInstallCard(
                        'WSL2',
                        'Linux Subsystem',
                        fluent.FluentIcons.command_prompt,
                        const Color(0xFFE95420),
                        () => _runSingleScript(context, 'install-wsl2-ubuntu.ps1', 'WSL2'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 6. Basic Software Row
                  _buildCategoryRow(
                    context,
                    '6. Basic Software',
                    [
                      _buildQuickInstallCard(
                        'Essential Apps',
                        '7-Zip, VLC, etc.',
                        fluent.FluentIcons.app_icon_default,
                        const Color(0xFF607D8B),
                        () => _runSingleScript(context, 'install-essential-apps.ps1', 'Essential Apps'),
                      ),
                      _buildQuickInstallCard(
                        'Media Tools',
                        'VLC, OBS, etc.',
                        fluent.FluentIcons.video,
                        const Color(0xFFFF9800),
                        () => _runSingleScript(context, 'install-media-tools.ps1', 'Media Tools'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 7. Additional IDEs Row
                  _buildCategoryRow(
                    context,
                    '7. Additional IDEs',
                    [
                      _buildQuickInstallCard(
                        'JetBrains IDEs',
                        'IntelliJ, WebStorm',
                        fluent.FluentIcons.app_icon_default,
                        const Color(0xFF000000),
                        () => _runSingleScript(context, 'install-jetbrains-ides.ps1', 'JetBrains IDEs'),
                      ),
                      _buildQuickInstallCard(
                        'Sublime Text',
                        'Text Editor',
                        fluent.FluentIcons.code,
                        const Color(0xFFFF9800),
                        () => _runSingleScript(context, 'install-sublime-text.ps1', 'Sublime Text'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 8. AI CLI Tools Row
                  _buildCategoryRow(
                    context,
                    '8. AI CLI Tools',
                    [
                      _buildQuickInstallCard(
                        'GitHub Copilot CLI',
                        'AI Assistant',
                        fluent.FluentIcons.robot,
                        const Color(0xFF9C27B0),
                        () => _runSingleScript(context, 'install-github-copilot-cli.ps1', 'GitHub Copilot CLI'),
                      ),
                      _buildQuickInstallCard(
                        'OpenAI CLI',
                        'ChatGPT CLI',
                        fluent.FluentIcons.robot,
                        const Color(0xFF00A67E),
                        () => _runSingleScript(context, 'install-openai-cli.ps1', 'OpenAI CLI'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 9. Cloud CLI Tools Row
                  _buildCategoryRow(
                    context,
                    '9. Cloud CLI Tools',
                    [
                      _buildQuickInstallCard(
                        'AWS CLI',
                        'Amazon Web Services',
                        fluent.FluentIcons.cloud,
                        const Color(0xFFFF9900),
                        () => _runCoreScript(context, 'aws-cli.ps1', 'AWS CLI'),
                      ),
                      _buildQuickInstallCard(
                        'Azure CLI',
                        'Microsoft Azure',
                        fluent.FluentIcons.cloud,
                        const Color(0xFF0078D4),
                        () => _runCoreScript(context, 'azure-cli.ps1', 'Azure CLI'),
                      ),
                      _buildQuickInstallCard(
                        'Google Cloud CLI',
                        'Google Cloud Platform',
                        fluent.FluentIcons.cloud,
                        const Color(0xFF4285F4),
                        () => _runCoreScript(context, 'gcloud.ps1', 'Google Cloud CLI'),
                      ),
                      _buildQuickInstallCard(
                        'Kubectl',
                        'Kubernetes CLI',
                        fluent.FluentIcons.cloud,
                        const Color(0xFF326CE5),
                        () => _runCoreScript(context, 'kubectl.ps1', 'Kubectl'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 10. AI Development Row
                  _buildCategoryRow(
                    context,
                    '10. AI Development',
                    [
                      _buildQuickInstallCard(
                        'Jupyter',
                        'Interactive Notebooks',
                        fluent.FluentIcons.code,
                        const Color(0xFFF37626),
                        () => _runCoreScript(context, 'jupyter.ps1', 'Jupyter'),
                      ),
                      _buildQuickInstallCard(
                        'PyTorch',
                        'Machine Learning',
                        fluent.FluentIcons.robot,
                        const Color(0xFFEE4C2C),
                        () => _runCoreScript(context, 'pytorch.ps1', 'PyTorch'),
                      ),
                      _buildQuickInstallCard(
                        'TensorFlow',
                        'Deep Learning',
                        fluent.FluentIcons.robot,
                        const Color(0xFFFF6F00),
                        () => _runCoreScript(context, 'tensorflow.ps1', 'TensorFlow'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 11. Backend Development Row
                  _buildCategoryRow(
                    context,
                    '11. Backend Development',
                    [
                      _buildQuickInstallCard(
                        '.NET Core',
                        'Microsoft Framework',
                        fluent.FluentIcons.developer_tools,
                        const Color(0xFF512BD4),
                        () => _runCoreScript(context, 'dotnet.ps1', '.NET Core'),
                      ),
                      _buildQuickInstallCard(
                        'Go',
                        'Google Language',
                        fluent.FluentIcons.code,
                        const Color(0xFF00ADD8),
                        () => _runCoreScript(context, 'go.ps1', 'Go'),
                      ),
                      _buildQuickInstallCard(
                        'Java',
                        'Oracle Language',
                        fluent.FluentIcons.code,
                        const Color(0xFFED8B00),
                        () => _runCoreScript(context, 'java.ps1', 'Java'),
                      ),
                      _buildQuickInstallCard(
                        'Python',
                        'Programming Language',
                        fluent.FluentIcons.code,
                        const Color(0xFF3776AB),
                        () => _runCoreScript(context, 'python.ps1', 'Python'),
                      ),
                      _buildQuickInstallCard(
                        'Rust',
                        'Systems Language',
                        fluent.FluentIcons.code,
                        const Color(0xFF000000),
                        () => _runCoreScript(context, 'rust.ps1', 'Rust'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 12. Container Development Row
                  _buildCategoryRow(
                    context,
                    '12. Container Development',
                    [
                      _buildQuickInstallCard(
                        'Docker',
                        'Containerization',
                        fluent.FluentIcons.developer_tools,
                        const Color(0xFF2496ED),
                        () => _runCoreScript(context, 'docker.ps1', 'Docker'),
                      ),
                      _buildQuickInstallCard(
                        'Docker Compose',
                        'Multi-container Apps',
                        fluent.FluentIcons.developer_tools,
                        const Color(0xFF2496ED),
                        () => _runCoreScript(context, 'docker-compose.ps1', 'Docker Compose'),
                      ),
                      _buildQuickInstallCard(
                        'Kubernetes',
                        'Container Orchestration',
                        fluent.FluentIcons.cloud,
                        const Color(0xFF326CE5),
                        () => _runCoreScript(context, 'kubernetes.ps1', 'Kubernetes'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 13. Database Development Row
                  _buildCategoryRow(
                    context,
                    '13. Database Development',
                    [
                      _buildQuickInstallCard(
                        'MongoDB',
                        'NoSQL Database',
                        fluent.FluentIcons.database,
                        const Color(0xFF47A248),
                        () => _runCoreScript(context, 'mongodb.ps1', 'MongoDB'),
                      ),
                      _buildQuickInstallCard(
                        'MySQL',
                        'Relational Database',
                        fluent.FluentIcons.database,
                        const Color(0xFF4479A1),
                        () => _runCoreScript(context, 'mysql.ps1', 'MySQL'),
                      ),
                      _buildQuickInstallCard(
                        'PostgreSQL',
                        'Advanced Database',
                        fluent.FluentIcons.database,
                        const Color(0xFF336791),
                        () => _runCoreScript(context, 'postgresql.ps1', 'PostgreSQL'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 14. Server Development Row
                  _buildCategoryRow(
                    context,
                    '14. Server Development',
                    [
                      _buildQuickInstallCard(
                        'Apache',
                        'Web Server',
                        fluent.FluentIcons.globe,
                        const Color(0xFFD22128),
                        () => _runCoreScript(context, 'apache.ps1', 'Apache'),
                      ),
                      _buildQuickInstallCard(
                        'Nginx',
                        'Web Server',
                        fluent.FluentIcons.globe,
                        const Color(0xFF009639),
                        () => _runCoreScript(context, 'nginx.ps1', 'Nginx'),
                      ),
                      _buildQuickInstallCard(
                        'XAMPP',
                        'Development Stack',
                        fluent.FluentIcons.globe,
                        const Color(0xFFFB7A24),
                        () => _runCoreScript(context, 'xampp.ps1', 'XAMPP'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 15. Enhanced Android Development Row
                  _buildCategoryRow(
                    context,
                    '15. Enhanced Android Development',
                    [
                      _buildQuickInstallCard(
                        'ADB',
                        'Android Debug Bridge',
                        fluent.FluentIcons.developer_tools,
                        const Color(0xFF3DDC84),
                        () => _runCoreScript(context, 'adb.ps1', 'ADB'),
                      ),
                      _buildQuickInstallCard(
                        'Android SDK Core',
                        'Core SDK Tools',
                        fluent.FluentIcons.developer_tools,
                        const Color(0xFF3DDC84),
                        () => _runCoreScript(context, 'android-sdk.ps1', 'Android SDK'),
                      ),
                      _buildQuickInstallCard(
                        'Android Studio Core',
                        'IDE Core Install',
                        fluent.FluentIcons.app_icon_default,
                        const Color(0xFF3DDC84),
                        () => _runCoreScript(context, 'android-studio.ps1', 'Android Studio'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 16. Enhanced Cross-Platform Row
                  _buildCategoryRow(
                    context,
                    '16. Enhanced Cross-Platform',
                    [
                      _buildQuickInstallCard(
                        'Dart',
                        'Programming Language',
                        fluent.FluentIcons.code,
                        const Color(0xFF0175C2),
                        () => _runCoreScript(context, 'dart.ps1', 'Dart'),
                      ),
                      _buildQuickInstallCard(
                        'Flutter Core',
                        'UI Framework',
                        fluent.FluentIcons.app_icon_default,
                        const Color(0xFF02569B),
                        () => _runCoreScript(context, 'flutter.ps1', 'Flutter'),
                      ),
                      _buildQuickInstallCard(
                        'Flutter Doctor',
                        'Environment Check',
                        fluent.FluentIcons.health,
                        const Color(0xFF02569B),
                        () => _runCoreScript(context, 'flutter-doctor.ps1', 'Flutter Doctor'),
                      ),
                      _buildQuickInstallCard(
                        'React Native Core',
                        'Mobile Framework',
                        fluent.FluentIcons.app_icon_default,
                        const Color(0xFF61DAFB),
                        () => _runCoreScript(context, 'react-native.ps1', 'React Native'),
                      ),
                      _buildQuickInstallCard(
                        'Hermes',
                        'JS Engine',
                        fluent.FluentIcons.code,
                        const Color(0xFF61DAFB),
                        () => _runCoreScript(context, 'hermes.ps1', 'Hermes'),
                      ),
                      _buildQuickInstallCard(
                        'Metro',
                        'JS Bundler',
                        fluent.FluentIcons.code,
                        const Color(0xFF61DAFB),
                        () => _runCoreScript(context, 'metro.ps1', 'Metro'),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 350.ms).slideX(begin: -0.2),
            
            const SizedBox(height: 24),
            
            // Dashboard Cards Section
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildDashboardCard(
                  'Package Managers',
                  'Install Chocolatey, Scoop, and Winget',
                  fluent.FluentIcons.package,
                  const Color(0xFF0078D4),
                  context,
                ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.8, 0.8)),
                _buildDashboardCard(
                  'Software Installation',
                  'Install essential software packages',
                  fluent.FluentIcons.download,
                  const Color(0xFF107C10),
                  context,
                ).animate().fadeIn(delay: 600.ms).scale(begin: const Offset(0.8, 0.8)),
                _buildDashboardCard(
                  'System Settings',
                  'Configure Windows settings',
                  fluent.FluentIcons.settings,
                  const Color(0xFFFF8C00),
                  context,
                ).animate().fadeIn(delay: 800.ms).scale(begin: const Offset(0.8, 0.8)),
                _buildDashboardCard(
                  'System Status',
                  'View system information',
                  fluent.FluentIcons.info,
                  const Color(0xFF5C2D91),
                  context,
                ).animate().fadeIn(delay: 1000.ms).scale(begin: const Offset(0.8, 0.8)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(String title, String subtitle, IconData icon, Color color, BuildContext context) {
    return fluent.Card(
      child: Container(
        height: 200, // Increased height to accommodate buttons
        padding: const EdgeInsets.all(12.0), // Reduced padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon container
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 16,
              ),
            ),
            const SizedBox(height: 8),
            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Subtitle with flexible height
            Flexible(
              child: Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 11,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            // Action buttons row - compact layout
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Flexible(
                  child: _buildActionButton(
                    fluent.FluentIcons.download,
                    'DL',
                    color,
                    () => _downloadScripts(context, title),
                  ),
                ),
                const SizedBox(width: 2),
                Flexible(
                  child: _buildActionButton(
                    fluent.FluentIcons.play,
                    'Run',
                    color,
                    () => _runCategoryScripts(context, title),
                  ),
                ),
                const SizedBox(width: 2),
                Flexible(
                  child: _buildActionButton(
                    fluent.FluentIcons.copy,
                    'Copy',
                    color,
                    () => _copyScriptCommands(context, title),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInstallCard(String title, String subtitle, IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      width: 180,
      height: 120,
      child: fluent.Card(
        child: fluent.Button(
          onPressed: onPressed,
          style: fluent.ButtonStyle(
            padding: fluent.ButtonState.all(const EdgeInsets.all(12)),
            backgroundColor: fluent.ButtonState.resolveWith((states) {
              if (states.contains(fluent.ButtonStates.pressed)) {
                return color.withOpacity(0.1);
              }
              if (states.contains(fluent.ButtonStates.hovered)) {
                return color.withOpacity(0.05);
              }
              return Colors.transparent;
            }),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 14,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 10,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryRow(BuildContext context, String categoryTitle, List<Widget> cards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          categoryTitle,
          style: fluent.FluentTheme.of(context).typography.subtitle?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey[300],
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: cards.map((card) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: card,
            )).toList(),
          ),
        ),
      ],
    );
  }

  void _runSingleScript(BuildContext context, String scriptName, String displayName) async {
    // Show confirmation dialog
    final result = await fluent.showDialog<bool>(
      context: context,
      builder: (context) => fluent.ContentDialog(
        title: Text('Install $displayName'),
        content: Text(
          'This will install $displayName on your system.\n\n'
          'The installation requires administrator privileges and may take a few minutes.\n\n'
          'Do you want to continue?',
        ),
        actions: [
          fluent.Button(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          fluent.FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Install'),
          ),
        ],
      ),
    );

    if (result == true) {
      _executeSingleScript(context, scriptName, displayName);
    }
  }

  void _executeSingleScript(BuildContext context, String scriptName, String displayName) async {
    // Show progress dialog
    fluent.showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => fluent.ContentDialog(
        title: Text('Installing $displayName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const fluent.ProgressRing(),
            const SizedBox(height: 16),
            Text('Installing $displayName...'),
            const SizedBox(height: 8),
            Text(
              'This may take several minutes. Please wait.',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );

    try {
      await _runSingleInstaller(scriptName);

      // Close progress dialog and show success
      if (context.mounted) {
        Navigator.of(context).pop();
        fluent.displayInfoBar(
          context,
          builder: (context, close) => fluent.InfoBar(
            title: const Text('Installation Complete'),
            content: Text('$displayName has been installed successfully.'),
            severity: fluent.InfoBarSeverity.success,
            onClose: close,
          ),
        );
      }
    } catch (e) {
      // Close progress dialog and show error
      if (context.mounted) {
        Navigator.of(context).pop();
        fluent.displayInfoBar(
          context,
          builder: (context, close) => fluent.InfoBar(
            title: const Text('Installation Error'),
            content: Text('An error occurred during $displayName installation: $e'),
            severity: fluent.InfoBarSeverity.error,
            onClose: close,
          ),
        );
      }
    }
  }

  void _runInstallers(BuildContext context) async {
    // Show confirmation dialog
    final result = await fluent.showDialog<bool>(
      context: context,
      builder: (context) => fluent.ContentDialog(
        title: const Text('Run All Installers'),
        content: const Text(
          'This will execute all installer scripts in sequence:\n\n'
          '• Install Chocolatey\n'
          '• Install Scoop\n'
          '• Install WinGet\n'
          '• Install essential software packages\n\n'
          'This process may take several minutes and requires administrator privileges.\n\n'
          'Do you want to continue?',
        ),
        actions: [
          fluent.Button(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          fluent.FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Run Installers'),
          ),
        ],
      ),
    );

    if (result == true) {
      _executeInstallerSequence(context);
    }
  }

  void _executeInstallerSequence(BuildContext context) async {
    final installerScripts = [
      'install-chocolatey.ps1',
      'install-scoop.ps1', 
      'install-winget.ps1',
      'install-essential-software.ps1',
    ];

    // Show progress dialog
    fluent.showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => fluent.ContentDialog(
        title: const Text('Running Installers'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const fluent.ProgressRing(),
            const SizedBox(height: 16),
            const Text('Executing installer scripts...'),
            const SizedBox(height: 8),
            Text(
              'This may take several minutes. Please wait.',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );

    try {
      for (final script in installerScripts) {
        await _runSingleInstaller(script);
        await Future.delayed(const Duration(seconds: 2)); // Brief pause between scripts
      }

      // Close progress dialog and show success
      if (context.mounted) {
        Navigator.of(context).pop();
        fluent.displayInfoBar(
          context,
          builder: (context, close) => fluent.InfoBar(
            title: const Text('Installation Complete'),
            content: const Text('All installer scripts have been executed successfully.'),
            severity: fluent.InfoBarSeverity.success,
            onClose: close,
          ),
        );
      }
    } catch (e) {
      // Close progress dialog and show error
      if (context.mounted) {
        Navigator.of(context).pop();
        fluent.displayInfoBar(
          context,
          builder: (context, close) => fluent.InfoBar(
            title: const Text('Installation Error'),
            content: Text('An error occurred during installation: $e'),
            severity: fluent.InfoBarSeverity.error,
            onClose: close,
          ),
        );
      }
    }
  }

  Future<void> _runSingleInstaller(String scriptName) async {
    final scriptDirectory = _getScriptDirectory(scriptName);
    final scriptPath = path.join(scriptDirectory, scriptName);
    
    final file = File(scriptPath);
    if (!await file.exists()) {
      throw Exception('Script file $scriptName not found');
    }

    final process = await Process.start(
      'powershell.exe',
      [
        '-ExecutionPolicy',
        'Bypass',
        '-Command',
        'Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File \\"$scriptPath\\"" -Verb RunAs -Wait'
      ],
      runInShell: true,
    );

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw Exception('Script $scriptName failed with exit code $exitCode');
    }
  }

  String _getScriptDirectory(String fileName) {
    // Use the same logic as other script methods
    if (fileName == 'install.ps1' || fileName == 'test.ps1') {
      return 'windows_scripts';
    }

    final categoryMap = {
      'install-chocolatey.ps1': 'package_managers',
      'install-scoop.ps1': 'package_managers', 
      'install-winget.ps1': 'package_managers',
      'install-winget-fixed.ps1': 'package_managers',
      'install-winget-simple.ps1': 'package_managers',
      'install-chocolatey-enhanced.ps1': 'package_managers',
      'install-scoop-fixed.ps1': 'package_managers',
      'install-python-enhanced.ps1': 'development',
      'install-nodejs-lts.ps1': 'development',
      'install-git.ps1': 'development',
      'install-wsl2-ubuntu.ps1': 'development',
      'install-vscode-enhanced.ps1': 'apps',
      'install-browsers-enhanced.ps1': 'apps',
      'install-docker.ps1': 'containers',
      'install-ai-development-stack.ps1': 'ai-development',
      'install-web-development-stack.ps1': 'web-development',
      'install-cloud-development-stack.ps1': 'cloud',
    };

    final category = categoryMap[fileName] ?? 'script';
    return path.join('windows_scripts', 'script', category);
  }

  // Action button builder
  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onPressed) {
    return fluent.Button(
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 12,
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 8,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Download scripts functionality
  void _downloadScripts(BuildContext context, String category) async {
    try {
      final scripts = _getCategoryScripts(category);
      if (scripts.isEmpty) {
        _showInfoBar(context, 'No Scripts', 'No scripts found for this category.', fluent.InfoBarSeverity.warning);
        return;
      }

      // Show download options dialog
      final result = await fluent.showDialog<String>(
        context: context,
        builder: (context) => fluent.ContentDialog(
          title: Text('Download $category Scripts'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Choose download location for ${scripts.length} script(s):'),
              const SizedBox(height: 16),
              ...scripts.map((script) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $script', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              )),
            ],
          ),
          actions: [
            fluent.Button(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            fluent.Button(
              child: const Text('Downloads Folder'),
              onPressed: () => Navigator.of(context).pop('downloads'),
            ),
            fluent.Button(
              child: const Text('Desktop'),
              onPressed: () => Navigator.of(context).pop('desktop'),
            ),
          ],
        ),
      );

      if (result != null) {
      await _downloadScriptsToLocation(context, category, result);
    }
    } catch (e) {
      _showInfoBar(context, 'Download Error', 'Failed to download scripts: $e', fluent.InfoBarSeverity.error);
    }
  }

  // Run category scripts functionality
  void _runCategoryScripts(BuildContext context, String category) async {
    try {
      final scripts = _getCategoryScripts(category);
      if (scripts.isEmpty) {
        _showInfoBar(context, 'No Scripts', 'No scripts found for this category.', fluent.InfoBarSeverity.warning);
        return;
      }

      // Show confirmation dialog
      final result = await fluent.showDialog<bool>(
        context: context,
        builder: (context) => fluent.ContentDialog(
          title: Text('Run $category Scripts'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('This will run ${scripts.length} script(s) with administrator privileges:'),
              const SizedBox(height: 12),
              ...scripts.map((script) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $script', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              )),
              const SizedBox(height: 12),
              const Text('Do you want to continue?', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            fluent.Button(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            fluent.FilledButton(
              child: const Text('Run Scripts'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      );

      if (result == true) {
          await _executeScriptCategory(context, category, scripts);
        }
    } catch (e) {
      _showInfoBar(context, 'Execution Error', 'Failed to run scripts: $e', fluent.InfoBarSeverity.error);
    }
  }

  // Copy script commands functionality
  void _copyScriptCommands(BuildContext context, String category) async {
    try {
      final scripts = _getCategoryScripts(category);
      if (scripts.isEmpty) {
        _showInfoBar(context, 'No Scripts', 'No scripts found for this category.', fluent.InfoBarSeverity.warning);
        return;
      }

      final commands = scripts.map((script) {
        final scriptPath = path.join(_getScriptDirectory(script), script);
        return 'powershell.exe -ExecutionPolicy Bypass -File "$scriptPath"';
      }).join('\n');

      await Clipboard.setData(ClipboardData(text: commands));
      _showInfoBar(context, 'Copied', 'PowerShell commands copied to clipboard!', fluent.InfoBarSeverity.success);
    } catch (e) {
      _showInfoBar(context, 'Copy Error', 'Failed to copy commands: $e', fluent.InfoBarSeverity.error);
    }
  }

  // Helper methods
  List<String> _getCategoryScripts(String category) {
    switch (category) {
      case 'Package Managers':
        return ['install-chocolatey-enhanced.ps1', 'install-scoop-fixed.ps1', 'install-winget-fixed.ps1'];
      case 'Software Installation':
        return ['install-vscode-enhanced.ps1', 'install-browsers-enhanced.ps1', 'install-docker.ps1'];
      case 'System Settings':
        return ['install-essential-dev-tools.ps1'];
      case 'System Status':
        return ['comprehensive-test.ps1', 'quick-test.ps1'];
      default:
        return [];
    }
  }

  Future<void> _downloadScriptsToLocation(BuildContext context, String category, String location) async {
    final scripts = _getCategoryScripts(category);
    final directory = location == 'downloads' 
        ? path.join(Platform.environment['USERPROFILE']!, 'Downloads', 'SetupX_Scripts')
        : path.join(Platform.environment['USERPROFILE']!, 'Desktop', 'SetupX_Scripts');

    final targetDir = Directory(directory);
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    int successCount = 0;
    for (final script in scripts) {
      try {
        final sourcePath = path.join(_getScriptDirectory(script), script);
        final sourceFile = File(sourcePath);
        
        if (await sourceFile.exists()) {
          final targetPath = path.join(directory, script);
          await sourceFile.copy(targetPath);
          successCount++;
        }
      } catch (e) {
        // Continue with other scripts
      }
    }

    _showInfoBar(
      context,
      'Download Complete', 
      'Downloaded $successCount/${scripts.length} scripts to ${location == 'downloads' ? 'Downloads' : 'Desktop'}',
      successCount == scripts.length ? fluent.InfoBarSeverity.success : fluent.InfoBarSeverity.warning
    );
  }

  Future<void> _executeScriptCategory(BuildContext context, String category, List<String> scripts) async {
    // Show progress dialog
    fluent.showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => fluent.ContentDialog(
        title: Text('Running $category Scripts'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            fluent.ProgressRing(),
            SizedBox(height: 16),
            Text('Executing scripts with administrator privileges...'),
          ],
        ),
      ),
    );

    try {
      for (final script in scripts) {
        await _runSingleInstaller(script);
      }

      // Close progress dialog and show success
      if (context.mounted) {
        Navigator.of(context).pop();
        _showInfoBar(context, 'Success', '$category scripts executed successfully!', fluent.InfoBarSeverity.success);
      }
    } catch (e) {
      // Close progress dialog and show error
      if (context.mounted) {
        Navigator.of(context).pop();
        _showInfoBar(context, 'Execution Error', 'Failed to execute scripts: $e', fluent.InfoBarSeverity.error);
      }
    }
  }

  void _showInfoBar(BuildContext context, String title, String message, fluent.InfoBarSeverity severity) {
    if (context.mounted) {
      fluent.displayInfoBar(
        context,
        builder: (context, close) => fluent.InfoBar(
          title: Text(title),
          content: Text(message),
          severity: severity,
          onClose: close,
        ),
      );
    }
  }

   void _installAllPackageManagers(BuildContext context) async {
     // Show confirmation dialog
     final result = await fluent.showDialog<bool>(
       context: context,
       builder: (context) => fluent.ContentDialog(
         title: const Text('Install All Package Managers'),
         content: const Text(
           'This will install all package managers in sequence:\n\n'
           '• Chocolatey Enhanced\n'
           '• Scoop Fixed\n'
           '• WinGet Fixed\n\n'
           'This process may take several minutes and requires administrator privileges.\n\n'
           'Do you want to continue?',
         ),
         actions: [
           fluent.Button(
             onPressed: () => Navigator.of(context).pop(false),
             child: const Text('Cancel'),
           ),
           fluent.FilledButton(
             onPressed: () => Navigator.of(context).pop(true),
             child: const Text('Install All'),
           ),
         ],
       ),
     );

     if (result == true) {
       _executePackageManagerInstallation(context);
     }
   }

   void _executePackageManagerInstallation(BuildContext context) async {
     final packageManagerScripts = [
       'install-chocolatey-enhanced.ps1',
       'install-scoop-fixed.ps1',
       'install-winget-fixed.ps1',
     ];

     // Show progress dialog
     fluent.showDialog(
       context: context,
       barrierDismissible: false,
       builder: (context) => fluent.ContentDialog(
         title: const Text('Installing Package Managers'),
         content: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             const fluent.ProgressRing(),
             const SizedBox(height: 16),
             const Text('Installing package managers...'),
             const SizedBox(height: 8),
             Text(
               'This may take several minutes. Please wait.',
               style: TextStyle(color: Colors.grey[400]),
             ),
           ],
         ),
       ),
     );

     try {
       for (final script in packageManagerScripts) {
         await _runSingleInstaller(script);
         await Future.delayed(const Duration(seconds: 2)); // Brief pause between scripts
       }

       // Close progress dialog and show success
       if (context.mounted) {
         Navigator.of(context).pop();
         fluent.displayInfoBar(
           context,
           builder: (context, close) => fluent.InfoBar(
             title: const Text('Installation Complete'),
             content: const Text('All package managers have been installed successfully.'),
             severity: fluent.InfoBarSeverity.success,
             onClose: close,
           ),
         );
       }
     } catch (e) {
       // Close progress dialog and show error
       if (context.mounted) {
         Navigator.of(context).pop();
         fluent.displayInfoBar(
           context,
           builder: (context, close) => fluent.InfoBar(
             title: const Text('Installation Error'),
             content: Text('An error occurred during package manager installation: $e'),
             severity: fluent.InfoBarSeverity.error,
             onClose: close,
           ),
         );
       }
     }
   }



   void _runCoreScript(BuildContext context, String scriptName, String displayName) async {
     // Show confirmation dialog
     final result = await fluent.showDialog<bool>(
       context: context,
       builder: (context) => fluent.ContentDialog(
         title: Text('Install $displayName'),
         content: Text(
           'This will install $displayName on your system.\n\n'
           'The installation requires administrator privileges and may take a few minutes.\n\n'
           'Do you want to continue?',
         ),
         actions: [
           fluent.Button(
             onPressed: () => Navigator.of(context).pop(false),
             child: const Text('Cancel'),
           ),
           fluent.FilledButton(
             onPressed: () => Navigator.of(context).pop(true),
             child: const Text('Install'),
           ),
         ],
       ),
     );

     if (result == true) {
       _executeCoreScript(context, scriptName, displayName);
     }
   }

   void _executeCoreScript(BuildContext context, String scriptName, String displayName) async {
     // Show progress dialog
     fluent.showDialog(
       context: context,
       barrierDismissible: false,
       builder: (context) => fluent.ContentDialog(
         title: Text('Installing $displayName'),
         content: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             const fluent.ProgressRing(),
             const SizedBox(height: 16),
             Text('Installing $displayName...'),
             const SizedBox(height: 8),
             Text(
               'This may take several minutes. Please wait.',
               style: TextStyle(color: Colors.grey[400]),
             ),
           ],
         ),
       ),
     );

     try {
       await _runCoreInstaller(scriptName);

       // Close progress dialog and show success
       if (context.mounted) {
         Navigator.of(context).pop();
         fluent.displayInfoBar(
           context,
           builder: (context, close) => fluent.InfoBar(
             title: const Text('Installation Complete'),
             content: Text('$displayName has been installed successfully.'),
             severity: fluent.InfoBarSeverity.success,
             onClose: close,
           ),
         );
       }
     } catch (e) {
       // Close progress dialog and show error
       if (context.mounted) {
         Navigator.of(context).pop();
         fluent.displayInfoBar(
           context,
           builder: (context, close) => fluent.InfoBar(
             title: const Text('Installation Error'),
             content: Text('An error occurred during $displayName installation: $e'),
             severity: fluent.InfoBarSeverity.error,
             onClose: close,
           ),
         );
       }
     }
   }

   Future<void> _runCoreInstaller(String scriptName) async {
     final scriptPath = path.join('windows_scripts', 'core', scriptName);
     
     final file = File(scriptPath);
     if (!await file.exists()) {
       throw Exception('Core script file $scriptName not found');
     }

     final process = await Process.start(
       'powershell.exe',
       [
         '-ExecutionPolicy',
         'Bypass',
         '-Command',
         'Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File \\"$scriptPath\\"" -Verb RunAs -Wait'
       ],
       runInShell: true,
     );

     final exitCode = await process.exitCode;
     if (exitCode != 0) {
       throw Exception('Core script $scriptName failed with exit code $exitCode');
     }
   }

   // Helper method to build section headers
   Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
     return Row(
       children: [
         Container(
           padding: const EdgeInsets.all(8),
           decoration: BoxDecoration(
             color: fluent.FluentTheme.of(context).accentColor.withOpacity(0.1),
             borderRadius: BorderRadius.circular(8),
           ),
           child: Icon(
             icon,
             size: 20,
             color: fluent.FluentTheme.of(context).accentColor,
           ),
         ),
         const SizedBox(width: 12),
         Text(
           title,
           style: fluent.FluentTheme.of(context).typography.title?.copyWith(
             fontWeight: FontWeight.w600,
           ),
         ),
       ],
     ).animate().fadeIn().slideX(begin: -0.2);
   }

   // Method for Install All in One CMD
   void _installAllInOne(BuildContext context) async {
     final result = await fluent.showDialog<bool>(
       context: context,
       builder: (context) => fluent.ContentDialog(
         title: const Text('Install All in One'),
         content: const Text(
           'This will execute a comprehensive installation that includes:\n\n'
           '• All package managers (Chocolatey, Scoop, WinGet)\n'
           '• Essential development tools\n'
           '• Common applications\n'
           '• System configurations\n\n'
           'This process may take 15-30 minutes and requires administrator privileges.\n\n'
           'Do you want to continue?',
         ),
         actions: [
           fluent.Button(
             onPressed: () => Navigator.of(context).pop(false),
             child: const Text('Cancel'),
           ),
           fluent.FilledButton(
             onPressed: () => Navigator.of(context).pop(true),
             child: const Text('Install All'),
           ),
         ],
       ),
     );

     if (result == true) {
       _executeAllInOneInstallation(context);
     }
   }

   void _executeAllInOneInstallation(BuildContext context) async {
     // Show progress dialog
     fluent.showDialog(
       context: context,
       barrierDismissible: false,
       builder: (context) => fluent.ContentDialog(
         title: const Text('Installing All Components'),
         content: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             const fluent.ProgressRing(),
             const SizedBox(height: 16),
             const Text('Installing all components...'),
             const SizedBox(height: 8),
             Text(
               'This may take 15-30 minutes. Please wait.',
               style: TextStyle(color: Colors.grey[400]),
             ),
           ],
         ),
       ),
     );

     try {
       // Execute comprehensive installation script
       await _runCoreInstaller('install-all-in-one.ps1');

       // Close progress dialog and show success
       if (context.mounted) {
         Navigator.of(context).pop();
         fluent.displayInfoBar(
           context,
           builder: (context, close) => fluent.InfoBar(
             title: const Text('Installation Complete'),
             content: const Text('All components have been installed successfully.'),
             severity: fluent.InfoBarSeverity.success,
             onClose: close,
           ),
         );
       }
     } catch (e) {
       // Close progress dialog and show error
       if (context.mounted) {
         Navigator.of(context).pop();
         fluent.displayInfoBar(
           context,
           builder: (context, close) => fluent.InfoBar(
             title: const Text('Installation Error'),
             content: Text('An error occurred during installation: $e'),
             severity: fluent.InfoBarSeverity.error,
             onClose: close,
           ),
         );
       }
     }
   }

   // Method for Install CLI
   void _installCLI(BuildContext context) async {
     final result = await fluent.showDialog<bool>(
       context: context,
       builder: (context) => fluent.ContentDialog(
         title: const Text('Install CLI Tools'),
         content: const Text(
           'This will install essential command line tools:\n\n'
           '• Git CLI\n'
           '• GitHub CLI\n'
           '• Node.js & npm\n'
           '• Python & pip\n'
           '• PowerShell Core\n'
           '• Windows Terminal\n\n'
           'This process may take 10-15 minutes and requires administrator privileges.\n\n'
           'Do you want to continue?',
         ),
         actions: [
           fluent.Button(
             onPressed: () => Navigator.of(context).pop(false),
             child: const Text('Cancel'),
           ),
           fluent.FilledButton(
             onPressed: () => Navigator.of(context).pop(true),
             child: const Text('Install CLI'),
           ),
         ],
       ),
     );

     if (result == true) {
       _executeCLIInstallation(context);
     }
   }

   void _executeCLIInstallation(BuildContext context) async {
     // Show progress dialog
     fluent.showDialog(
       context: context,
       barrierDismissible: false,
       builder: (context) => fluent.ContentDialog(
         title: const Text('Installing CLI Tools'),
         content: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             const fluent.ProgressRing(),
             const SizedBox(height: 16),
             const Text('Installing CLI tools...'),
             const SizedBox(height: 8),
             Text(
               'This may take 10-15 minutes. Please wait.',
               style: TextStyle(color: Colors.grey[400]),
             ),
           ],
         ),
       ),
     );

     try {
       // Execute CLI installation script
       await _runCoreInstaller('install-cli-tools.ps1');

       // Close progress dialog and show success
       if (context.mounted) {
         Navigator.of(context).pop();
         fluent.displayInfoBar(
           context,
           builder: (context, close) => fluent.InfoBar(
             title: const Text('CLI Installation Complete'),
             content: const Text('All CLI tools have been installed successfully.'),
             severity: fluent.InfoBarSeverity.success,
             onClose: close,
           ),
         );
       }
     } catch (e) {
       // Close progress dialog and show error
       if (context.mounted) {
         Navigator.of(context).pop();
         fluent.displayInfoBar(
           context,
           builder: (context, close) => fluent.InfoBar(
             title: const Text('CLI Installation Error'),
             content: Text('An error occurred during CLI installation: $e'),
             severity: fluent.InfoBarSeverity.error,
             onClose: close,
           ),
         );
       }
     }
   }
 }