# LaTeq Windows Uninstall Script
# Completely removes LaTeq from Windows system (but not the dependencies)
# Handles both current PowerShell-only installation and legacy LaTeq.bat installations
# Repository: https://github.com/MathieuMichels/LaTeq
# Usage: powershell -Command "& {Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/MathieuMichels/LaTeq/main/uninstall.ps1' -UseBasicParsing | Invoke-Expression}"

param(
    [string]$InstallPath = "$env:ProgramFiles\LaTeq",
    [switch]$Force,
    [switch]$KeepProfile
)

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
        Write-ColorOutput "This script requires administrator privileges to uninstall system-wide LaTeq." "ERROR"
        Write-ColorOutput "Please run PowerShell as Administrator and try again." "ERROR"
        Write-ColorOutput "" 
        Write-ColorOutput "Right-click on PowerShell and select 'Run as Administrator', then run:" "INFO"
        Write-ColorOutput "powershell -Command `"& {Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/MathieuMichels/LaTeq/main/uninstall.ps1' -UseBasicParsing | Invoke-Expression}`"" "INFO"
        exit 1
    }
    Write-ColorOutput "Administrator privileges confirmed." "SUCCESS"
}

# Remove LaTeq installation directory
function Remove-LaTeqInstallation {
    Write-ColorOutput "Checking for LaTeq installation..." "INFO"
    
    $removed = $false
    
    # Check main installation path
    if (Test-Path $InstallPath) {
        Write-ColorOutput "Found LaTeq installation at: $InstallPath" "INFO"
        
        # List files that will be removed
        $files = Get-ChildItem $InstallPath -Recurse
        if ($files.Count -gt 0) {
            Write-ColorOutput "Files to be removed:" "INFO"
            foreach ($file in $files) {
                Write-Host "  - $($file.FullName)" -ForegroundColor Gray
            }
        }
        
        try {
            Remove-Item $InstallPath -Recurse -Force
            Write-ColorOutput "LaTeq installation directory removed successfully." "SUCCESS"
            $removed = $true
        } catch {
            Write-ColorOutput "Failed to remove installation directory: $($_.Exception.Message)" "ERROR"
        }
    }
    
    # Check for legacy LaTeq.bat in system PATH directories
    $pathDirs = $env:Path -split ';' | Where-Object { $_ -ne '' }
    $systemPaths = @(
        "$env:ProgramFiles\LaTeq",
        "$env:ProgramFiles(x86)\LaTeq", 
        "$env:SystemRoot\System32",
        "$env:SystemRoot",
        "C:\LaTeq",
        "C:\Program Files\LaTeq",
        "C:\Program Files (x86)\LaTeq"
    )
    
    $legacyBatFiles = @()
    
    foreach ($dir in ($pathDirs + $systemPaths | Sort-Object -Unique)) {
        if (Test-Path $dir) {
            $batFile = Join-Path $dir "LaTeq.bat"
            if (Test-Path $batFile) {
                $legacyBatFiles += $batFile
            }
        }
    }
    
    if ($legacyBatFiles.Count -gt 0) {
        Write-ColorOutput "Found legacy LaTeq.bat files:" "WARNING"
        foreach ($batFile in $legacyBatFiles) {
            Write-Host "  - $batFile" -ForegroundColor Yellow
        }
        
        foreach ($batFile in $legacyBatFiles) {
            try {
                Remove-Item $batFile -Force
                Write-ColorOutput "Removed legacy file: $batFile" "SUCCESS"
                $removed = $true
            } catch {
                Write-ColorOutput "Failed to remove $batFile`: $($_.Exception.Message)" "ERROR"
            }
        }
    }
    
    if (-not $removed) {
        Write-ColorOutput "No LaTeq installation found." "INFO"
    }
    
    return $removed
}

# Remove LaTeq from system PATH
function Remove-FromSystemPath {
    Write-ColorOutput "Removing LaTeq from system PATH..." "INFO"
    
    try {
        $currentPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
        $pathEntries = $currentPath -split ';' | Where-Object { $_ -ne '' }
        
        # Remove LaTeq paths
        $laTeqPaths = @(
            $InstallPath,
            "$env:ProgramFiles\LaTeq",
            "$env:ProgramFiles(x86)\LaTeq",
            "C:\LaTeq",
            "C:\Program Files\LaTeq",
            "C:\Program Files (x86)\LaTeq"
        )
        
        $originalCount = $pathEntries.Count
        $pathEntries = $pathEntries | Where-Object { 
            $entry = $_.TrimEnd('\')
            $keep = $true
            foreach ($laTeqPath in $laTeqPaths) {
                if ($entry -eq $laTeqPath.TrimEnd('\')) {
                    $keep = $false
                    Write-ColorOutput "Removing from PATH: $entry" "INFO"
                    break
                }
            }
            $keep
        }
        
        if ($pathEntries.Count -lt $originalCount) {
            $newPath = $pathEntries -join ';'
            [Environment]::SetEnvironmentVariable("Path", $newPath, [EnvironmentVariableTarget]::Machine)
            Write-ColorOutput "LaTeX paths removed from system PATH." "SUCCESS"
        } else {
            Write-ColorOutput "No LaTeq paths found in system PATH." "INFO"
        }
        
    } catch {
        Write-ColorOutput "Failed to modify system PATH: $($_.Exception.Message)" "WARNING"
    }
}

# Remove LaTeq function from PowerShell profile
function Remove-LaTeqFromProfile {
    if ($KeepProfile) {
        Write-ColorOutput "Keeping LaTeq function in PowerShell profile (--KeepProfile specified)." "INFO"
        return
    }
    
    Write-ColorOutput "Checking PowerShell profile for LaTeq function..." "INFO"
    
    $profilePath = $PROFILE
    
    if (-not (Test-Path $profilePath)) {
        Write-ColorOutput "No PowerShell profile found." "INFO"
        return
    }
    
    try {
        $profileContent = Get-Content $profilePath -Raw
        
        if ($profileContent -and $profileContent.Contains("function LaTeq")) {
            Write-ColorOutput "Found LaTeq function in PowerShell profile." "INFO"
            
            # Remove the LaTeq function block
            # This is a simple approach - remove everything from "# LaTeq function" to the closing brace
            $lines = Get-Content $profilePath
            $newLines = @()
            $inLaTeqFunction = $false
            $braceCount = 0
            
            foreach ($line in $lines) {
                if ($line.Trim() -match "^# LaTeq function" -or $line.Trim() -match "^function LaTeq") {
                    $inLaTeqFunction = $true
                    Write-ColorOutput "Removing LaTeq function from profile..." "INFO"
                    continue
                }
                
                if ($inLaTeqFunction) {
                    # Count braces to find the end of the function
                    $openBraces = ($line.ToCharArray() | Where-Object { $_ -eq '{' }).Count
                    $closeBraces = ($line.ToCharArray() | Where-Object { $_ -eq '}' }).Count
                    $braceCount += $openBraces - $closeBraces
                    
                    # If we've closed all braces, we're done with the function
                    if ($braceCount -le 0 -and $line.Trim() -match '}') {
                        $inLaTeqFunction = $false
                        continue
                    }
                    continue
                }
                
                $newLines += $line
            }
            
            # Write back the profile without LaTeq function
            $newLines | Set-Content $profilePath
            Write-ColorOutput "LaTeq function removed from PowerShell profile." "SUCCESS"
            Write-ColorOutput "Note: Restart PowerShell or run '. `$PROFILE' to reload the profile." "INFO"
            
        } else {
            Write-ColorOutput "No LaTeq function found in PowerShell profile." "INFO"
        }
        
    } catch {
        Write-ColorOutput "Failed to modify PowerShell profile: $($_.Exception.Message)" "WARNING"
    }
}

# Clean up any temporary files
function Remove-TempFiles {
    Write-ColorOutput "Cleaning up temporary files..." "INFO"
    
    $tempDirs = @(
        "$env:TEMP\lateq-install",
        "$env:TEMP\lateq-test",
        "$env:TEMP\LaTeq"
    )
    
    foreach ($tempDir in $tempDirs) {
        if (Test-Path $tempDir) {
            try {
                Remove-Item $tempDir -Recurse -Force
                Write-ColorOutput "Removed temporary directory: $tempDir" "SUCCESS"
            } catch {
                Write-ColorOutput "Failed to remove temporary directory $tempDir`: $($_.Exception.Message)" "WARNING"
            }
        }
    }
}

# Verify uninstallation
function Test-Uninstallation {
    Write-ColorOutput "Verifying uninstallation..." "INFO"
    
    $issues = @()
    
    # Check installation path
    if (Test-Path $InstallPath) {
        $issues += "Installation directory still exists: $InstallPath"
    }
    
    # Check for LaTeq.bat files
    $pathDirs = $env:Path -split ';' | Where-Object { $_ -ne '' }
    foreach ($dir in $pathDirs) {
        if (Test-Path $dir) {
            $batFile = Join-Path $dir "LaTeq.bat"
            if (Test-Path $batFile) {
                $issues += "Legacy LaTeq.bat still exists: $batFile"
            }
            $ps1File = Join-Path $dir "LaTeq.ps1"
            if (Test-Path $ps1File) {
                $issues += "LaTeq.ps1 still exists: $ps1File"
            }
        }
    }
    
    # Check PATH
    $currentPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
    if ($currentPath -like "*LaTeq*") {
        $issues += "LaTeq paths may still be in system PATH"
    }
    
    if ($issues.Count -eq 0) {
        Write-ColorOutput "LaTeq successfully uninstalled!" "SUCCESS"
    } else {
        Write-ColorOutput "Uninstallation completed with some issues:" "WARNING"
        foreach ($issue in $issues) {
            Write-ColorOutput "  - $issue" "WARNING"
        }
    }
}

# Show dependency information
function Show-DependencyInfo {
    Write-Host ""
    Write-ColorOutput "Dependencies were NOT removed:" "INFO"
    Write-Host "The following software remains installed (if it was installed):"
    Write-Host "  - MiKTeX or TeX Live (LaTeX distribution)"
    Write-Host "  - ImageMagick (image conversion)"
    Write-Host "  - Ghostscript (PostScript/PDF handling)"
    Write-Host ""
    Write-Host "If you want to remove these dependencies, you can:"
    Write-Host "  - Uninstall MiKTeX through Control Panel or Programs and Features"
    Write-Host "  - Uninstall TeX Live through its own uninstaller"
    Write-Host "  - Uninstall ImageMagick through Control Panel or Programs and Features"
    Write-Host "  - Uninstall Ghostscript through Control Panel or Programs and Features"
    Write-Host "  - Or if installed via Chocolatey: choco uninstall miktex imagemagick ghostscript"
    Write-Host ""
}

# Main uninstall function
function Main {
    Write-Host ""
    Write-Host "====================================="
    Write-Host "  LaTeq Windows Uninstall Script"
    Write-Host "====================================="
    Write-Host ""
    Write-ColorOutput "This will completely remove LaTeq from your system." "INFO"
    Write-ColorOutput "Dependencies (MiKTeX, ImageMagick, etc.) will NOT be removed." "INFO"
    Write-Host ""
    
    if (-not $Force) {
        $confirm = Read-Host "Do you want to continue? (y/N)"
        if ($confirm -notmatch "^[Yy]") {
            Write-ColorOutput "Uninstallation cancelled." "INFO"
            exit 0
        }
    }
    
    Write-Host ""
    Write-ColorOutput "Starting LaTeq uninstallation..." "INFO"
    Write-Host ""
    
    try {
        Assert-Administrator
        
        $wasInstalled = Remove-LaTeqInstallation
        Remove-FromSystemPath
        Remove-LaTeqFromProfile
        Remove-TempFiles
        Test-Uninstallation
        
        Write-Host ""
        if ($wasInstalled) {
            Write-ColorOutput "LaTeq has been successfully uninstalled!" "SUCCESS"
        } else {
            Write-ColorOutput "LaTeq was not found on this system." "INFO"
        }
        
        Show-DependencyInfo
        
    } catch {
        Write-ColorOutput "Uninstallation failed: $($_.Exception.Message)" "ERROR"
        exit 1
    }
}

# Run main function
Main
