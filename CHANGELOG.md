# Changelog

All notable changes to pwsh-neofetch will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned

- Color theme customization
- User-configurable information display order
- Export system information to file (JSON, CSV, TXT)
- Remote system information collection
- Gallery of pre-made ASCII art templates
- Plugin system for custom information modules
- Integration with hardware monitoring tools
- Localization support for multiple languages

## [1.3.0] - 2025-12-16

### Added

- `Invoke-Neofetch` function name following PowerShell Verb-Noun convention
- `-AsObject` parameter for structured PSObject output, enabling pipeline usage with `ConvertTo-Json`, `Export-Csv`, etc.
- `-WhatIf` and `-Confirm` support for destructive operations like `-reload` and `-init`
- ASCII art file validation with 20KB size limit
- Path traversal detection with warning for `-asciiart` parameter
- Consolidated `$script:Defaults` hashtable for all configuration values
- Live graph default settings in configuration
- Expanded Pester test coverage for new functionality
- CONTRIBUTING.md with development setup and release process documentation
- CHANGELOG.md for version history tracking
- CI version validation (manifest must match git tag)

### Changed

- **Breaking:** Primary function renamed from `neofetch` to `Invoke-Neofetch`
  - The `neofetch` alias is automatically created for backward compatibility
  - Users calling `neofetch` directly will not be affected
- `VariablesToExport` changed from `'*'` to `@()` to prevent namespace pollution
- `module_relocator.ps1` now uses registry-based OneDrive detection and recursive search, supporting all language localisations
- Help text now references centralized default values
- Refactored codebase for improved maintainability
- Removed standalone script in favor of module-only distribution
- Improved CI/CD pipeline with tests before publish
- Enhanced error handling with verbose diagnostic output

### Removed

- **Breaking:** Benchmark feature (`-benchmark` parameter) removed entirely
  - `Invoke-SystemBenchmark` function removed
  - `Show-BenchmarkResults` function removed
  - Users requiring benchmarking should use dedicated tools (CrystalDiskMark, etc.)

### Fixed

- ASCII art validation now fails gracefully with fallback to default art
- Clear error messages for ASCII art file issues (not found, too large, is directory)
- Version and release notes mismatch in module manifest
- Variable scope issue in live graphs error handling
- Silent error swallowing now logs to verbose stream

### Security

- Removed `-Verbose` flag from publish workflow to prevent credential leakage
- Added version-tag validation to prevent release mismatches

## [1.2.0] - 2025-05-11

### Added

- **Live system monitoring** (`-live`): Real-time CPU, RAM, GPU, and VRAM usage graphs with character-based visualization
- **Configuration wizard** (`-init`): Interactive first-run setup for preferences
- **System benchmark** (`-benchmark`): CPU, memory, and disk I/O performance testing with composite scoring
- **Minimal view** (`-minimal`): Condensed output showing only essential system information
- **Terminal profile configuration** (`-profileName`): Custom Windows Terminal profile detection for accurate font information
- **Cache system**: Configurable caching to reduce repeated WMI queries
  - `-cacheExpiration <seconds>`: Set cache lifetime
  - `-nocache`: Force fresh data collection
  - `-defaultcache`: Reset to default (30 minutes)
- **Thread configuration** (`-maxThreads`): Control parallel data collection
- **Configuration management**:
  - `-changes`: Display current configuration status
  - `-reload`: Reset all configuration to defaults

### Changed

- Multi-threaded system information collection using runspace pools for improved performance
- GPU detection now prioritizes discrete GPUs (NVIDIA, AMD) over integrated graphics
- GPU memory reporting via `nvidia-smi` for NVIDIA cards

## [1.1.2] - 2025-03-05

### Fixed

- Username retrieval issue
- Improved compatibility on Windows Terminal

## [1.1.1] - 2025-03-01

### Changed

- Minor stability improvements (v1.1 final)

## [1.1.0] - 2025-03-01

### Added

- Initial module structure for PowerShell Gallery
- Module relocator script for OneDrive path issues
- Basic system information display

### Changed

- Restructured for PSGallery distribution

## [1.0.0] - 2025-02-28

### Added

- Initial release
- System information display (OS, Host, Kernel, Uptime, Packages, Shell, Resolution, WM, Terminal, CPU, GPU, Memory, Disk, Battery)
- Custom ASCII art support (`-asciiart`, `-defaultart`)
- Color block display
- Windows logo ASCII art

[Unreleased]: https://github.com/Sriram-PR/pwsh-neofetch/compare/v1.3.0...HEAD
[1.3.0]: https://github.com/Sriram-PR/pwsh-neofetch/compare/v1.2.1...v1.3.0
[1.2.0]: https://github.com/Sriram-PR/pwsh-neofetch/compare/v1.1.2...v1.2.0
[1.1.2]: https://github.com/Sriram-PR/pwsh-neofetch/compare/v1.1.1...v1.1.2
[1.1.1]: https://github.com/Sriram-PR/pwsh-neofetch/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/Sriram-PR/pwsh-neofetch/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/Sriram-PR/pwsh-neofetch/releases/tag/v1.0.0
