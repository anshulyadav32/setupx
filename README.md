# SetWinX - Windows Development Setup CLI

**🚀 A powerful command-line interface for automated Windows development environment setup**

SetWinX is a comprehensive CLI tool that simplifies the installation and management of development tools, package managers, and essential applications on Windows systems.

## 🎯 Features

- **📦 Package Manager Support**: Scoop, Winget, Chocolatey
- **🛠️ Development Tools**: Git, GitHub CLI, VS Code, Docker, Node.js, Python, and more
- **🌐 Web Development**: NVM, XAMPP, NPM, React.js tools
- **📱 Cross-Platform Development**: Android Studio, Flutter
- **🤖 AI Tools**: ChatGPT Desktop, Gemini CLI, VS Code AI extensions, and more
- **🖥️ Common Tools**: Chrome, Brave, Firefox, Windows Terminal
- **🔧 Server Development**: AWS CLI, Azure CLI, Google Cloud CLI, and database tools
- **🐧 WSL Development**: WSL2, Ubuntu, Kali Linux, Docker WSL

## 🚀 Quick Installation

### One-Command Installation
```powershell
# Install SetWinX CLI globally from GitHub
iex (irm "https://raw.githubusercontent.com/anshulyadav32/setupx/master/install.ps1")
```

### Manual Installation
```powershell
# Clone repository
git clone https://github.com/anshulyadav32/setupx.git c:\dev0-1\setupx-cli

# Add to PATH (replace with your installation path)
# Add to PATH
$CLIPath = "c:\dev0-1\setupx-cli\setwinx-cli"
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
$newPath = $currentPath + ";" + $CLIPath
[Environment]::SetEnvironmentVariable("Path", $newPath, "User")
```

## 📋 Usage

### Basic Commands
```powershell
# Show help
setwinx --help

# List all available modules
setwinx --list-modules

# Check status of all components
setwinx --status

# List all components
setwinx --list
```

### Individual Component Management
```powershell
# Install specific components
setwinx git auto                    # Auto-setup Git
setwinx python install             # Install Python
setwinx vscode install --force     # Force install VS Code

# Check component status
setwinx docker status              # Check Docker status
setwinx node test                  # Test Node.js installation

# Using hierarchical IDs
setwinx 2.1 install               # Install Git (Category 2, Component 1)
setwinx 8.1 auto                  # Auto-setup Chrome (Category 8, Component 1)
```

### Bulk Operations
```powershell
# Install all package managers
setwinx --package-managers auto

# Check status of all development tools
setwinx --dev-tools status

# Install all common tools
setwinx --common-tools auto

# Test all AI tools
setwinx --aitools-dev test
```

### 1. Package Managers (Category 1)
- **[1.1] scoop** - Command-line installer for Windows
- **[1.2] winget** - Windows Package Manager
- **[1.3] choco** - Chocolatey package manager

### 2. Development Tools (Category 2)
- **[2.1] git** - Version control system
- **[2.2] gh** - GitHub CLI
- **[2.3] vscode** - Visual Studio Code
- **[2.4] docker** - Containerization platform
- **[2.5] node** - Node.js runtime
- **[2.6] python** - Python programming language
- **[2.7] terminal** - Windows Terminal
- **[2.8] rustc** - Rust compiler

### 3. Web Development (Category 3)
- **[3.1] nvm** - Node Version Manager
- **[3.2] xampp** - Apache + MySQL + PHP + Perl
- **[3.3] npm** - Node Package Manager
- **[3.4] web-python** - Python for web development
- **[3.5] reactjs** - React.js development tools

### 4. Cross-Platform Development (Category 4)
- **[4.1] android-studio** - Android IDE
- **[4.2] flutter** - Flutter SDK

### 5. AI Tools Development (Category 5)
- **[5.1] geminicli** - Google Gemini CLI
- **[5.2] codex-cli** - GitHub Codex CLI
- **[5.3] cloud-cli** - Cloud AI tools
- **[5.4] chatgpt-desktop** - ChatGPT Desktop app
- **[5.5] noi** - Noi AI interface
- **[5.6] vscode-ai** - VS Code AI extensions
- **[5.7] curser-ai** - Cursor AI editor
- **[5.8] trae-ai** - Trae AI tools
- **[5.9] windsurf** - Windsurf AI platform

### 6. Server Setup Development (Category 6)
- **[6.1] docker-server** - Docker for servers
- **[6.2] psql** - PostgreSQL
- **[6.3] mysql** - MySQL database
- **[6.4] mongodb** - MongoDB database
- **[6.5] aws-cli** - Amazon Web Services CLI
- **[6.6] gcloud-cli** - Google Cloud CLI
- **[6.7] az-cli** - Azure CLI
- **[6.8] vercel-cli** - Vercel CLI
- **[6.9] netlify-cli** - Netlify CLI
- **[6.10] railway-cli** - Railway CLI

### 7. WSL Development Environment (Category 7)
- **[7.1] wsl2** - Windows Subsystem for Linux 2
- **[7.2] ubuntu-lts** - Ubuntu LTS distribution
- **[7.3] kali-linux** - Kali Linux distribution
- **[7.4] docker-wsl** - Docker with WSL2 backend

### 8. Common Tools (Category 8)
- **[8.1] chrome** - Google Chrome browser
- **[8.2] brave** - Brave privacy browser
- **[8.3] firefox** - Mozilla Firefox browser
- **[8.4] windows-terminal** - Windows Terminal app

## 🎮 Available Actions

- **`auto`** - Intelligent auto-setup (test → install → verify)
- **`install`** - Install component with intelligent fallbacks
- **`status`** - Get detailed component status
- **`test`** - Test if component is working properly
- **`version`** - Get component version information
- **`path`** - Get component installation paths
- **`update`** - Update component to latest version
- **`reinstall`** - Completely remove and reinstall component

## 🔧 Advanced Features

### Module Groups
Use module groups for bulk operations:
```powershell
setwinx --all test                 # Test all components
setwinx --package-managers auto    # Auto-setup all package managers
setwinx --dev-tools status         # Check all development tools
setwinx --web-dev install          # Install all web development tools
setwinx --cross-platform-dev auto  # Setup cross-platform tools
setwinx --aitools-dev test         # Test all AI tools
setwinx --server-setup-dev auto    # Setup server development tools
setwinx --wsl-dev install          # Install WSL development environment
setwinx --common-tools auto        # Install all common tools
```

### Hierarchical IDs
Access components using category.component format:
```powershell
setwinx 1.1 install     # Install Scoop (Category 1, Component 1)
setwinx 2.3 auto        # Auto-setup VS Code (Category 2, Component 3)
setwinx 8.1 status      # Check Chrome status (Category 8, Component 1)
```

### Options
- **`--force`** - Force action even if component appears working
- **`--verbose`** - Enable verbose output
- **`--module <name>`** - Target specific module for status operations

## 📁 Project Structure

```
setupx/
├── setwinx-cli/             # Main CLI directory
│   ├── setwinx.ps1          # Main CLI script
│   ├── setwinx.bat          # Windows batch wrapper
│   ├── install-setwinx.ps1  # Installation script
│   ├── core/                # Component scripts
│   │   ├── package-managers/
│   │   ├── development-tools/
│   │   ├── web-development/
│   │   ├── cross-platform-development/
│   │   ├── ai-tools-development/
│   │   ├── server-development/
│   │   ├── wsl-development/
│   │   └── common-tools/
│   ├── modules/             # PowerShell modules
│   ├── config/              # Configuration files
│   └── docs/                # Documentation
├── lib/                     # Flutter GUI application
└── README.md               # This file
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make your changes
4. Test thoroughly
5. Commit your changes: `git commit -am 'Add feature'`
6. Push to the branch: `git push origin feature-name`
7. Submit a pull request

## � License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## � Issues & Support

- **GitHub Issues**: [Report bugs or request features](https://github.com/anshulyadav32/setupx/issues)
- **Discussions**: [Community discussions](https://github.com/anshulyadav32/setupx/discussions)

## � Documentation

For detailed documentation, visit the [docs](docs/) directory or check out our [Wiki](https://github.com/anshulyadav32/setupx/wiki).

## 🎉 Acknowledgments

- Thanks to all contributors who help improve SetWinX
- Inspired by package managers like Scoop, Chocolatey, and Winget
- Built with PowerShell for native Windows integration

---

**Made with ❤️ by [anshulyadav32](https://github.com/anshulyadav32)**

⭐ **Star this repository** if SetWinX helps you set up your development environment!
