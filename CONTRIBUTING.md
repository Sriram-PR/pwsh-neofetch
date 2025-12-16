# Contributing to pwsh-neofetch

Thank you for your interest in contributing to pwsh-neofetch! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Pull Request Process](#pull-request-process)
- [Release Process](#release-process)
- [Style Guide](#style-guide)

---

## Code of Conduct

Please be respectful and constructive in all interactions. We welcome contributors of all experience levels.

---

## Getting Started

### Prerequisites

- Windows 10/11 or Windows Server 2016+
- PowerShell 5.1 or later (PowerShell 7+ recommended for development)
- Git

### Repository Structure

```
pwsh-neofetch/
├── .github/
│   ├── ISSUE_TEMPLATE/      # Bug report and feature request templates
│   └── workflows/           # CI/CD pipelines
├── ps-gallery-build/
│   └── pwsh-neofetch/       # Module source (published to PSGallery)
│       ├── pwsh-neofetch.psd1   # Module manifest
│       └── pwsh-neofetch.psm1   # Module code
├── direct-installer.ps1     # Alternative installation script
├── direct-uninstaller.ps1   # Uninstallation script
├── module_relocator.ps1     # OneDrive path fix utility
├── CHANGELOG.md             # Version history
└── README.md                # Project documentation
```

---

## Development Setup

1. **Fork and clone the repository:**

   ```powershell
   git clone https://github.com/YOUR-USERNAME/pwsh-neofetch.git
   cd pwsh-neofetch
   ```

2. **Import the module for testing:**

   ```powershell
   Import-Module ./ps-gallery-build/pwsh-neofetch/pwsh-neofetch.psd1 -Force
   ```

3. **Test your changes:**

   ```powershell
   neofetch
   neofetch -minimal
   neofetch -changes
   ```

4. **Re-import after changes:**

   ```powershell
   Remove-Module pwsh-neofetch -ErrorAction SilentlyContinue
   Import-Module ./ps-gallery-build/pwsh-neofetch/pwsh-neofetch.psd1 -Force
   ```

---

## Making Changes

### Branch Naming

- `feature/short-description` — New features
- `fix/short-description` — Bug fixes
- `docs/short-description` — Documentation only
- `refactor/short-description` — Code refactoring

### Commit Messages

Use clear, descriptive commit messages:

```
<type>: <short summary>

<optional body with more details>
```

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`

Examples:

```
feat: add JSON output format option
fix: resolve GPU detection on AMD cards
docs: update installation instructions
refactor: extract system info functions to separate file
```

---

## Pull Request Process

1. **Create a feature branch** from `main`
2. **Make your changes** with clear commits
3. **Test thoroughly** on your system
4. **Update documentation** if needed (README, CHANGELOG)
5. **Submit PR** with a clear description of changes

### PR Checklist

- [ ] Code follows the [style guide](#style-guide)
- [ ] Changes tested on Windows 10/11
- [ ] No hardcoded paths or user-specific values
- [ ] Error handling added for new functionality
- [ ] CHANGELOG.md updated (for user-facing changes)
- [ ] README.md updated (if adding new features/options)

---

## Release Process

> **Important:** Only maintainers can publish releases. Contributors should not modify version numbers.

### For Maintainers: Version Bump Procedure

When preparing a release, follow these steps **exactly** to avoid CI failures:

#### Step 1: Update Version in Manifest

Edit `ps-gallery-build/pwsh-neofetch/pwsh-neofetch.psd1`:

```powershell
# Update BOTH of these fields:
ModuleVersion = '1.2.1'  # ← New version number

# In PrivateData.PSData:
ReleaseNotes = 'v1.2.1 - Brief description. See CHANGELOG.md for details.'
```

#### Step 2: Update CHANGELOG.md

Add a new section under `## [Unreleased]`:

```markdown
## [1.2.1] - 2025-01-15

### Added
- New feature X

### Changed
- Modified behavior Y

### Fixed
- Bug fix Z
```

Update the comparison links at the bottom of the file.

#### Step 3: Commit and Tag

```powershell
git add .
git commit -m "chore: bump version to 1.2.1"
git tag v1.2.1
git push origin main --tags
```

#### Step 4: Create GitHub Release

1. Go to **Releases** → **Create a new release**
2. Select the tag `v1.2.1`
3. Title: `v1.2.1`
4. Description: Copy relevant section from CHANGELOG.md
5. Click **Publish release**

The CI workflow will automatically:

- Validate that the manifest version matches the tag
- Publish to PowerShell Gallery

### Version Number Rules

- **Major** (X.0.0): Breaking changes, major rewrites
- **Minor** (1.X.0): New features, backward-compatible
- **Patch** (1.2.X): Bug fixes, minor improvements

### CI Version Validation

The publish workflow **will fail** if:

- Manifest `ModuleVersion` doesn't match the git tag
- Example: Tag `v1.2.1` requires `ModuleVersion = '1.2.1'`

This prevents accidental version mismatches between git and PSGallery.

---

## Style Guide

### PowerShell Conventions

1. **Function Naming:** Use `Verb-Noun` format for internal functions

   ```powershell
   # Good
   function Get-SystemInfoFast { }
   function Reset-NeofetchConfiguration { }
   
   # Exception: exported 'neofetch' function (for user familiarity)
   ```

2. **Parameter Naming:** Use PascalCase

   ```powershell
   param(
       [string]$AsciiArtPath,
       [switch]$UseMinimal
   )
   ```

3. **Variables:** Use camelCase for local, PascalCase for parameters

   ```powershell
   $maxThreads = 4
   $cacheExpiration = 1800
   ```

4. **Error Handling:** Always provide context

   ```powershell
   # Good
   catch {
       Write-Verbose "Error getting CPU info: $_"
       return "Unknown"
   }
   
   # Avoid
   catch { return "Unknown" }
   ```

5. **Comments:** Explain *why*, not *what*

   ```powershell
   # Good: Explain reasoning
   # Use discrete GPU if available, as integrated GPUs report less useful info
   $DiscreteGPU = $GPUInfoAll | Where-Object { $_.Description -match "NVIDIA|AMD" }
   
   # Avoid: Obvious comments
   # Get the GPU
   $GPU = Get-GPU
   ```

### Formatting

- Indent with 4 spaces (not tabs)
- Maximum line length: 120 characters
- Use blank lines to separate logical sections
- Keep functions focused and reasonably sized (<100 lines preferred)

### Testing Checklist

Before submitting, test these scenarios:

- [ ] Fresh install (no config files exist)
- [ ] With existing config files
- [ ] `-init` wizard flow
- [ ] `-minimal` output
- [ ] `-live` graphs display correctly
- [ ] Custom ASCII art (`-asciiart`)
- [ ] Cache behavior (`-nocache`, `-changes`)

---

## Questions?

- Open an [issue](https://github.com/Sriram-PR/pwsh-neofetch/issues) for bugs or feature requests
- Check existing issues before creating new ones

Thank you for contributing!
