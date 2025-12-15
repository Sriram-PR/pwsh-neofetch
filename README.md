<h3 align="center"><img alt="logo" src="https://github.com/Sriram-PR/pwsh-neofetch/blob/main/assets/pwsh-neofetch.png" width="500px"></h3>

<p align="center">
<a href="./LICENSE.md"><img src="https://img.shields.io/github/license/Sriram-PR/pwsh-neofetch.svg?color=blue"></a>
<a href="https://github.com/Sriram-PR/pwsh-neofetch/releases"><img src="https://img.shields.io/github/v/release/Sriram-PR/pwsh-neofetch.svg?color=blue"></a>
<a><img src="https://img.shields.io/powershellgallery/dt/pwsh-neofetch.svg?color=blue"></a>
<a><img src="https://img.shields.io/github/languages/top/Sriram-PR/pwsh-neofetch?color=blue"></a>
<a><img src="https://img.shields.io/powershellgallery/p/pwsh-neofetch?color=blue"></a>
</p>
<br />

A feature-rich PowerShell implementation of the popular Neofetch system information tool for Windows. This module displays system information with customizable ASCII art in your terminal, similar to the original Neofetch but designed specifically for Windows environments.

## Features

- 📊 Comprehensive system information display
- 🎨 Customizable ASCII art support
- ⚡ Multi-threaded data collection for improved performance
- 🔄 Smart caching system to reduce load times
- 📱 Terminal profile detection for accurate font information
- 📈 Live system monitoring with real-time graphs
- 🧩 Minimal view option for essential information only
- 🛠️ Configuration wizard for easy setup

## Installation

### From PowerShell Gallery (Recommended)

The easiest way to install pwsh-neofetch is from the PowerShell Gallery:

```powershell
Install-Module -Name pwsh-neofetch
```

To update to the latest version:

```powershell
Update-Module -Name pwsh-neofetch
```

### Alternative: Install from GitHub

If you cannot access PowerShell Gallery (corporate firewall, air-gapped systems) or want to test a development version:

```powershell
# Clone the repository
git clone https://github.com/Sriram-PR/pwsh-neofetch.git
cd pwsh-neofetch

# Run the installer
.\direct-installer.ps1
```

To uninstall:

```powershell
.\direct-uninstaller.ps1
```

## Troubleshooting Installation

If the `neofetch` command isn't recognized after installation, try these steps:

1. **Restart your PowerShell session** - The module may not be loaded in existing sessions.

2. **Manually import the module:**

   ```powershell
   Import-Module pwsh-neofetch
   ```

3. **If using OneDrive folder sync** - OneDrive's "Known Folder Move" feature can cause path issues on some systems. Run the module relocator:

   ```powershell
   # From the cloned repository
   .\module_relocator.ps1
   ```

4. **Verify installation:**

   ```powershell
   Get-Module -ListAvailable pwsh-neofetch
   ```

## Quick Start

After installation, simply run:

```powershell
neofetch
```

<p align="center"><img alt="neofetch-basic" src="https://github.com/Sriram-PR/pwsh-neofetch/blob/main/assets/neofetch-basic.png" width="600px"></p>

On first run, the configuration wizard will launch automatically to help you set up your preferences.

## Usage

```powershell
neofetch [options]
```

> **Note:** `neofetch` is an alias for `Invoke-Neofetch`. Both commands work identically.

### Available Options

| Option | Description |
|--------|-------------|
| `-init` | Run the configuration wizard |
| `-Force` | Force reconfiguration even if config files exist |
| `-asciiart <path>` | Path to a text file containing custom ASCII art (max 20KB) |
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
| `-live` | Display live CPU, RAM, GPU, and VRAM usage graphs |
| `-reload` | Reset all configuration files and caches |
| `-help` | Display help message |

### Examples

```powershell
# Basic usage
neofetch

# Run configuration wizard
neofetch -init

# Display minimal information
neofetch -minimal

# Use custom ASCII art
neofetch -asciiart "C:\path\to\ascii\art.txt"

# Live system monitoring
neofetch -live

# View current configuration
neofetch -changes

# Force fresh data (bypass cache)
neofetch -nocache
```

## Configuration

All configuration is stored in your user profile directory (`$env:USERPROFILE`):

| File | Purpose |
|------|---------|
| `.neofetch_ascii` | Custom ASCII art |
| `.neofetch_cache_expiration` | Cache expiration time in seconds |
| `.neofetch_threads` | Maximum thread count |
| `.neofetch_profile_name` | Windows Terminal profile name |

To reset all configuration to defaults:

```powershell
neofetch -reload
```

## Custom ASCII Art

You can use your own ASCII art by creating a text file and pointing to it:

```powershell
neofetch -asciiart "C:\path\to\ascii\art.txt"
```

**Limitations:**

- Maximum file size: 20KB
- Path traversal (`..`) will trigger a warning but is allowed

Example ASCII art file:

```
⣾⡻⡃⣿⣿⠸⢣⣾⢸⡸⣿⣿⢹⣿⣿⣿⠘⣿⣿⣿⢈⣿⢸⣿⣷⣭⣿⣿⡇⣿
⠃⣾⠃⣿⡏⢇⣮⣟⠸⡇⣿⣿⢸⠿⣿⣿⣤⢿⣿⣿⢸⢹⡆⡟⣸⣿⡟⣿⡇⣿
⢰⣿⠄⣿⡇⡜⠛⠛⠿⢤⢹⣿⣼⢀⣿⡏⠿⠄⣿⠟⣰⣦⢧⢱⣿⣿⠳⣿⠃⣿
```

<p align="center"><img alt="custom-ascii" src="https://github.com/Sriram-PR/pwsh-neofetch/blob/main/assets/neofetch-zerotwo.png" width="600px"></p>

## Live System Monitoring

The `-live` flag displays real-time graphs for CPU, RAM, GPU, and VRAM usage:

```powershell
neofetch -live
```

Press `q` or `ESC` to exit the live view.

## Requirements

- Windows 10/11 or Windows Server 2016+
- PowerShell 5.1 or later (PowerShell 7+ recommended)

## Troubleshooting

### Cache Issues

If you experience stale data:

```powershell
neofetch -nocache
```

### Performance Issues

Adjust thread count for your system:

```powershell
neofetch -maxThreads 2  # For less powerful systems
neofetch -maxThreads 8  # For more powerful systems
```

### Reset Everything

To start fresh:

```powershell
neofetch -reload
```

## Roadmap

- [x] Multi-threaded system information collection
- [x] Custom ASCII art support
- [x] Caching system for improved performance
- [x] Live system monitoring graphs
- [x] Configuration wizard
- [ ] Color theme customization
- [ ] User-configurable information display order
- [ ] Export system information to file (JSON, CSV, TXT)
- [ ] Remote system information collection
- [ ] Gallery of pre-made ASCII art templates
- [ ] Plugin system for custom information modules
- [ ] Integration with hardware monitoring tools
- [ ] Localization support for multiple languages

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

This project is licensed under the [MIT License](LICENSE).

## Acknowledgments

- Inspired by the original [Neofetch](https://github.com/dylanaraps/neofetch) for Linux
