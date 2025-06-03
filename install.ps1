# LaTeq Windows Installation Script
# Automatically downloads and installs LaTeq system-wide on Windows
# Creates a PowerShell function for easy usage
# Repository: https://github.com/MathieuMichels/LaTeq
# Usage: powershell -Command "& {Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/MathieuMichels/LaTeq/main/install.ps1' -UseBasicParsing | Invoke-Expression}"

param(
    [string]$InstallPath = "$env:ProgramFiles\LaTeq",
    [switch]$Force
)

# Configuration
$REPO_BASE_URL = "https://raw.githubusercontent.com/MathieuMichels/LaTeq/main"
$SCRIPT_PS1_URL = "$REPO_BASE_URL/LaTeq.ps1"
$TEMP_DIR = "$env:TEMP\lateq-install"

# Colors for output (Windows PowerShell)
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Type = "INFO"
    )
    
    switch ($Type) {
        "INFO" { Write-Host "[INFO] $Message" -ForegroundColor Blue }
        "SUCCESS" { Write-Host "[SUCCESS] $Message" -ForegroundColor Green }
        "WARNING" { Write-Host "[WARNING] $Message" -ForegroundColor Yellow }
        "ERROR" { Write-Host "[ERROR] $Message" -ForegroundColor Red }
        default { Write-Host $Message }
    }
}

# Check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Check administrator privileges
function Assert-Administrator {
    if (-not (Test-Administrator)) {
        Write-ColorOutput "This script requires administrator privileges to install system-wide." "ERROR"
        Write-ColorOutput "Please run PowerShell as Administrator and try again." "ERROR"
        Write-ColorOutput "" 
        Write-ColorOutput "Right-click on PowerShell and select 'Run as Administrator', then run:" "INFO"
        Write-ColorOutput "powershell -Command `"& {Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/MathieuMichels/LaTeq/main/install.ps1' -UseBasicParsing | Invoke-Expression}`"" "INFO"
        exit 1
    }
    Write-ColorOutput "Administrator privileges confirmed." "SUCCESS"
}

# Check system dependencies
function Test-Dependencies {
    Write-ColorOutput "Checking system dependencies..." "INFO"
    
    $missingDeps = @()
    $recommendedDeps = @()
    $warningMsgs = @()
    
    # Check for PowerShell (should always be available)
    if (-not (Get-Command "powershell" -ErrorAction SilentlyContinue)) {
        $missingDeps += "PowerShell"
    }
    
    # Check for pdflatex (LaTeX)
    if (-not (Get-Command "pdflatex" -ErrorAction SilentlyContinue)) {
        $recommendedDeps += "pdflatex (MiKTeX or TeX Live)"
    }
    
    # Check for ImageMagick
    $magickCmd = Get-Command "magick" -ErrorAction SilentlyContinue
    $convertCmd = Get-Command "convert" -ErrorAction SilentlyContinue
    
    if (-not $magickCmd -and -not $convertCmd) {
        $recommendedDeps += "ImageMagick (for PNG/JPEG conversion)"
    } else {
        # Check for Ghostscript (required for ImageMagick PDF conversion)
        $gsCmd = Get-Command "gswin64c" -ErrorAction SilentlyContinue
        if (-not $gsCmd) {
            $gsCmd = Get-Command "gswin32c" -ErrorAction SilentlyContinue
        }
        if (-not $gsCmd) {
            $gsCmd = Get-Command "gs" -ErrorAction SilentlyContinue
        }
        
        if (-not $gsCmd) {
            $warningMsgs += "Ghostscript not found - PNG/JPEG conversion may fail"
        }
    }
    
    if ($missingDeps.Count -gt 0) {
        Write-ColorOutput "Missing required dependencies: $($missingDeps -join ', ')" "ERROR"
        exit 1
    }
    
    if ($recommendedDeps.Count -gt 0 -or $warningMsgs.Count -gt 0) {
        if ($recommendedDeps.Count -gt 0) {
            Write-ColorOutput "Missing recommended dependencies: $($recommendedDeps -join ', ')" "WARNING"
        }
        if ($warningMsgs.Count -gt 0) {
            Write-ColorOutput "Warnings: $($warningMsgs -join ', ')" "WARNING"
        }
        Write-ColorOutput ""
        Write-ColorOutput "LaTeq will be installed, but you should install these for full functionality:" "INFO"
        Write-ColorOutput "  - MiKTeX: https://miktex.org/download" "INFO"
        Write-ColorOutput "  - TeX Live: https://www.tug.org/texlive/windows.html" "INFO"
        Write-ColorOutput "  - ImageMagick: https://imagemagick.org/script/download.php#windows" "INFO"
        Write-ColorOutput "  - Ghostscript: https://www.ghostscript.com/download/gsdnld.html" "INFO"
        Write-ColorOutput "  - Or use Chocolatey: choco install miktex imagemagick ghostscript" "INFO"
        Write-ColorOutput ""
        
        $continue = Read-Host "Continue installation anyway? (y/N)"
        if ($continue -notmatch "^[Yy]") {
            Write-ColorOutput "Installation cancelled." "INFO"
            exit 0
        }
    } else {
        Write-ColorOutput "All dependencies are available!" "SUCCESS"
    }
}

# Download LaTeq scripts
function Get-LaTeqScripts {
    Write-ColorOutput "Creating temporary directory..." "INFO"
    if (Test-Path $TEMP_DIR) {
        Remove-Item $TEMP_DIR -Recurse -Force
    }
    New-Item -ItemType Directory -Path $TEMP_DIR -Force | Out-Null
      Write-ColorOutput "Downloading LaTeq scripts from GitHub..." "INFO"
    
    try {
        # Download PowerShell script
        Write-ColorOutput "Downloading LaTeq.ps1..." "INFO"
        Invoke-WebRequest -Uri $SCRIPT_PS1_URL -OutFile "$TEMP_DIR\LaTeq.ps1" -UseBasicParsing
        
    } catch {
        Write-ColorOutput "Failed to download LaTeq scripts: $($_.Exception.Message)" "ERROR"
        exit 1
    }
    
    # Verify downloads
    if (-not (Test-Path "$TEMP_DIR\LaTeq.ps1")) {
        Write-ColorOutput "Failed to download LaTeq scripts." "ERROR"
        exit 1
    }
    
    # Verify PowerShell script content
    $ps1Content = Get-Content "$TEMP_DIR\LaTeq.ps1" -Raw
    if (-not $ps1Content.Contains("LaTeq for Windows PowerShell")) {
        Write-ColorOutput "Downloaded PowerShell script doesn't appear to be valid." "ERROR"
        exit 1
    }
    
    Write-ColorOutput "LaTeq scripts downloaded successfully!" "SUCCESS"
}

# Install scripts system-wide
function Install-LaTeqScripts {
    Write-ColorOutput "Installing LaTeq to $InstallPath..." "INFO"
    
    # Create installation directory
    if (-not (Test-Path $InstallPath)) {
        New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
    }
      try {
        # Copy scripts to installation directory
        Copy-Item "$TEMP_DIR\LaTeq.ps1" "$InstallPath\LaTeq.ps1" -Force
        
        Write-ColorOutput "Scripts copied to $InstallPath" "SUCCESS"
        
    } catch {
        Write-ColorOutput "Failed to copy scripts: $($_.Exception.Message)" "ERROR"
        exit 1
    }
}

# Add installation path to system PATH
function Add-ToSystemPath {
    Write-ColorOutput "Adding $InstallPath to system PATH..." "INFO"
    
    # Get current system PATH
    $currentPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
    
    # Check if already in PATH
    if ($currentPath -split ";" | Where-Object { $_.Trim() -eq $InstallPath }) {
        Write-ColorOutput "Installation path already in system PATH." "INFO"
        return
    }
    
    try {
        # Add to system PATH
        $newPath = $currentPath + ";" + $InstallPath
        [Environment]::SetEnvironmentVariable("Path", $newPath, [EnvironmentVariableTarget]::Machine)
        
        # Also add to current session PATH
        $env:Path += ";$InstallPath"
        
        Write-ColorOutput "Installation path added to system PATH." "SUCCESS"
        
    } catch {
        Write-ColorOutput "Failed to add to system PATH: $($_.Exception.Message)" "WARNING"
        Write-ColorOutput "You may need to add $InstallPath to your PATH manually." "WARNING"
    }
}

# Set PowerShell execution policy if needed
function Set-ExecutionPolicyIfNeeded {
    $currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
    
    if ($currentPolicy -eq "Restricted") {
        Write-ColorOutput "Setting PowerShell execution policy to RemoteSigned for current user..." "INFO"
        try {
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
            Write-ColorOutput "Execution policy updated." "SUCCESS"
        } catch {
            Write-ColorOutput "Failed to set execution policy: $($_.Exception.Message)" "WARNING"
            Write-ColorOutput "You may need to run: Set-ExecutionPolicy RemoteSigned -Scope CurrentUser" "WARNING"
        }
    }
}

# Create PowerShell profile function for easier LaTeq usage
function Add-LaTeqToProfile {
    Write-ColorOutput "Adding LaTeq function to PowerShell profile..." "INFO"
    
    # Get PowerShell profile path
    $profilePath = $PROFILE
    
    # Create profile directory if it doesn't exist
    if (-not (Test-Path (Split-Path $profilePath))) {
        New-Item -ItemType Directory -Path (Split-Path $profilePath) -Force | Out-Null
    }
    
    # Define the LaTeq function
    $laTeqFunction = @"

# LaTeq function for easy equation compilation
function LaTeq {
    param(
        [Parameter(Mandatory=`$true, Position=0)]
        [string]`$Equation,
        [switch]`$png,
        [switch]`$jpeg,
        [string]`$output,
        [string]`$filename,
        [string]`$packages
    )
    
    `$laTeqScript = "$InstallPath\LaTeq.ps1"
    if (-not (Test-Path `$laTeqScript)) {
        Write-Host "Error: LaTeq.ps1 not found at `$laTeqScript"
        return
    }
    
    `$args = @(`$Equation)
    if (`$png) { `$args += "--png" }
    if (`$jpeg) { `$args += "--jpeg" }
    if (`$output) { `$args += "--output"; `$args += `$output }
    if (`$filename) { `$args += "--filename"; `$args += `$filename }
    if (`$packages) { `$args += "--packages"; `$args += `$packages }
    
    & powershell.exe -ExecutionPolicy Bypass -File `$laTeqScript @args
}
"@
    
    try {
        # Check if LaTeq function already exists in profile
        if (Test-Path $profilePath) {
            $profileContent = Get-Content $profilePath -Raw
            if ($profileContent -and $profileContent.Contains("function LaTeq")) {
                Write-ColorOutput "LaTeq function already exists in PowerShell profile." "INFO"
                return
            }
        }
        
        # Add function to profile
        Add-Content -Path $profilePath -Value $laTeqFunction
        Write-ColorOutput "LaTeq function added to PowerShell profile." "SUCCESS"
        Write-ColorOutput "You can now use 'LaTeq `"equation`"' directly in PowerShell!" "SUCCESS"
        Write-ColorOutput "Note: Restart PowerShell or run '. `$PROFILE' to load the function." "INFO"
        
    } catch {
        Write-ColorOutput "Failed to add LaTeq function to profile: $($_.Exception.Message)" "WARNING"
        Write-ColorOutput "You can manually add the function or use the full path to LaTeq.ps1" "WARNING"
    }
}

# Test installation
function Test-Installation {
    Write-ColorOutput "Testing LaTeq installation..." "INFO"
    
    # Refresh PATH in current session
    $env:Path = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine) + ";" + [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
      # Test if LaTeq command is available
    $laTeqPath = "$InstallPath\LaTeq.ps1"
    if (Test-Path $laTeqPath) {
        Write-ColorOutput "LaTeq.ps1 found at $laTeqPath" "SUCCESS"
        
        # Test with a simple equation
        Write-ColorOutput "Testing with a simple equation..." "INFO"
        
        $testDir = "$env:TEMP\lateq-test"
        if (Test-Path $testDir) {
            Remove-Item $testDir -Recurse -Force
        }
        New-Item -ItemType Directory -Path $testDir -Force | Out-Null
        
        Push-Location $testDir
        try {
            # Test LaTeq (will show error menu if pdflatex not available, which is expected)
            powershell.exe -ExecutionPolicy Bypass -File $laTeqPath "x^2 + 1" 2>&1 | Out-Null
            Write-ColorOutput "LaTeq test executed (check above for any dependency warnings)." "SUCCESS"
        } catch {
            Write-ColorOutput "LaTeq test encountered issues, but installation appears correct." "WARNING"
            Write-ColorOutput "This might be due to missing LaTeX packages." "INFO"
        } finally {
            Pop-Location
            Remove-Item $testDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        
    } else {
        Write-ColorOutput "LaTeq.ps1 not found after installation." "ERROR"
        exit 1
    }
}

# Clean up temporary files
function Remove-TempFiles {
    if (Test-Path $TEMP_DIR) {
        Write-ColorOutput "Cleaning up temporary files..." "INFO"
        Remove-Item $TEMP_DIR -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Main installation function
function Main {
    Write-Host ""
    Write-Host "======================================="
    Write-Host "  LaTeq Windows Automatic Installation"
    Write-Host "======================================="
    Write-Host ""
    Write-ColorOutput "Starting LaTeq installation..." "INFO"
    Write-Host ""
    
    try {        # Run installation steps
        Assert-Administrator
        Test-Dependencies
        Get-LaTeqScripts
        Install-LaTeqScripts
        Add-ToSystemPath
        Set-ExecutionPolicyIfNeeded
        Add-LaTeqToProfile
        Test-Installation        Write-Host ""
        Write-ColorOutput "LaTeq installation completed successfully!" "SUCCESS"
        Write-Host ""
        Write-Host "Usage examples:"
        Write-Host "  LaTeq `"x^2 + 1`"                                    # Generate PDF (after profile reload)"
        Write-Host "  LaTeq `"E = mc^2`" -jpeg                             # Generate JPEG (after profile reload)"
        Write-Host "  powershell LaTeq.ps1 `"x^2 + 1`"                    # Direct usage"
        Write-Host "  powershell LaTeq.ps1 `"E = mc^2`" --jpeg             # Direct usage with JPEG"
        Write-Host ""
        Write-ColorOutput "To use the simplified 'LaTeq' command, restart PowerShell or run: . `$PROFILE" "INFO"
        Write-ColorOutput "LaTeq.ps1 is located at: $InstallPath\LaTeq.ps1" "INFO"
        Write-Host ""
        Write-Host "For more information, visit: https://github.com/MathieuMichels/LaTeq"
        Write-Host ""
        
    } catch {
        Write-ColorOutput "Installation failed: $($_.Exception.Message)" "ERROR"
        exit 1
    } finally {
        Remove-TempFiles
    }
}

# Run main function
Main
