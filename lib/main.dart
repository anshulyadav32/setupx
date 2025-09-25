import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

// Import page components
import 'pages/dashboard_page.dart';
import 'pages/all_components_page.dart';
import 'pages/package_managers_page.dart';
import 'pages/scripts_page.dart';
import 'pages/software_installation_page.dart';
import 'pages/system_settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure window
  await windowManager.ensureInitialized();
  
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1400, 900),
    minimumSize: Size(1200, 800),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden, // Hide default title bar for custom implementation
    windowButtonVisibility: false, // We'll create custom window controls
  );
  
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    await windowManager.maximize(); // Start maximized for fullscreen experience
  });

  runApp(const SetupXApp());
}

class SetupXApp extends StatelessWidget {
  const SetupXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return fluent.FluentApp(
      title: 'SetupX',
      theme: fluent.FluentThemeData(
        brightness: Brightness.light,
        accentColor: fluent.Colors.blue,
      ),
      darkTheme: fluent.FluentThemeData(
        brightness: Brightness.dark,
        accentColor: fluent.Colors.blue,
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;
  fluent.PaneDisplayMode paneDisplayMode = fluent.PaneDisplayMode.open;

  final List<fluent.NavigationPaneItem> items = [
    fluent.PaneItem(
      key: const ValueKey('/dashboard'),
      icon: const Icon(fluent.FluentIcons.home),
      title: const Text('Dashboard'),
      body: const DashboardPage(),
    ),
    fluent.PaneItem(
      key: const ValueKey('/all-components'),
      icon: const Icon(fluent.FluentIcons.installation),
      title: const Text('All Components CMD'),
      body: const AllComponentsPage(),
    ),
    fluent.PaneItem(
      key: const ValueKey('/package-managers'),
      icon: const Icon(fluent.FluentIcons.package),
      title: const Text('Package Managers'),
      body: const PackageManagersPage(),
    ),
    fluent.PaneItem(
      key: const ValueKey('/scripts'),
      icon: const Icon(fluent.FluentIcons.code),
      title: const Text('Scripts'),
      body: const ScriptsPage(),
    ),
    fluent.PaneItem(
      key: const ValueKey('/software'),
      icon: const Icon(fluent.FluentIcons.app_icon_default),
      title: const Text('Software Installation'),
      body: const SoftwareInstallationPage(),
    ),
    fluent.PaneItem(
      key: const ValueKey('/settings'),
      icon: const Icon(fluent.FluentIcons.settings),
      title: const Text('System Settings'),
      body: const SystemSettingsPage(),
    ),
  ];

  void _togglePane() {
    setState(() {
      paneDisplayMode = paneDisplayMode == fluent.PaneDisplayMode.open
          ? fluent.PaneDisplayMode.compact
          : fluent.PaneDisplayMode.open;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Custom Title Bar with Window Controls
        Container(
          height: 32,
          decoration: BoxDecoration(
            color: fluent.FluentTheme.of(context).acrylicBackgroundColor,
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // App Icon and Title
              Expanded(
                child: GestureDetector(
                  onPanStart: (details) {
                    windowManager.startDragging();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(
                          fluent.FluentIcons.pc1,
                          size: 16,
                          color: fluent.FluentTheme.of(context).accentColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'SetupX - Windows Development Environment Setup',
                          style: fluent.FluentTheme.of(context).typography.caption?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Window Control Buttons
              Row(
                children: [
                  // Minimize Button
                  _WindowControlButton(
                    icon: fluent.FluentIcons.chrome_minimize,
                    onPressed: () async {
                      await windowManager.minimize();
                    },
                    color: Colors.grey[600],
                  ),
                  // Maximize/Restore Button
                  _WindowControlButton(
                    icon: fluent.FluentIcons.checkbox_composite,
                    onPressed: () async {
                      if (await windowManager.isMaximized()) {
                        await windowManager.unmaximize();
                      } else {
                        await windowManager.maximize();
                      }
                    },
                    color: Colors.grey[600],
                  ),
                  // Close Button
                  _WindowControlButton(
                    icon: fluent.FluentIcons.chrome_close,
                    onPressed: () async {
                      // Show confirmation dialog before exiting
                      final result = await fluent.showDialog<bool>(
                        context: context,
                        builder: (context) => fluent.ContentDialog(
                          title: const Text('Exit Application'),
                          content: const Text('Are you sure you want to exit SetupX?'),
                          actions: [
                            fluent.Button(
                              child: const Text('Cancel'),
                              onPressed: () => Navigator.of(context).pop(false),
                            ),
                            fluent.FilledButton(
                              child: const Text('Exit'),
                              onPressed: () => Navigator.of(context).pop(true),
                            ),
                          ],
                        ),
                      );
                      
                      if (result == true) {
                        await windowManager.close();
                      }
                    },
                    color: Colors.red[600],
                    isCloseButton: true,
                  ),
                ],
              ),
            ],
          ),
        ),
        // Main Content Area
        Expanded(
          child: fluent.NavigationView(
            appBar: fluent.NavigationAppBar(
              automaticallyImplyLeading: false,
              leading: fluent.IconButton(
                icon: Icon(
                  paneDisplayMode == fluent.PaneDisplayMode.open 
                      ? fluent.FluentIcons.global_nav_button 
                      : fluent.FluentIcons.more,
                ),
                onPressed: _togglePane,
              ),
              title: Text(
                'SetupX',
                style: fluent.FluentTheme.of(context).typography.bodyStrong,
              ),
            ),
            pane: fluent.NavigationPane(
              selected: selectedIndex,
              onChanged: (index) => setState(() => selectedIndex = index),
              displayMode: paneDisplayMode,
              items: items,
            ),
          ),
        ),
      ],
    );
  }
}

class _WindowControlButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  final bool isCloseButton;

  const _WindowControlButton({
    required this.icon,
    required this.onPressed,
    this.color,
    this.isCloseButton = false,
  });

  @override
  State<_WindowControlButton> createState() => _WindowControlButtonState();
}

class _WindowControlButtonState extends State<_WindowControlButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 46,
          height: 32,
          decoration: BoxDecoration(
            color: _isHovered 
                ? (widget.isCloseButton ? Colors.red : Colors.grey[200])
                : Colors.transparent,
          ),
          child: Icon(
            widget.icon,
            size: 10,
            color: _isHovered && widget.isCloseButton
                ? Colors.white
                : (widget.color ?? Colors.grey[700]),
          ),
        ),
      ),
    );
  }
}
