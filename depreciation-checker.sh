#!/bin/bash

# =============================================================================
# 🔍 Kubernetes Depreciation Checker For Kustomize manifests
# =============================================================================
# This script scans Kubernetes manifests for deprecated API versions using Pluto
# and Kustomize. It processes all overlays in the specified directory structure
#
# Prerequisites:
#   - pluto: https://pluto.docs.fairwinds.com/installation/
#   - kustomize: https://kubectl.docs.kubernetes.io/installation/kustomize/
#
# Expected folder structure:
#   📁 application-name/overlays/dev/
#   📁 application-name/overlays/prod/
# =============================================================================

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# =============================================================================
# ⚙️  CONFIGURATION
# =============================================================================


# Global verbose flag
VERBOSE=false

# Global silent flag
SILENT=false

# Kubernetes version for pluto checks
k8s_version=""

# Arrays to track overlay results
FAILED_OVERLAYS=()
DEPRECATED_OVERLAYS=()

# =============================================================================
# 🛠️  UTILITY FUNCTIONS
# =============================================================================

# Display usage information
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS] [BASE_DIRECTORY]

Scans Kubernetes manifests for deprecated API versions using Pluto.
Works by processing all 'overlays' directories in the specified base directory.

Required Tools:
    - pluto: https://pluto.docs.fairwinds.com/installation/
    - kustomize: https://kubectl.docs.kubernetes.io/installation/kustomize/

Options:
    -h, --help        Show this help message
    -v, --verbose     Enable verbose output (show build and check status)
    -s, --silent      Silent mode (suppress progress dots)
    -k, --k8s-version VERSION  Target Kubernetes version (e.g. v1.30)


Arguments:
    BASE_DIRECTORY    Directory to scan (default: current directory)

Exit Codes:
    0    No issues found with kustomizations
    1    Kustomizations with deprecations found
    2    Could not build kustomization(s)
    3    Kustomizations with deprecations found AND could not build kustomization(s)

Examples:
    $0                    # Scan current directory (quiet mode)
    $0 -v                 # Scan with verbose output
    $0 -v /path/to/apps   # Scan specific directory with verbose output
    $0 -k v1.30.0 -v      # Use specific K8s version

EOF
}

# Print colored output
print_info() {

    echo -e "\033[34m[ℹ️  INFO]\033[0m $*"
}

print_warning() {
    if [[ "$VERBOSE" == "false" ]]; then
        echo
    fi    
    echo -e "\033[33m[⚠️  WARNING]\033[0m $*"
}

print_error() {
    if [[ "$VERBOSE" == "false" ]]; then
        echo
    fi
    echo -e "\033[31m[❌ ERROR]\033[0m $*"
}

print_success() {
    echo -e "\033[32m[✅ SUCCESS]\033[0m $*"
}

# Print verbose messages (only when -v flag is used)
print_verbose() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "\033[95m[🐍 VERBOSE]\033[0m $*"
    fi
}

print_verbose_success() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "\033[32m[✅ SUCCESS]\033[0m $*"
    fi
}
# =============================================================================
# 🔧 PREREQUISITE CHECKS
# =============================================================================

# Check if pluto is installed and available
check_pluto() {
    if ! command -v pluto &> /dev/null; then
        print_error "🚫 pluto is not installed or not in PATH"
        print_info "📚 Installation guide: https://pluto.docs.fairwinds.com/installation/"
        exit 1
    fi
    print_info "🔍 Found pluto: $(pluto version 2>/dev/null | head -1 || echo 'version unknown')"
}

# Check if kustomize is installed and available
check_kustomize() {
    if ! command -v kustomize &> /dev/null; then
        print_error "🚫 kustomize is not installed or not in PATH"
        print_info "📚 Installation guide: https://kubectl.docs.kubernetes.io/installation/kustomize/"
        exit 1
    fi
    print_info "🔧 Found kustomize: $(kustomize version 2>/dev/null | head -1 || echo 'version unknown')"
}

# Run all prerequisite checks
check_prerequisites() {
    print_info "🔍 Checking prerequisites..."
    if [[ "$VERBOSE" != "true" ]]; then
        print_info "💡 Running with verbose logs"
        print_info "'.' indicates a processed folder"
    else
        print_verbose "Running with verbose logs"
    fi
    check_pluto
    check_kustomize
    # Run pluto depreciation check
    if [[ -n "$k8s_version" ]]; then
        print_info "🔍 Running depreciation check (target: $k8s_version)..."
    else
        print_info "🔍 Running depreciation check (all versions)..."
    fi    
}

# =============================================================================
# ⚡ CORE FUNCTIONS
# =============================================================================

# Process a single overlay directory
process_overlay() {
    local env_dir="$1"
    local temp_dir="$2"
    
    print_verbose "📂 Processing: $env_dir"
    
    # Clean up any previous manifest
    rm -f "$temp_dir/manifest.yaml"
    
    # Build kustomization
    if kustomize build "$env_dir" > "$temp_dir/manifest.yaml" 2>/dev/null; then
        print_verbose_success "🏗️  Built kustomization successfully"
        

        
        # Capture pluto output and exit code
        local pluto_output
        local pluto_exit_code
        
        # Build pluto command based on whether version is specified
        if [[ -n "$k8s_version" ]]; then
            print_verbose "🔍 Running: pluto detect $temp_dir/manifest.yaml --target-versions k8s=$k8s_version"
            pluto_output=$(pluto detect "$temp_dir/manifest.yaml" --target-versions "k8s=$k8s_version" 2>/dev/null)
        else
            print_verbose "🔍 Running: pluto detect $temp_dir/manifest.yaml"
            pluto_output=$(pluto detect "$temp_dir/manifest.yaml" 2>/dev/null)
        fi
        pluto_exit_code=$?
        
        if [[ $pluto_exit_code -eq 0 ]]; then
            print_verbose_success "✨ No deprecated APIs found"
            return 0
        else
            print_warning "⚠️  Deprecated APIs found at $env_dir:"
            echo "$pluto_output"
            DEPRECATED_OVERLAYS+=("$env_dir")
            return 1
        fi
    else
        print_error "💥 Failed to build kustomization for $env_dir"
        FAILED_OVERLAYS+=("$env_dir")
        return 2
    fi   
}

# Find and process all overlay directories
process_overlays() {
    local base_dir="${1:-.}"
    
    print_info "🔍 Scanning for overlays directories in: $base_dir"
    # if [[ -n "$k8s_version" ]]; then
    #     print_info "🎯 Target Kubernetes version: $k8s_version"
    # else
    #     print_info "🎯 Scanning all Kubernetes versions for deprecated APIs"
    # fi
    
    # Create temporary directory for manifests
    local temp_dir
    temp_dir=$(mktemp -d)
    print_verbose "🗂️  Using temporary directory: $temp_dir"
    # Ensure cleanup on exit
    trap "rm -rf '$temp_dir'" EXIT
    
    local processed_count=0
    local failed_count=0
    local deprecated_count=0
    
    # Find all overlays directories with dev or prod subdirectories
    # First, find all overlays directories
    local overlays_dirs=()
    while IFS= read -r -d '' overlays_dir; do
        overlays_dirs+=("$overlays_dir")
    done < <(find "$base_dir" -type d -name "overlays" -print0)
    
    print_verbose "🔎 Found ${#overlays_dirs[@]} overlays directories"
    
    # Then iterate over them one by one
    for overlays_dir in "${overlays_dirs[@]}"; do
        print_verbose_success "🔎 Processing overlays directory for all overlay subfolders: $overlays_dir"
        for env_dir in "$overlays_dir"/*; do
            if [[ -d "$env_dir" ]]; then
                local result
                # Use 'set +e' temporarily to prevent script exit on function failure
                set +e
                process_overlay "$env_dir" "$temp_dir"
                echo "debug 0"
                result=$?
                echo "debug 1"
                set -e
                
                if [[ "$VERBOSE" != "true" && "$SILENT" != "true" ]]; then
                    echo -n "."
                fi
                echo "debug 2"

                
                case $result in
                    0)
                        ((processed_count++))
                        ;;
                    1)
                        ((processed_count++))
                        ((deprecated_count++))
                        ;;
                    2)
                        ((failed_count++))
                        ;;
                esac
            fi
                echo "debug 3"
        done
        echo "debug 4"
    done
    
    # Summary
    echo ""
    print_info "📊 Scan completed:"
    print_info "  ✅ Processed: $processed_count overlays"
    if [[ $deprecated_count -gt 0 ]]; then
        print_warning "  ⚠️  With deprecations: $deprecated_count overlays"
    fi
}

# Determine appropriate exit code based on results
determine_exit_code() {
    local has_deprecated=$([[ ${#DEPRECATED_OVERLAYS[@]} -gt 0 ]] && echo "true" || echo "false")
    local has_failed=$([[ ${#FAILED_OVERLAYS[@]} -gt 0 ]] && echo "true" || echo "false")
    
    if [[ "$has_deprecated" == "true" && "$has_failed" == "true" ]]; then
        return 3  # Both deprecations and build failures
    elif [[ "$has_failed" == "true" ]]; then
        return 2  # Only build failures
    elif [[ "$has_deprecated" == "true" ]]; then
        return 1  # Only deprecations
    else
        return 0  # No issues
    fi
}

# =============================================================================
# 🚀 MAIN EXECUTION
# =============================================================================

main() {
    # Parse command line arguments
    local base_dir="."
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -s|--silent)
                SILENT=true
                shift
                ;;
            -k|--k8s-version)
                if [[ -n "${2:-}" ]]; then
                    # Validate k8s version format (v1.30.0 or v1.30)
                    if [[ ! "$2" =~ ^v[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
                        print_error "Invalid Kubernetes version format: $2"
                        print_error "Expected format: v1.30.0 or v1.30"
                        exit 1
                    fi
                    k8s_version="$2"
                    shift 2
                else
                    print_error "Missing value for -k|--k8s-version option"
                    exit 1
                fi
                ;;
            -* )
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
            * )
                base_dir="$1"
                shift
                ;;
        esac
    done
    
    echo "=== 🔍 Kubernetes depreciation Checker ==="
    echo ""
    
    # Check prerequisites
    check_prerequisites
    echo ""
    
    # Process overlays
    process_overlays "$base_dir"
    
    # Determine and use appropriate exit code
    echo ""
    if [[ ${#DEPRECATED_OVERLAYS[@]} -eq 0 && ${#FAILED_OVERLAYS[@]} -eq 0 ]]; then
        print_success "🎉 Depreciation check completed! No issues found."
    else
        print_success "🎉 Depreciation check completed!"
        if [[ ${#DEPRECATED_OVERLAYS[@]} -gt 0 ]]; then
            print_warning "Found deprecations in ${#DEPRECATED_OVERLAYS[@]} overlay(s)"
        fi
        if [[ ${#FAILED_OVERLAYS[@]} -gt 0 ]]; then
            print_error "Failed to build ${#FAILED_OVERLAYS[@]} overlay(s)"
        fi
    fi
    
    determine_exit_code
    local exit_code=$?
    exit $exit_code
}

# Run main function with all arguments
main "$@"