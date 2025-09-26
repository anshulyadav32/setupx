# SetupX - Modular Windows Development Setup

A clean, modular PowerShell tool for setting up Windows development environments.

## 🚀 Quick Start

### One-Command Installation
```powershell
Invoke-RestMethod -Uri https://raw.githubusercontent.com/anshulyadav32/setupx/master/install.ps1 | Invoke-Expression
```

### Force Installation (No Prompts)
```powershell
iwr https://raw.githubusercontent.com/anshulyadav32/setupx/master/install.ps1 | iex -Force
```

### Custom Installation Path
```powershell
iwr https://raw.githubusercontent.com/anshulyadav32/setupx/master/install.ps1 | iex -InstallPath "C:\MyTools\SetupX"
```

## 📋 Features

### Module Categories
- **🌐 Web Development**: Frontend frameworks, web servers, and tools
- **🤖 AI Tools & Development**: AI frameworks, models, and development tools  
- **📱 Mobile Development**: Mobile app development frameworks and tools
- **🎮 Game Development**: Game engines and development tools
- **⚙️ DevOps & Automation**: CI/CD tools, automation, and deployment
- **🔧 System Tools**: System utilities, performance tools, and diagnostics
- **🛠️ Common Tools**: Essential desktop applications and utilities
- **📊 Data & Analytics**: Data processing, databases, and analytics tools

### Available Components
- **Chrome, Brave, Firefox** - Popular web browsers
- **Windows Terminal** - Modern terminal application
- **Node.js, Python, Git** - Essential development tools
- **Docker, Kubernetes** - Containerization and orchestration
- **Visual Studio Code** - Code editor and extensions
- **And many more...**

## 🎯 Usage

After installation, run SetupX from PowerShell:

```powershell
# Navigate to installation directory (if not in PATH)
cd $env:USERPROFILE\SetupX

# Run SetupX framework
.\setwinx.ps1

# Install specific components
.\setwinx.ps1 -Component chrome
.\setwinx.ps1 -Component nodejs

# Install entire categories
.\setwinx.ps1 -Target web-development
.\setwinx.ps1 -Target common-tools

# Get help and available options
.\setwinx.ps1 -Help
```

## 📁 Project Structure

```
SetupX/
├── setwinx.ps1              # Main framework script
├── core/                    # Core component modules
│   ├── common-tools/        # Essential desktop applications
│   ├── web-development/     # Web development tools
│   ├── ai-tools-development/# AI and ML tools
│   └── ...                  # Other categories
├── modules/                 # Additional modules
├── scripts/                 # Utility scripts
├── super-modules/           # Advanced module collections
├── config/                  # Configuration files
└── data/                    # Data and templates
```

## 🛡️ Requirements

- **Windows 10/11**
- **PowerShell 5.0+**
- **Internet Connection**
- **Administrator Rights** (for some installations)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

- 🐛 **Issues**: [GitHub Issues](https://github.com/anshulyadav32/setupx/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/anshulyadav32/setupx/discussions)
- 📧 **Contact**: Create an issue for support

## 🎉 Acknowledgments

Special thanks to all contributors and the open-source community for making this project possible.
