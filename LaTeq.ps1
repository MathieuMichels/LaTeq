# LaTeq for Windows PowerShell
# Script to compile a LaTeX equation to standalone PDF, PNG, or JPEG
# Usage: LaTeq.ps1 "equation" [-png] [-jpeg] [-output "path"] [-filename "name"] [-packages "pkg1,pkg2,pkg3"]
# Example: .\LaTeq.ps1 "3x+1"
# Example: .\LaTeq.ps1 "3x+1" -png
# Example: .\LaTeq.ps1 "3x+1" -jpeg -output "$env:USERPROFILE\Documents"
# Example: .\LaTeq.ps1 "3x+1" -png -output "$env:USERPROFILE\Documents" -filename "my_equation"
# Example: .\LaTeq.ps1 "\tikz \draw (0,0) circle (1cm);" -packages "tikz"
# Example: .\LaTeq.ps1 "\chemfig{H-C(-[2]H)(-[6]H)-H}" -packages "chemfig,xcolor"

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Equation,
    
    [switch]$png,
    [switch]$jpeg,
    
    [string]$output = $env:TEMP + "\LaTeq",
    [string]$filename = "",
    [string]$packages = ""
)

# Show usage if no equation provided
if (-not $Equation) {
    Write-Host "Usage: LaTeq.ps1 `"equation`" [-png] [-jpeg] [-output `"path`"] [-filename `"name`"] [-packages `"pkg1,pkg2,pkg3`"]"
    Write-Host "Example: .\LaTeq.ps1 `"3x+1`""
    Write-Host "Example: .\LaTeq.ps1 `"3x+1`" -png"
    Write-Host "Example: .\LaTeq.ps1 `"3x+1`" -jpeg -output `"`$env:USERPROFILE\Documents`""
    Write-Host "Example: .\LaTeq.ps1 `"3x+1`" -png -output `"`$env:USERPROFILE\Documents`" -filename `"my_equation`""
    Write-Host "Example: .\LaTeq.ps1 `"\tikz \draw (0,0) circle (1cm);`" -packages `"tikz`""
    Write-Host "Example: .\LaTeq.ps1 `"\chemfig{H-C(-[2]H)(-[6]H)-H}`" -packages `"chemfig,xcolor`""
    Write-Host "By default, files are saved in the current directory"
    Write-Host "Default packages: amsmath, amssymb, amsfonts"
    exit 1
}

# Setup variables
$EXPORT_PNG = $png
$EXPORT_JPEG = $jpeg
$TEMP_DIR = "$env:TEMP\LaTeq"
$FINAL_OUTPUT_DIR = if ($output -eq "$env:TEMP\LaTeq") { Get-Location } else { $output }

# Create directories
if (-not (Test-Path $TEMP_DIR)) {
    New-Item -ItemType Directory -Path $TEMP_DIR -Force | Out-Null
}

if (-not (Test-Path $FINAL_OUTPUT_DIR)) {
    New-Item -ItemType Directory -Path $FINAL_OUTPUT_DIR -Force | Out-Null
}

# Check write permissions
try {
    $testFile = Join-Path $FINAL_OUTPUT_DIR "test_write.tmp"
    New-Item -ItemType File -Path $testFile -Force | Out-Null
    Remove-Item $testFile -Force
} catch {
    Write-Host "Error: Cannot write to $FINAL_OUTPUT_DIR"
    exit 1
}

# Get absolute paths
$TEMP_DIR_ABS = (Resolve-Path $TEMP_DIR).Path
$FINAL_OUTPUT_DIR_ABS = (Resolve-Path $FINAL_OUTPUT_DIR).Path

# Determine filename
if ($filename -eq "") {
    $FILENAME = "equation_$(Get-Date -UFormat %s)"
} else {
    $FILENAME = $filename
}

# File paths
$TEX_FILE = Join-Path $TEMP_DIR "$FILENAME.tex"
$PDF_FILE = Join-Path $TEMP_DIR "$FILENAME.pdf"
$PNG_FILE = Join-Path $TEMP_DIR "$FILENAME.png"
$JPEG_FILE = Join-Path $TEMP_DIR "$FILENAME.jpg"

$FINAL_PDF_FILE = Join-Path $FINAL_OUTPUT_DIR_ABS "$FILENAME.pdf"
$FINAL_PNG_FILE = Join-Path $FINAL_OUTPUT_DIR_ABS "$FILENAME.png"
$FINAL_JPEG_FILE = Join-Path $FINAL_OUTPUT_DIR_ABS "$FILENAME.jpg"

# Build LaTeX document content
$latexContent = @"
\documentclass[border=10pt]{standalone}
\usepackage{amsmath}
\usepackage{amssymb}
\usepackage{amsfonts}
"@

# Add custom packages if specified
if ($packages -ne "") {
    Write-Host "Additional packages: $packages"
    $packageArray = $packages -split ","
    foreach ($pkg in $packageArray) {
        $pkg = $pkg.Trim()
        if ($pkg -ne "") {
            $latexContent += "`n\usepackage{$pkg}"
        }
    }
}

# Complete the LaTeX document
$latexContent += @"

\begin{document}
`$\displaystyle $Equation`$
\end{document}
"@

# Write LaTeX file
$latexContent | Out-File -FilePath $TEX_FILE -Encoding UTF8
Write-Host "LaTeX file created: $TEX_FILE"
Write-Host "Compiling equation: $Equation"
if ($FINAL_OUTPUT_DIR_ABS -ne (Get-Location).Path) {
    Write-Host "Final output directory: $FINAL_OUTPUT_DIR_ABS"
}
if ($packages -ne "") {
    Write-Host "Using additional packages: $packages"
}

# Change to temp directory and compile
Push-Location $TEMP_DIR
$pdflatexResult = & pdflatex -interaction=nonstopmode "$FILENAME.tex" 2>&1
Pop-Location

if ($LASTEXITCODE -eq 0) {
    Write-Host "Compilation successful!"
    
    # Clean up auxiliary files
    $auxFile = Join-Path $TEMP_DIR "$FILENAME.aux"
    $logFile = Join-Path $TEMP_DIR "$FILENAME.log"
    if (Test-Path $auxFile) { Remove-Item $auxFile -Force }
    if (Test-Path $logFile) { Remove-Item $logFile -Force }
    if (Test-Path $TEX_FILE) { Remove-Item $TEX_FILE -Force }
    
    if ($EXPORT_PNG -or $EXPORT_JPEG) {
        # Check if ImageMagick is available
        $convertCmd = Get-Command "magick" -ErrorAction SilentlyContinue
        if (-not $convertCmd) {
            $convertCmd = Get-Command "convert" -ErrorAction SilentlyContinue
        }
        
        if ($convertCmd) {
            if ($EXPORT_PNG) {
                Write-Host "Converting to PNG..."
                $convertArgs = @("-density", "300", $PDF_FILE, "-quality", "90", $PNG_FILE)
                & $convertCmd.Source $convertArgs
                
                if ($LASTEXITCODE -eq 0) {
                    if ($TEMP_DIR_ABS -ne $FINAL_OUTPUT_DIR_ABS) {
                        Copy-Item $PNG_FILE $FINAL_PNG_FILE -Force
                        $OUTPUT_FILE = $FINAL_PNG_FILE
                    } else {
                        $OUTPUT_FILE = $PNG_FILE
                    }
                    $FORMAT = "PNG"
                } else {
                    Write-Host "Error during PNG conversion!"
                    if (Test-Path $PDF_FILE) { Remove-Item $PDF_FILE -Force }
                    exit 1
                }
            } else {
                Write-Host "Converting to JPEG..."
                $convertArgs = @("-density", "300", $PDF_FILE, "-background", "white", "-flatten", "-quality", "90", $JPEG_FILE)
                & $convertCmd.Source $convertArgs
                
                if ($LASTEXITCODE -eq 0) {
                    if ($TEMP_DIR_ABS -ne $FINAL_OUTPUT_DIR_ABS) {
                        Copy-Item $JPEG_FILE $FINAL_JPEG_FILE -Force
                        $OUTPUT_FILE = $FINAL_JPEG_FILE
                    } else {
                        $OUTPUT_FILE = $JPEG_FILE
                    }
                    $FORMAT = "JPEG"
                } else {
                    Write-Host "Error during JPEG conversion!"
                    if (Test-Path $PDF_FILE) { Remove-Item $PDF_FILE -Force }
                    exit 1
                }
            }
            
            Write-Host "$FORMAT conversion successful!"
            Write-Host "Generated file: $OUTPUT_FILE"
            
            # Clean up temporary PDF
            if (Test-Path $PDF_FILE) { Remove-Item $PDF_FILE -Force }
            
            # Open the file
            try {
                Start-Process $OUTPUT_FILE
            } catch {
                Write-Host "Generated file: $OUTPUT_FILE"
                Write-Host "Could not open file automatically. Please open manually."
            }
        } else {
            Write-Host "ImageMagick not found. Required for image conversion."
            Write-Host "Please install ImageMagick from: https://imagemagick.org/script/download.php#windows"
            Write-Host "Or install via Chocolatey: choco install imagemagick"
            if (Test-Path $PDF_FILE) { Remove-Item $PDF_FILE -Force }
            exit 1
        }
    } else {
        # Handle PDF output
        if ($TEMP_DIR_ABS -ne $FINAL_OUTPUT_DIR_ABS) {
            Copy-Item $PDF_FILE $FINAL_PDF_FILE -Force
            $OUTPUT_FILE = $FINAL_PDF_FILE
        } else {
            $OUTPUT_FILE = $PDF_FILE
        }
        
        Write-Host "PDF generated: $OUTPUT_FILE"
        
        # Open the PDF
        try {
            Start-Process $OUTPUT_FILE
        } catch {
            Write-Host "Could not open PDF automatically. Please open manually."
        }
    }
} else {
    Write-Host "Compilation error!"
    Write-Host "Check your equation syntax and package dependencies."
    Write-Host ""
    
    # Interactive error handling
    do {
        Write-Host "What would you like to do?"
        Write-Host "1) Show LaTeX log"
        Write-Host "2) Show generated .tex file"
        Write-Host "3) Save log file to disk"
        Write-Host "4) Save .tex file to disk"
        Write-Host "5) Show both log and .tex file"
        Write-Host "6) Clean up and exit"
        Write-Host ""
        $choice = Read-Host "Choose an option (1-6)"
        
        switch ($choice) {
            "1" {
                Write-Host ""
                Write-Host "LaTeX log:"
                Write-Host "===================="
                $logPath = Join-Path $TEMP_DIR "$FILENAME.log"
                if (Test-Path $logPath) {
                    Get-Content $logPath
                } else {
                    Write-Host "Log file not found"
                }
                Write-Host "===================="
                Write-Host ""
            }
            "2" {
                Write-Host ""
                Write-Host "Generated .tex file:"
                Write-Host "===================="
                if (Test-Path $TEX_FILE) {
                    Get-Content $TEX_FILE
                } else {
                    Write-Host "TeX file not found"
                }
                Write-Host "===================="
                Write-Host ""
            }
            "3" {
                $logPath = Join-Path $TEMP_DIR "$FILENAME.log"
                if (Test-Path $logPath) {
                    $savedLog = Join-Path $FINAL_OUTPUT_DIR_ABS "lateq_error_$(Get-Date -UFormat %s).log"
                    Copy-Item $logPath $savedLog -Force
                    Write-Host "Log saved to: $savedLog"
                } else {
                    Write-Host "No log file to save"
                }
                Write-Host ""
            }
            "4" {
                if (Test-Path $TEX_FILE) {
                    $savedTex = Join-Path $FINAL_OUTPUT_DIR_ABS "lateq_error_$(Get-Date -UFormat %s).tex"
                    Copy-Item $TEX_FILE $savedTex -Force
                    Write-Host "TeX file saved to: $savedTex"
                } else {
                    Write-Host "No TeX file to save"
                }
                Write-Host ""
            }
            "5" {
                Write-Host ""
                Write-Host "Generated .tex file:"
                Write-Host "===================="
                if (Test-Path $TEX_FILE) {
                    Get-Content $TEX_FILE
                } else {
                    Write-Host "TeX file not found"
                }
                Write-Host "===================="
                Write-Host ""
                Write-Host "LaTeX log:"
                Write-Host "===================="
                $logPath = Join-Path $TEMP_DIR "$FILENAME.log"
                if (Test-Path $logPath) {
                    Get-Content $logPath
                } else {
                    Write-Host "Log file not found"
                }
                Write-Host "===================="
                Write-Host ""
            }
            "6" {
                Write-Host "Cleaning up and exiting..."
                break
            }
            default {
                Write-Host "Invalid option. Please choose 1-6."
                Write-Host ""
            }
        }
    } while ($choice -ne "6")
    
    # Clean up temporary files
    if (Test-Path $TEX_FILE) { Remove-Item $TEX_FILE -Force }
    $logPath = Join-Path $TEMP_DIR "$FILENAME.log"
    if (Test-Path $logPath) { Remove-Item $logPath -Force }
    $auxPath = Join-Path $TEMP_DIR "$FILENAME.aux"
    if (Test-Path $auxPath) { Remove-Item $auxPath -Force }
    
    exit 1
}
