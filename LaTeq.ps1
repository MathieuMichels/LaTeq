# LaTeq for Windows PowerShell
# Script to compile a LaTeX equation to standalone PDF, PNG, or JPEG
# Usage: LaTeq "equation" [--png|--jpeg] [--output "path"] [--filename "name"] [--packages "pkg1,pkg2,pkg3"] [--dpi "value"]
# Example: LaTeq "3x+1"
# Example: LaTeq "3x+1" --png
# Example: LaTeq "3x+1" --jpeg --output "$env:USERPROFILE\Documents"
# Example: LaTeq "3x+1" --png --output "$env:USERPROFILE\Documents" --filename "my_equation"
# Example: LaTeq "3x+1" --png --dpi "300"
# Example: LaTeq "\tikz \draw (0,0) circle (1cm);" --packages "tikz"
# Example: LaTeq "\chemfig{H-C(-[2]H)(-[6]H)-H}" --packages "chemfig,xcolor"

# Manual argument parsing to support --parameter syntax like bash version
if ($args.Count -eq 0) {
    Write-Host "Usage: LaTeq `"equation`" [--png|--jpeg] [--output `"path`"] [--filename `"name`"] [--packages `"pkg1,pkg2,pkg3`"] [--dpi `"value`"]"
    Write-Host "Example: LaTeq `"3x+1`""
    Write-Host "Example: LaTeq `"3x+1`" --png"
    Write-Host "Example: LaTeq `"3x+1`" --jpeg --output `"`$env:USERPROFILE\Documents`""
    Write-Host "Example: LaTeq `"3x+1`" --png --output `"`$env:USERPROFILE\Documents`" --filename `"my_equation`""
    Write-Host "Example: LaTeq `"3x+1`" --png --dpi `"300`""
    Write-Host "Example: LaTeq `"\tikz \draw (0,0) circle (1cm);`" --packages `"tikz`""
    Write-Host "Example: LaTeq `"\chemfig{H-C(-[2]H)(-[6]H)-H}`" --packages `"chemfig,xcolor`""
    Write-Host "By default, files are saved in the current directory"
    Write-Host "Default packages: amsmath, amssymb, amsfonts"
    Write-Host "Default DPI: 450"
    exit 1
}

# Initialize variables
$Equation = $args[0]
$EXPORT_PNG = $false
$EXPORT_JPEG = $false
$output = "$env:TEMP\LaTeq"  # Default to temp/LaTeq directory
$filename = ""
$packages = ""
$dpi = 450  # Default DPI value

# Parse arguments manually
$i = 1
while ($i -lt $args.Count) {
    switch ($args[$i]) {
        "--png" {
            $EXPORT_PNG = $true
            $i++
        }
        "--jpeg" {
            $EXPORT_JPEG = $true
            $i++
        }
        "--output" {
            if ($i + 1 -lt $args.Count) {
                $output = $args[$i + 1]
                $i += 2
            } else {
                Write-Host "Error: --output requires a path argument"
                exit 1
            }
        }
        "--filename" {
            if ($i + 1 -lt $args.Count) {
                $filename = $args[$i + 1]
                $i += 2
            } else {
                Write-Host "Error: --filename requires a name argument"
                exit 1
            }
        }        "--packages" {
            if ($i + 1 -lt $args.Count) {
                $packages = $args[$i + 1]
                $i += 2
            } else {
                Write-Host "Error: --packages requires a package list argument"
                exit 1
            }
        }
        "--dpi" {
            if ($i + 1 -lt $args.Count) {
                $dpi = [int]$args[$i + 1]
                $i += 2
            } else {
                Write-Host "Error: --dpi requires a numeric value argument"
                exit 1
            }
        }
        default {
            Write-Host "Unknown option: $($args[$i])"
            exit 1
        }
    }
}

# Show usage if no equation provided
if (-not $Equation) {
    Write-Host "Usage: LaTeq.ps1 `"equation`" [--png|--jpeg] [--output `"path`"] [--filename `"name`"] [--packages `"pkg1,pkg2,pkg3`"] [--dpi `"value`"]"
    Write-Host "Example: .\LaTeq.ps1 `"3x+1`""
    Write-Host "Example: .\LaTeq.ps1 `"3x+1`" --png"
    Write-Host "Example: .\LaTeq.ps1 `"3x+1`" --jpeg --output `"`$env:USERPROFILE\Documents`""
    Write-Host "Example: .\LaTeq.ps1 `"3x+1`" --png --output `"`$env:USERPROFILE\Documents`" --filename `"my_equation`""
    Write-Host "Example: .\LaTeq.ps1 `"3x+1`" --png --dpi `"300`""
    Write-Host "Example: .\LaTeq.ps1 `"\tikz \draw (0,0) circle (1cm);`" --packages `"tikz`""
    Write-Host "Example: .\LaTeq.ps1 `"\chemfig{H-C(-[2]H)(-[6]H)-H}`" --packages `"chemfig,xcolor`""
    Write-Host "By default, files are saved in the current directory"
    Write-Host "Default packages: amsmath, amssymb, amsfonts"
    Write-Host "Default DPI: 450"
    exit 1
}

# Setup directories - temporary files ALWAYS go to temp directory (like Linux /tmp/LaTeq)
$TEMP_DIR = "$env:TEMP\LaTeq"

# Final output directory - if not specified, use current directory (like Linux script)
$FINAL_OUTPUT_DIR = if ($output -eq ".") { Get-Location } else { $output }

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
Write-Host "Compiling equation: $Equation"
if ($FINAL_OUTPUT_DIR_ABS -ne (Get-Location).Path) {
    Write-Host "Final output directory: $FINAL_OUTPUT_DIR_ABS"
}
if ($packages -ne "") {
    Write-Host "Using additional packages: $packages"
}
if ($EXPORT_PNG -or $EXPORT_JPEG) {
    Write-Host "Using DPI: $dpi"
}

# Change to temp directory and compile
Push-Location $TEMP_DIR
try {
    $pdflatexResult = & pdflatex -interaction=nonstopmode "$FILENAME.tex" 2>&1
    if ($LASTEXITCODE -ne 0 -and $pdflatexResult) {
        Write-Host "PDFLaTeX output:"
        $pdflatexResult | Write-Host
    }
} catch {
    Write-Host "Error running pdflatex: $($_.Exception.Message)"
}
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
        $magickCmd = Get-Command "magick" -ErrorAction SilentlyContinue
        $convertCmd = Get-Command "convert" -ErrorAction SilentlyContinue
        
        if ($magickCmd -or $convertCmd) {
            # Check if Ghostscript is available (required for PDF conversion)
            $gsCmd = Get-Command "gswin64c" -ErrorAction SilentlyContinue
            if (-not $gsCmd) {
                $gsCmd = Get-Command "gswin32c" -ErrorAction SilentlyContinue
            }
            if (-not $gsCmd) {
                $gsCmd = Get-Command "gs" -ErrorAction SilentlyContinue
            }
            
            if (-not $gsCmd) {
                Write-Host "Warning: Ghostscript not found. ImageMagick requires Ghostscript for PDF conversion."
                Write-Host "Please install Ghostscript from: https://www.ghostscript.com/download/gsdnld.html"
                Write-Host "Or install via Chocolatey: choco install ghostscript"
                Write-Host ""
                Write-Host "Attempting conversion anyway..."
            }            if ($EXPORT_PNG) {
                Write-Host "Converting to PNG..."
                try {
                    if ($magickCmd) {
                        # Use modern ImageMagick syntax matching Linux script
                        & magick -density $dpi "$PDF_FILE" -quality 90 "$PNG_FILE" 2>&1 | Write-Host
                    } else {
                        # Use legacy convert command matching Linux script
                        & convert -density $dpi "$PDF_FILE" -quality 90 "$PNG_FILE" 2>&1 | Write-Host
                    }
                } catch {
                    Write-Host "Error during PNG conversion: $($_.Exception.Message)"
                    $LASTEXITCODE = 1
                }
                
                if ($LASTEXITCODE -eq 0) {
                    if ($TEMP_DIR_ABS -ne $FINAL_OUTPUT_DIR_ABS) {
                        Copy-Item $PNG_FILE $FINAL_PNG_FILE -Force
                        $OUTPUT_FILE = $FINAL_PNG_FILE
                    } else {
                        $OUTPUT_FILE = $PNG_FILE
                    }
                    $FORMAT = "PNG"                } else {
                    Write-Host "Error during PNG conversion!"
                    if (Test-Path $PDF_FILE) { Remove-Item $PDF_FILE -Force }
                    exit 1
                }            } elseif ($EXPORT_JPEG) {
                Write-Host "Converting to JPEG..."
                try {
                    if ($magickCmd) {
                        # Use modern ImageMagick syntax for Windows
                        & magick -density $dpi "$PDF_FILE" -background white -flatten -quality 90 "$JPEG_FILE" 2>&1 | Write-Host
                    } else {
                        # Use legacy convert command
                        & convert -density $dpi "$PDF_FILE" -background white -flatten -quality 90 "$JPEG_FILE" 2>&1 | Write-Host
                    }
                } catch {
                    Write-Host "Error during JPEG conversion: $($_.Exception.Message)"
                    $LASTEXITCODE = 1
                }
                
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
            }        } else {
            Write-Host "ImageMagick (convert) not installed. Required for image conversion:"
            Write-Host "Please install ImageMagick from: https://imagemagick.org/script/download.php#windows"
            Write-Host "Or install via Chocolatey: choco install imagemagick"
            Write-Host ""
            Write-Host "Note: ImageMagick also requires Ghostscript for PDF conversion."
            Write-Host "Install Ghostscript from: https://www.ghostscript.com/download/gsdnld.html"
            Write-Host "Or install via Chocolatey: choco install ghostscript"
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
