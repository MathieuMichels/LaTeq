#!/bin/bash

# LaTeq Linux/macOS Uninstall Script
# Completely removes LaTeq from Unix-like systems (but not the dependencies)
# Handles system-wide LaTeq installations
# Repository: https://github.com/MathieuMichels/LaTeq
# Usage: curl -sSL https://raw.githubusercontent.com/MathieuMichels/LaTeq/main/uninstall.sh | bash
# Or: bash <(wget -qO- https://raw.githubusercontent.com/MathieuMichels/LaTeq/main/uninstall.sh)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DEFAULT_INSTALL_PATHS=(
    "/usr/local/bin/LaTeq"
    "/usr/bin/LaTeq"
    "/opt/LaTeq/LaTeq"
    "$HOME/.local/bin/LaTeq"
    "$HOME/bin/LaTeq"
)

TEMP_DIRS=(
    "/tmp/lateq-install"
    "/tmp/lateq-test"
    "/tmp/LaTeq"
    "$HOME/.cache/lateq"
    "$HOME/.tmp/lateq"
)

# Command line arguments
FORCE_REMOVE=false
KEEP_DEPENDENCIES=true
SHOW_HELP=false

# Parse command line arguments function
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --force)
                FORCE_REMOVE=true
                shift
                ;;
            --keep-dependencies|--keep-deps)
                KEEP_DEPENDENCIES=true
                shift
                ;;
            --remove-dependencies|--remove-deps)
                KEEP_DEPENDENCIES=false
                shift
                ;;
            --help|-h)
                SHOW_HELP=true
                shift
                ;;
            *)
                echo "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

# Show help message
show_help() {
    echo "LaTeq Uninstall Script"
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "OPTIONS:"
    echo "  --force                 Skip confirmation prompts"
    echo "  --remove-dependencies   Also remove LaTeX and ImageMagick dependencies"
    echo "  --keep-dependencies     Keep dependencies (default)"
    echo "  --help, -h             Show this help message"
    echo
    echo "Examples:"
    echo "  $0                     # Interactive uninstall"
    echo "  $0 --force             # Silent uninstall"
    echo "  $0 --remove-dependencies  # Remove LaTeq and all dependencies"
    echo
}

# Print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running with appropriate privileges
check_privileges() {
    if [[ $EUID -eq 0 ]]; then
        print_info "Running as root."
        USE_SUDO=""
    else
        print_info "Running as regular user. Will use sudo for system files."
        USE_SUDO="sudo"
        
        # Check if sudo is available
        if ! command -v sudo >/dev/null 2>&1; then
            print_error "sudo command not found. Please run as root or install sudo."
            exit 1
        fi
    fi
}

# Find LaTeq installations
find_lateq_installations() {
    print_info "Searching for LaTeq installations..."
    
    local found_installations=()
    
    # Check default installation paths
    for path in "${DEFAULT_INSTALL_PATHS[@]}"; do
        if [[ -f "$path" ]]; then
            found_installations+=("$path")
        fi
    done
    
    # Check for LaTeq in PATH directories
    if command -v LaTeq >/dev/null 2>&1; then
        local lateq_path=$(which LaTeq 2>/dev/null)
        if [[ -n "$lateq_path" && ! " ${found_installations[*]} " =~ " ${lateq_path} " ]]; then
            found_installations+=("$lateq_path")
        fi
    fi
    
    # Search in common directories for any missed installations
    local search_dirs=(
        "/usr/local/bin"
        "/usr/bin"
        "/opt"
        "$HOME/.local/bin"
        "$HOME/bin"
    )
    
    for dir in "${search_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            # Find files named LaTeq
            while IFS= read -r -d '' file; do
                if [[ ! " ${found_installations[*]} " =~ " ${file} " ]]; then
                    found_installations+=("$file")
                fi
            done < <(find "$dir" -name "LaTeq" -type f -print0 2>/dev/null || true)
        fi
    done
    
    # Store results in global variable
    FOUND_INSTALLATIONS=("${found_installations[@]}")
    
    if [[ ${#FOUND_INSTALLATIONS[@]} -gt 0 ]]; then
        print_success "Found ${#FOUND_INSTALLATIONS[@]} LaTeq installation(s):"
        for installation in "${FOUND_INSTALLATIONS[@]}"; do
            echo "  - $installation"
        done
    else
        print_info "No LaTeq installations found."
    fi
}
# Remove LaTeq installations
remove_lateq_installations() {
    if [[ ${#FOUND_INSTALLATIONS[@]} -eq 0 ]]; then
        print_info "No LaTeq installations to remove."
        return false
    fi
    
    print_info "Removing LaTeq installations..."
    
    local removed_count=0
    
    for installation in "${FOUND_INSTALLATIONS[@]}"; do
        print_info "Removing: $installation"
        
        # Check if we need sudo for this file
        local dir=$(dirname "$installation")
        if [[ -w "$dir" ]]; then
            # We can write to the directory, no sudo needed
            if rm -f "$installation" 2>/dev/null; then
                print_success "Removed: $installation"
                ((removed_count++))
            else
                print_error "Failed to remove: $installation"
            fi
        else
            # Need sudo for system directories
            if $USE_SUDO rm -f "$installation" 2>/dev/null; then
                print_success "Removed: $installation"
                ((removed_count++))
            else
                print_error "Failed to remove: $installation"
            fi
        fi
    done
    
    if [[ $removed_count -gt 0 ]]; then
        print_success "Removed $removed_count LaTeq installation(s)."
        return true
    else
        print_warning "No LaTeq installations were successfully removed."
        return false
    fi
}

# Clean up temporary files
cleanup_temp_files() {
    print_info "Cleaning up temporary files..."
    
    local removed_count=0
    
    for temp_dir in "${TEMP_DIRS[@]}"; do
        if [[ -d "$temp_dir" ]]; then
            print_info "Removing temporary directory: $temp_dir"
            if rm -rf "$temp_dir" 2>/dev/null; then
                print_success "Removed: $temp_dir"
                ((removed_count++))
            else
                print_warning "Failed to remove: $temp_dir"
            fi
        fi
    done
    
    # Clean up any LaTeq-related files in /tmp
    if [[ -d "/tmp" ]]; then
        find /tmp -name "*lateq*" -o -name "*LaTeq*" -type f -mtime +1 -delete 2>/dev/null || true
        find /tmp -name "equation_*.pdf" -o -name "equation_*.png" -o -name "equation_*.jpg" -type f -mtime +1 -delete 2>/dev/null || true
    fi
    
    if [[ $removed_count -gt 0 ]]; then
        print_success "Cleaned up $removed_count temporary directories."
    else
        print_info "No temporary files found to clean up."
    fi
}

# Verify uninstallation
verify_uninstallation() {
    print_info "Verifying uninstallation..."
    
    local issues=()
    
    # Check if LaTeq command is still available
    if command -v LaTeq >/dev/null 2>&1; then
        local lateq_path=$(which LaTeq 2>/dev/null)
        issues+=("LaTeq command still available at: $lateq_path")
    fi
    
    # Check installation paths again
    for path in "${DEFAULT_INSTALL_PATHS[@]}"; do
        if [[ -f "$path" ]]; then
            issues+=("LaTeq file still exists: $path")
        fi
    done
    
    # Check for any remaining LaTeq files in common directories
    for dir in "/usr/local/bin" "/usr/bin" "/opt"; do
        if [[ -d "$dir" ]]; then
            while IFS= read -r -d '' file; do
                issues+=("LaTeq file still exists: $file")
            done < <(find "$dir" -name "LaTeq" -type f -print0 2>/dev/null || true)
        fi
    done
    
    if [[ ${#issues[@]} -eq 0 ]]; then
        print_success "LaTeq successfully uninstalled!"
    else
        print_warning "Uninstallation completed with some issues:"
        for issue in "${issues[@]}"; do
            print_warning "  - $issue"
        done
        echo
        print_info "You may need to manually remove remaining files or restart your shell."
    fi
}

# Show dependency information
show_dependency_info() {
    if [[ $KEEP_DEPENDENCIES == true ]]; then
        echo
        print_info "Dependencies were NOT removed:"
        echo "The following software remains installed (if it was installed):"
        echo "  - TeX Live or MacTeX (LaTeX distribution)"
        echo "  - ImageMagick (image conversion)"
        echo
        echo "If you want to remove these dependencies, you can:"
        echo "  - Re-run this script with --remove-dependencies"
        echo "  - Or remove manually:"
        echo "    Debian/Ubuntu: sudo apt remove texlive imagemagick"
        echo "    Fedora: sudo dnf remove texlive ImageMagick"
        echo "    Arch: sudo pacman -Rs texlive-core imagemagick"
        echo "    macOS: brew uninstall mactex imagemagick"
        echo
    fi
}

# Remove dependencies
remove_dependencies() {
    if [[ $KEEP_DEPENDENCIES == true ]]; then
        print_info "Keeping dependencies (use --remove-dependencies to remove them)."
        return
    fi
    
    print_warning "Removing LaTeX and ImageMagick dependencies..."
    print_warning "This will remove packages that might be used by other applications!"
    
    if [[ $FORCE_REMOVE == false ]]; then
        echo
        read -p "Are you sure you want to remove dependencies? (y/N): " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            print_info "Keeping dependencies."
            return
        fi
    fi
    
    # Detect package manager and remove dependencies
    if command -v apt-get >/dev/null 2>&1; then
        print_info "Detected Debian/Ubuntu system. Removing with apt..."
        $USE_SUDO apt-get remove --purge -y texlive texlive-* imagemagick 2>/dev/null || print_warning "Some packages could not be removed"
        $USE_SUDO apt-get autoremove -y 2>/dev/null || true
        
    elif command -v dnf >/dev/null 2>&1; then
        print_info "Detected Fedora system. Removing with dnf..."
        $USE_SUDO dnf remove -y texlive ImageMagick 2>/dev/null || print_warning "Some packages could not be removed"
        
    elif command -v yum >/dev/null 2>&1; then
        print_info "Detected RedHat/CentOS system. Removing with yum..."
        $USE_SUDO yum remove -y texlive ImageMagick 2>/dev/null || print_warning "Some packages could not be removed"
        
    elif command -v pacman >/dev/null 2>&1; then
        print_info "Detected Arch Linux system. Removing with pacman..."
        $USE_SUDO pacman -Rs --noconfirm texlive-core imagemagick 2>/dev/null || print_warning "Some packages could not be removed"
        
    elif command -v brew >/dev/null 2>&1; then
        print_info "Detected Homebrew (macOS). Removing with brew..."
        brew uninstall --ignore-dependencies mactex imagemagick 2>/dev/null || print_warning "Some packages could not be removed"
        
    else
        print_warning "Unknown package manager. Please remove these packages manually:"
        echo "  - texlive or mactex (LaTeX distribution)"
        echo "  - imagemagick (image conversion)"
        echo ""
        echo "Common commands:"
        echo "  Debian/Ubuntu: sudo apt remove texlive imagemagick"
        echo "  Fedora: sudo dnf remove texlive ImageMagick"
        echo "  Arch: sudo pacman -Rs texlive-core imagemagick"
        echo "  macOS: brew uninstall mactex imagemagick"
    fi
    
    print_success "Dependencies removal completed."
}

# Main uninstall function
main() {
    # Parse command line arguments
    parse_arguments "$@"
    
    # Show help if requested
    if [[ $SHOW_HELP == true ]]; then
        show_help
        exit 0
    fi
    
    echo
    echo "====================================="
    echo "  LaTeq Linux/macOS Uninstall Script"
    echo "====================================="
    echo
    print_info "This will completely remove LaTeq from your system."
    if [[ $KEEP_DEPENDENCIES == true ]]; then
        print_info "Dependencies (TeX Live, ImageMagick, etc.) will NOT be removed."
    else
        print_warning "Dependencies (TeX Live, ImageMagick, etc.) WILL be removed."
    fi
    echo
    
    # Confirmation prompt
    if [[ $FORCE_REMOVE == false ]]; then
        read -p "Do you want to continue? (y/N): " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            print_info "Uninstallation cancelled."
            exit 0
        fi
    fi
    
    echo
    print_info "Starting LaTeq uninstallation..."
    echo
    
    # Check privileges
    check_privileges
    
    # Find and remove LaTeq installations
    find_lateq_installations
    local was_installed=false
    if remove_lateq_installations; then
        was_installed=true
    fi
    
    # Clean up temporary files
    cleanup_temp_files
    
    # Remove dependencies if requested
    remove_dependencies
    
    # Verify uninstallation
    verify_uninstallation
    
    echo
    if [[ $was_installed == true ]]; then
        print_success "LaTeq has been successfully uninstalled!"
    else
        print_info "LaTeq was not found on this system."
    fi
    
    # Show dependency information
    show_dependency_info
    
    print_info "You may need to restart your shell or terminal to clear the PATH cache."
    echo
}

# Run main function with all arguments
main "$@"
