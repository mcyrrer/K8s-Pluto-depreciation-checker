# 🧪 Test Documentation

This directory contains test cases for the Kubernetes Depreciation Checker script.

## 📁 Test Structure

```
test/
├── valid-app/                  # ✅ Valid Kustomize configuration
│   ├── base/
│   │   ├── kustomization.yaml  # Base Kustomize configuration
│   │   ├── deployment.yaml     # Sample deployment
│   │   └── service.yaml        # Sample service
│   └── overlays/
│       ├── dev/
│       │   ├── kustomization.yaml      # Dev overlay
│       │   └── deployment-patch.yaml   # Dev-specific patches
│       └── prod/
│           ├── kustomization.yaml      # Prod overlay
│           └── deployment-patch.yaml   # Prod-specific patches
└── invalid-app/                # ❌ Invalid Kustomize configuration
    └── overlays/
        └── dev/
            ├── kustomization.yaml      # References non-existent files
            └── invalid-patch.yaml      # Invalid patch configuration
```

## 🎯 Test Cases

### Valid App (`test/valid-app`)
- **Purpose**: Tests successful Kustomize builds and deprecation checking
- **Structure**: Complete Kustomize setup with base and overlays
- **Expected Result**: Script should successfully process all overlays
- **Features Tested**:
  - Base resource loading
  - Overlay patching
  - Namespace application
  - Label application
  - Resource customization

### Invalid App (`test/invalid-app`)
- **Purpose**: Tests error handling for broken Kustomize configurations
- **Issues**:
  - References non-existent resources (`non-existent-resource.yaml`)
  - Invalid patch targeting non-existent deployment
  - Missing base directory
- **Expected Result**: Script should gracefully handle build failures
- **Features Tested**:
  - Error handling
  - Failure reporting
  - Graceful degradation

## 🔧 Manual Testing

### Run Tests Locally

```bash
# Test valid configuration
./depreciation-checker.sh -v test/valid-app

# Test invalid configuration (should show errors)
./depreciation-checker.sh -v test/invalid-app

# Test both (mixed results)
./depreciation-checker.sh -v test/

# Test with specific Kubernetes version
KUBERNETES_VERSION=v1.28.0 ./depreciation-checker.sh -v test/valid-app
```

### Expected Outputs

#### Valid App Output
```
=== 🔍 Kubernetes depreciation Checker ===

[ℹ️  INFO] 🔍 Checking prerequisites...
[ℹ️  INFO] Running with verbose logs
[ℹ️  INFO] 🔍 Found pluto: version v5.18.4
[ℹ️  INFO] 🔧 Found kustomize: Version: kustomize/v5.0.1

[ℹ️  INFO] 🔍 Scanning for overlays directories in: test/valid-app
[ℹ️  INFO] 🎯 Scanning all Kubernetes versions for deprecated APIs
[ℹ️  INFO] 📂 Processing: test/valid-app/overlays/dev
[✅ SUCCESS] 🏗️  Built kustomization successfully
[ℹ️  INFO] 🔍 Running depreciation check (all versions)...
[✅ SUCCESS] ✨ No deprecated APIs found
---
[ℹ️  INFO] 📂 Processing: test/valid-app/overlays/prod
[✅ SUCCESS] 🏗️  Built kustomization successfully
[ℹ️  INFO] 🔍 Running depreciation check (all versions)...
[✅ SUCCESS] ✨ No deprecated APIs found
---

[ℹ️  INFO] 📊 Scan completed:
[ℹ️  INFO]   ✅ Processed: 2 overlays

[✅ SUCCESS] 🎉 depreciation check completed!
```

#### Invalid App Output
```
=== 🔍 Kubernetes depreciation Checker ===

[ℹ️  INFO] 🔍 Checking prerequisites...
[ℹ️  INFO] Running with verbose logs
[ℹ️  INFO] 🔍 Found pluto: version v5.18.4
[ℹ️  INFO] 🔧 Found kustomize: Version: kustomize/v5.0.1

[ℹ️  INFO] 🔍 Scanning for overlays directories in: test/invalid-app
[ℹ️  INFO] 🎯 Scanning all Kubernetes versions for deprecated APIs
[ℹ️  INFO] 📂 Processing: test/invalid-app/overlays/dev
[❌ ERROR] 💥 Failed to build kustomization for test/invalid-app/overlays/dev
---

[ℹ️  INFO] 📊 Scan completed:
[ℹ️  INFO]   ✅ Processed: 0 overlays
[⚠️  WARNING]   ❌ Failed: 1 overlays

[✅ SUCCESS] 🎉 depreciation check completed!
```

## 🚀 GitHub Actions Testing

The repository includes a comprehensive GitHub Actions workflow (`.github/workflows/test.yml`) that:

### Test Jobs

1. **test-depreciation-checker**
   - Tests script functionality across multiple Kubernetes versions
   - Tests both valid and invalid configurations
   - Tests mixed scenarios
   - Tests quiet and verbose modes

2. **test-script-validation**
   - Validates shell script syntax
   - Runs ShellCheck for code quality

3. **test-edge-cases**
   - Tests empty directories
   - Tests non-existent paths
   - Tests invalid arguments
   - Tests current directory execution

4. **create-test-report**
   - Generates comprehensive test reports
   - Uploads results as artifacts

### Matrix Testing

The workflow tests against multiple Kubernetes versions:
- `v1.25.0`
- `v1.28.0`
- All versions (empty string)

### Trigger Conditions

- Push to `main` or `develop` branches
- Pull requests to `main`
- Manual workflow dispatch

## 🔍 Adding New Tests

To add new test cases:

1. Create new app directories under `test/`
2. Follow the expected Kustomize structure
3. Update this documentation
4. Consider adding specific test steps to the GitHub workflow

### Test Naming Convention

- `valid-*`: Tests that should succeed
- `invalid-*`: Tests that should fail gracefully
- `deprecated-*`: Tests with intentional deprecated APIs
- `edge-*`: Edge case scenarios

## 📊 Continuous Integration

The GitHub Actions workflow ensures:
- ✅ Script syntax is valid
- ✅ Dependencies are properly installed
- ✅ All test cases pass
- ✅ Error handling works correctly
- ✅ Cross-platform compatibility (Ubuntu)
- ✅ Multiple Kubernetes version support