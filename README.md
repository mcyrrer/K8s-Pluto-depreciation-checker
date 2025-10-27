# 🔍 Kubernetes Depreciation Checker

[![Shell Script](https://img.shields.io/badge/Shell-Script-blue?logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Pluto](https://img.shields.io/badge/Pluto-Fairwinds-orange)](https://pluto.docs.fairwinds.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A powerful shell script that scans Kubernetes manifests for deprecated API versions using Pluto and Kustomize. Perfect for identifying deprecated APIs across multiple application overlays before cluster upgrades.

## ✨ Features

- 🔍 **Automated Scanning**: Recursively finds and processes all Kustomize overlay directories
- 🎯 **Version Targeting**: Check against specific Kubernetes versions or scan all versions
- 📊 **Detailed Reporting**: Clear output with color-coded results and summary statistics
- 🔧 **Kustomize Integration**: Builds manifests using Kustomize before deprecation checking
- ⚡ **Batch Processing**: Handles multiple applications and environments efficiently
- 🛡️ **Error Handling**: Robust error handling with detailed failure reporting

## 📋 Prerequisites

Before using this tool, ensure you have the following installed:

### Required Tools

| Tool | Purpose | Installation Guide |
|------|---------|-------------------|
| **[Pluto](https://pluto.docs.fairwinds.com/)** | Kubernetes deprecation checker | [Installation Guide](https://pluto.docs.fairwinds.com/installation/) |
| **[Kustomize](https://kustomize.io/)** | Kubernetes manifest customization | [Installation Guide](https://kubectl.docs.kubernetes.io/installation/kustomize/) |

### Quick Installation

```bash
# Install Pluto (macOS)
brew install FairwindsOps/tap/pluto

# Install Pluto (Linux)
curl -L https://github.com/FairwindsOps/pluto/releases/download/v5.18.4/pluto_5.18.4_linux_amd64.tar.gz | tar -xz
sudo mv pluto /usr/local/bin/

# Install Kustomize
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
sudo mv kustomize /usr/local/bin/
```

## 🏗️ Expected Directory Structure

The script expects your Kubernetes applications to follow this structure:

```
your-project/
├── application-1/
│   └── overlays/
│       ├── dev/
│       │   ├── kustomization.yaml
│       │   └── patches/
│       └── prod/
│           ├── kustomization.yaml
│           └── patches/
├── application-2/
│   └── overlays/
│       ├── dev/
│       └── staging/
│       └── prod/
└── application-n/
    └── overlays/
        └── ...
```

## 🚀 Usage

### Basic Usage

```bash
# Scan current directory (quiet mode)
./depreciation-checker.sh

# Scan with verbose output
./depreciation-checker.sh -v

# Scan specific directory
./depreciation-checker.sh -v /path/to/your/apps

# Target specific Kubernetes version
./depreciation-checker.sh -k v1.30.0 -v

# Silent mode (no progress dots)
./depreciation-checker.sh -s

# Combine options
KUBERNETES_VERSION=v1.30.0 ./depreciation-checker.sh -v -s
```

### Command Line Options

| Option | Description |
|--------|-------------|
| `-h, --help` | Show help message and usage examples |
| `-v, --verbose` | Enable verbose output (shows build and check status) |
| `-s, --silent` | Silent mode (suppress progress dots) |
| `-k, --k8s-version VERSION` | Target specific Kubernetes version (e.g., v1.30.0) |

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `KUBERNETES_VERSION` | Target Kubernetes version to check against | Scan all versions |

## 📊 Exit Codes

The script uses different exit codes to indicate various outcomes:

| Exit Code | Description |
|-----------|-------------|
| `0` | No issues found - all kustomizations built successfully with no deprecated APIs |
| `1` | Deprecated APIs found - kustomizations built but contain deprecated resources |
| `2` | Build failures only - some kustomizations failed to build |
| `3` | Both issues - deprecated APIs found AND build failures occurred |

## 📊 Output Examples

### Quiet Mode Output
```
=== 🔍 Kubernetes depreciation Checker ===

[ℹ️  INFO] 🔍 Checking prerequisites...
[ℹ️  INFO] 💡 Running with verbose logs
[ℹ️  INFO] '.' indicates a processed folder
[ℹ️  INFO] 🔍 Found pluto: version v5.18.4
[ℹ️  INFO] 🔧 Found kustomize: Version: kustomize/v5.0.1

[ℹ️  INFO] 🔍 Scanning for overlays directories in: .
[ℹ️  INFO] 🎯 Scanning all Kubernetes versions for deprecated APIs
...........

[ℹ️  INFO] 📊 Scan completed:
[ℹ️  INFO]   ✅ Processed: 11 overlays

[✅ SUCCESS] 🎉 depreciation check completed!
```

### Verbose Mode with Deprecations Found
```
[⚠️  WARNING] ⚠️  Deprecated APIs found:
NAME        KIND         VERSION              REPLACEMENT   REMOVED   DEPRECATED
deployment  Deployment   extensions/v1beta1   apps/v1       v1.16.0   v1.9.0
```

## 🛠️ How It Works

1. **Prerequisites Check**: Verifies that Pluto and Kustomize are installed and accessible
2. **Directory Discovery**: Recursively finds all `overlays` directories in the specified path
3. **Manifest Building**: Uses Kustomize to build complete manifests for each overlay
4. **Deprecation Scanning**: Runs Pluto against each built manifest to identify deprecated APIs
5. **Results Reporting**: Provides detailed output with color-coded status indicators

## 🔧 Troubleshooting

### Common Issues

#### Tool Not Found
```bash
[❌ ERROR] 🚫 pluto is not installed or not in PATH
```
**Solution**: Install the missing tool using the installation guides above.

#### Kustomization Build Failed
```bash
[❌ ERROR] 💥 Failed to build kustomization for ./app/overlays/dev
```
**Solution**: Check your `kustomization.yaml` files for syntax errors or missing resources.

#### No Overlays Found
If no overlays are processed, ensure your directory structure matches the expected format with `overlays` directories containing environment subdirectories.

## � Testing

The project includes comprehensive tests to ensure reliability and correctness.

### Test Structure

```
test/
├── valid-app/          # ✅ Working Kustomize configuration
│   ├── base/           # Base resources
│   └── overlays/       # Dev and Prod overlays
├── deprecated-app/     # ⚠️  Contains deprecated APIs for testing
│   ├── base/           # Base with deprecated apiVersions
│   └── overlays/       # Overlay using deprecated resources
├── invalid-app/        # ❌ Broken configuration for error testing
└── README.md           # Detailed test documentation
```

### Run Tests Locally

```bash
# Test valid configuration
./depreciation-checker.sh -v test/valid-app

# Test deprecated APIs detection
./depreciation-checker.sh -v test/deprecated-app

# Test invalid configuration (error handling)
./depreciation-checker.sh -v test/invalid-app

# Test all scenarios
./depreciation-checker.sh -v test/
```

### Automated Testing

The repository includes GitHub Actions workflows that automatically:
- ✅ Validate script syntax and code quality
- ✅ Test functionality across multiple Kubernetes versions
- ✅ Test deprecated API detection with known deprecated resources
- ✅ Test error handling and edge cases
- ✅ Generate comprehensive test reports

[![Tests](https://github.com/matgus/K8s-Pluto-depreciation-checker-MC/actions/workflows/test.yml/badge.svg)](https://github.com/matgus/K8s-Pluto-depreciation-checker-MC/actions/workflows/test.yml)

## �🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### Development

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. **Run tests**: `./depreciation-checker.sh -v test/` to ensure your changes work
4. Commit your changes (`git commit -m 'Add some amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

### Adding Tests

When contributing new features:
1. Add test cases in the `test/` directory
2. Update test documentation
3. Ensure GitHub Actions pass
4. Follow the existing test naming conventions

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Fairwinds Pluto](https://pluto.docs.fairwinds.com/) - For the excellent deprecation detection tool
- [Kubernetes SIG CLI Kustomize](https://kustomize.io/) - For the manifest customization framework

## 📞 Support

If you encounter any issues or have questions:

1. Check the [troubleshooting section](#-troubleshooting)
2. Search existing [issues](../../issues)
3. Create a new issue with detailed information about your problem

---

**Happy Kubernetes deprecation hunting! 🎯**