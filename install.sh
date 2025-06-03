#!/bin/bash

# LaTeq Installation Script
# Automatically downloads and installs LaTeq system-wide
# Repository: https://github.com/MathieuMichels/LaTeq
# Usage: curl -sSL https://raw.githubusercontent.com/MathieuMichels/LaTeq/main/install.sh | bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://raw.githubusercontent.com/MathieuMichels/LaTeq/main/LaTeq.sh"
INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="LaTeq"
TEMP_DIR="/tmp/lateq-install"

# Print colored output
print_status() {
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

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_warning "Running as root. Installation will proceed directly."
        USE_SUDO=""
    else
        print_status "Running as regular user. Will use sudo for system installation."
        USE_SUDO="sudo"
    fi
}

# Check system dependencies
check_dependencies() {
    print_status "Checking system dependencies..."
    
    local missing_deps=()
    
    # Check for required commands
    if ! command -v wget >/dev/null 2>&1 && ! command -v curl >/dev/null 2>&1; then
        missing_deps+="wget or curl"
    fi
    
    # Check for LaTeX
    if ! command -v pdflatex >/dev/null 2>&1; then
        missing_deps+="texlive"
    fi
    
    # Check for ImageMagick
    if ! command -v convert >/dev/null 2>&1; then
        missing_deps+="imagemagick"
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_warning "Missing dependencies detected: ${missing_deps[*]}"
        echo
        print_status "Installing missing dependencies..."
        
        # Detect package manager and install dependencies
        if command -v apt-get >/dev/null 2>&1; then
            print_status "Detected Debian/Ubuntu system. Installing with apt..."
            $USE_SUDO apt-get update
            
            if [[ " ${missing_deps[*]} " =~ " wget or curl " ]]; then
                $USE_SUDO apt-get install -y wget curl
            fi
            if [[ " ${missing_deps[*]} " =~ " texlive " ]]; then
                $USE_SUDO apt-get install -y texlive
                print_status "For full LaTeX functionality, consider installing: sudo apt install texlive-full"
            fi
            if [[ " ${missing_deps[*]} " =~ " imagemagick " ]]; then
                $USE_SUDO apt-get install -y imagemagick
            fi
            
        elif command -v yum >/dev/null 2>&1; then
            print_status "Detected RedHat/CentOS system. Installing with yum..."
            
            if [[ " ${missing_deps[*]} " =~ " wget or curl " ]]; then
                $USE_SUDO yum install -y wget curl
            fi
            if [[ " ${missing_deps[*]} " =~ " texlive " ]]; then
                $USE_SUDO yum install -y texlive
            fi
            if [[ " ${missing_deps[*]} " =~ " imagemagick " ]]; then
                $USE_SUDO yum install -y ImageMagick
            fi
            
        elif command -v pacman >/dev/null 2>&1; then
            print_status "Detected Arch Linux system. Installing with pacman..."
            
            if [[ " ${missing_deps[*]} " =~ " wget or curl " ]]; then
                $USE_SUDO pacman -S --noconfirm wget curl
            fi
            if [[ " ${missing_deps[*]} " =~ " texlive " ]]; then
                $USE_SUDO pacman -S --noconfirm texlive-core
            fi
            if [[ " ${missing_deps[*]} " =~ " imagemagick " ]]; then
                $USE_SUDO pacman -S --noconfirm imagemagick
            fi
            
        else
            print_error "Unsupported package manager. Please install the following packages manually:"
            echo "  - wget or curl (for downloading)"
            echo "  - texlive (for LaTeX compilation)"
            echo "  - imagemagick (for image conversion)"
            echo ""
            echo "On Debian/Ubuntu: sudo apt install wget texlive imagemagick"
            echo "On RedHat/CentOS: sudo yum install wget texlive ImageMagick"
            echo "On Arch Linux: sudo pacman -S wget texlive-core imagemagick"
            exit 1
        fi
        
        print_success "Dependencies installed successfully!"
    else
        print_success "All dependencies are already installed!"
    fi
}

# Download LaTeq script
download_script() {
    print_status "Creating temporary directory..."
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"
    
    print_status "Downloading LaTeq script from GitHub..."
    
    # Try curl first, then wget, without cache
    if command -v curl >/dev/null 2>&1; then
        curl -sSL "$REPO_URL" -o LaTeq.sh -H 'Cache-Control: no-cache, no-store'
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$REPO_URL" -O LaTeq.sh --no-cache
    else
        print_error "Neither curl nor wget found. Cannot download script."
        exit 1
    fi
    
    # Verify download
    if [ ! -f "LaTeq.sh" ] || [ ! -s "LaTeq.sh" ]; then
        print_error "Failed to download LaTeq script."
        exit 1
    fi
    
    # Check if it's a valid shell script
    if ! head -1 LaTeq.sh | grep -q "#!/bin/bash"; then
        print_error "Downloaded file doesn't appear to be a valid bash script."
        exit 1
    fi
    
    print_success "LaTeq script downloaded successfully!"
}

# Install script system-wide
install_script() {
    print_status "Installing LaTeq to $INSTALL_DIR/$SCRIPT_NAME..."
    
    # Make script executable
    chmod +x LaTeq.sh
    
    # Copy to system directory
    $USE_SUDO cp LaTeq.sh "$INSTALL_DIR/$SCRIPT_NAME"
    
    # Verify installation
    if [ -f "$INSTALL_DIR/$SCRIPT_NAME" ]; then
        print_success "LaTeq installed successfully to $INSTALL_DIR/$SCRIPT_NAME"
    else
        print_error "Installation failed. Could not copy script to $INSTALL_DIR"
        exit 1
    fi
}

# Test installation
test_installation() {
    print_status "Testing LaTeq installation..."
    
    # Check if LaTeq command is available
    if command -v LaTeq >/dev/null 2>&1; then
        print_success "LaTeq command is available in PATH!"
        
        # Test with a simple equation
        print_status "Testing with a simple equation..."
        
        # Create test directory
        TEST_DIR="/tmp/lateq-test"
        mkdir -p "$TEST_DIR"
        cd "$TEST_DIR"
        
        # Run LaTeq with a simple equation (PDF output to avoid GUI dependencies)
        if LaTeq "x^2 + 1" >/dev/null 2>&1; then
            print_success "LaTeq test completed successfully!"
            
            # Show generated file
            if [ -f "equation_"*.pdf ]; then
                GENERATED_FILE=$(ls equation_*.pdf | head -1)
                print_success "Generated test file: $PWD/$GENERATED_FILE"
            fi
        else
            print_warning "LaTeq test failed, but installation appears correct."
            print_status "This might be due to missing LaTeX packages or display issues."
        fi
        
        # Clean up test
        cd /
        rm -rf "$TEST_DIR"
        
    else
        print_error "LaTeq command not found in PATH after installation."
        print_status "You may need to restart your shell or run: export PATH=\"$INSTALL_DIR:\$PATH\""
        exit 1
    fi
}

# Clean up temporary files
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        print_status "Cleaning up temporary files..."
        rm -rf "$TEMP_DIR"
    fi
}

# Main installation function
main() {
    echo
    echo "=================================="
    echo "  LaTeq Automatic Installation"
    echo "=================================="
    echo
    print_status "Starting LaTeq installation..."
    echo
    
    # Trap cleanup on exit
    trap cleanup EXIT
    
    # Run installation steps
    check_root
    check_dependencies
    download_script
    install_script
    test_installation
    
    echo
    print_success "LaTeq installation completed successfully!"
    echo
    echo "Usage examples:"
    echo "  LaTeq \"x^2 + 1\"                    # Generate PDF"
    echo "  LaTeq \"E = mc^2\" --jpeg             # Generate JPEG"
    echo "  LaTeq \"\\int_0^1 x dx\" --png        # Generate PNG"
    echo
    echo "For more information, visit: https://github.com/MathieuMichels/LaTeq"
    echo
}

# Run main function
main "$@"
