<h3 align="center"><img alt="logo" src="https://github.com/Sriram-PR/pwsh-neofetch/blob/main/assets/pwsh-neofetch.png" width="500px"></h3>

<p align="center">
<a href="./LICENSE.md"><img src="https://img.shields.io/github/license/Sriram-PR/pwsh-neofetch.svg?color=blue"></a>
<a href="https://github.com/Sriram-PR/pwsh-neofetch/releases"><img src="https://img.shields.io/github/v/release/Sriram-PR/pwsh-neofetch.svg?color=blue"></a>
<a><img src="https://img.shields.io/powershellgallery/dt/pwsh-neofetch.svg?color=blue"></a>
<a><img src="https://img.shields.io/github/languages/top/Sriram-PR/pwsh-neofetch.svg?color=blue
"></a>
<a><img src="https://img.shields.io/powershellgallery/p/pwsh-neofetch?color=blue"></a>
</p>
<br />

A feature-rich PowerShell implementation of the popular Neofetch system information tool for Windows. This script/module displays system information with customizable ASCII art in your terminal, similar to the original Neofetch but designed specifically for Windows environments.

## Features

- 📊 Comprehensive system information display
- 🎨 Customizable ASCII art support
- ⚡ Multi-threaded data collection for improved performance
- 🔄 Smart caching system to reduce load times
- 📱 Terminal profile detection for accurate font information
- 📉 Built-in system benchmarking utility
- 🧩 Minimal view option for essential information only
- 🛠️ Configuration wizard for easy setup

## Installation

### From PowerShell Gallery (Recommended)

```powershell
Install-Module -Name pwsh-neofetch
```

### From GitHub

```powershell
# Clone the repository
git clone https://github.com/Sriram-PR/pwsh-neofetch.git

# Run the installer script
.\direct-installer.ps1

# To uninstall, run
.\direct-uninstaller.ps1
```

## Troubleshooting Installation

If the `neofetch` command isn't recognized after installation (this issue may occur only when installing from the PowerShell Gallery), try these steps:

1. Make sure the module is loaded:
   ```powershell
   Import-Module pwsh-neofetch
   ```

2. If the command still doesn't work, this may be due to a module path issue. You can fix it by:
   ```powershell
   # Clone the repository
   git clone https://github.com/Sriram-PR/pwsh-neofetch.git
   
   # Navigate to the directory
   cd pwsh-neofetch
   
   # Run the module relocator script
   .\module-relocator.ps1
   ```

3. Close and reopen your PowerShell session

4. Try running the command again:
   ```powershell
   neofetch
   ```

This solves a common issue where the module is installed but not properly located in your PowerShell module path.

## Quick Start

After installation, simply run:

```powershell
neofetch
```

<p align="center"><img alt="neofetch-basic" src="https://github.com/Sriram-PR/pwsh-neofetch/blob/main/assets/neofetch-basic.png" width="600px"></p>

On a fresh install, this command will automatically launch the configuration wizard to help you set up your preferences.

## Configuration Options

All configuration is stored in your user profile directory:

- `.neofetch_ascii` - Custom ASCII art
- `.neofetch_cache_expiration` - Cache expiration time in seconds
- `.neofetch_threads` - Maximum thread count
- `.neofetch_profile_name` - Windows Terminal profile name

## Usage

```powershell
neofetch [options]
```

### Available Options

| Option | Description |
|--------|-------------|
| `-init` | Run the configuration wizard |
| `-Force` | Force reconfiguration even if config files exist |
| `-asciiart <path>` | Path to a text file containing custom ASCII art |
| `-defaultart` | Reset to default Windows ASCII art |
| `-changes` | Display information about current configuration |
| `-maxThreads <n>` | Limit maximum threads used (default: 4 or CPU core count) |
| `-defaultthreads` | Reset to default thread count |
| `-profileName <name>` | Set Windows Terminal profile name for font detection |
| `-defaultprofile` | Reset terminal profile to default |
| `-cacheExpiration <n>` | Set cache expiration period in seconds (default: 1800) |
| `-defaultcache` | Reset cache expiration to default |
| `-nocache` | Disable caching and force fresh data collection |
| `-minimal` | Display minimal view with essential system info only |
| `-benchmark` | Run a system benchmark and display results |
| `-reload` | Reset all configuration files and caches |
| `-help` | Display help message |

## Examples

Basic usage:
```powershell
neofetch
```

Force reconfiguration:
```powershell
neofetch -init -Force
```

Using custom ASCII art:
```powershell
neofetch -asciiart "C:\path\to\ascii\art.txt"
```

Display minimal information:
```powershell
neofetch -minimal
```

Run system benchmark:
```powershell
neofetch -benchmark
```

View current configuration:
```powershell
neofetch -changes
```

## Custom ASCII Art

You can create your own ASCII art text files to use with the script.

Example of a simple ASCII art file:
```
⣾⡻⡃⣿⣿⠸⢣⣾⢸⡸⣿⣿⢹⣿⣿⣿⠘⣿⣿⣿⢈⣿⢸⣿⣷⣭⣿⣿⡇⣿
⠃⣾⠃⣿⡏⢇⣮⣟⠸⡇⣿⣿⢸⠿⣿⣿⣤⢿⣿⣿⢸⢹⡆⡟⣸⣿⡟⣿⡇⣿
⢰⣿⠄⣿⡇⡜⠛⠛⠿⢤⢹⣿⣼⢀⣿⡏⠿⠄⣿⠟⣰⣦⢧⢱⣿⣿⠳⣿⠃⣿
⡜⣿⡆⣿⡇⣿⣿⣷⣶⣾⣦⣄⣧⣸⡸⢧⣿⡨⠩⠦⠿⠿⡼⢸⣿⡿⣄⢈⡆⢸
⠹⣿⡇⣿⡇⣿⣿⣿⣿⣿⣿⣿⢻⣿⣿⣿⣶⣶⣶⣶⣶⣶⡆⣿⣿⢇⡟⣼⡧⣫
⠄⢹⡇⣿⡇⣿⣿⣿⣿⣿⣿⣧⣤⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⣿⣿⢘⣾⣿⢷⠋
⠄⠈⡇⣿⡇⣹⣿⣿⣿⣿⣿⣧⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢣⣿⡟⣾⣿⣿⠄⠄
⠄⠄⢠⣿⡇⣷⠘⢿⣿⣧⡲⣾⣭⣭⣿⣒⠊⣹⣿⣿⡿⠁⣸⣿⡇⣿⣿⡏⡇⠄
⠄⠄⠄⣿⡇⣿⠄⠄⠙⢿⣿⣷⣶⣶⣶⣾⣿⣿⠟⠋⠄⠄⣿⣿⢳⣿⣿⢹⡇⠄
⠄⠄⠄⠘⣿⢸⢰⣆⠄⠄⠙⠻⣿⡿⠟⠛⠉⠄⠄⠄⠄⠄⣿⡟⣼⣿⢏⣿⢧⣷
```

<h3 align="center"><img alt="logo" src="https://github.com/Sriram-PR/pwsh-neofetch/blob/main/assets/neofetch-zerotwo.png" width="600px"></h3>

## System Benchmark

The built-in benchmark evaluates:
- CPU performance (prime number calculation)
- Memory performance (array operations)
- Disk I/O performance (read/write speeds)

Results include individual scores and a composite rating.

## Requirements

- Windows 7/Server 2008 R2 or later
- PowerShell 5.1 or later

## Troubleshooting

### Cache Issues
If you experience stale data, try:
```powershell
neofetch -nocache
```

### Performance Problems
Adjust thread count to optimize for your system:
```powershell
neofetch -maxThreads 2  # For less powerful systems
neofetch -maxThreads 8  # For more powerful systems
```

### Reset Configuration
To start fresh:
```powershell
neofetch -reload
```

## Roadmap / Planned Features

These are the features I'm planning to implement in future releases:

- [x] Multi-threaded system information collection
- [x] Custom ASCII art support
- [x] Caching system for improved performance
- [x] System benchmarking utility
- [ ] Color theme customization
- [ ] User-configurable information display order
- [ ] Export system information to file (JSON, CSV, TXT)
- [ ] Comparison mode to highlight system changes over time
- [ ] Remote system information collection
- [ ] Gallery of pre-made ASCII art templates
- [ ] Plugin system for custom information modules
- [ ] Integration with hardware monitoring tools
- [ ] Localization support for multiple languages

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the [MIT License](https://github.com/Sriram-PR/pwsh-neofetch/blob/main/LICENSE).

## Acknowledgments

- Inspired by the original [Neofetch](https://github.com/dylanaraps/neofetch) for Linux