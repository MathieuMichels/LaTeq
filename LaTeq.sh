#!/bin/bash

# Script to compile a LaTeX equation to standalone PDF, PNG, or JPEG
# Usage: LaTeq "equation" [--png|--jpeg] [--output /path/to/dir] [--filename name] [--packages "pkg1,pkg2,pkg3"]
# Example: LaTeq "3x+1"
# Example: LaTeq "3x+1" --png
# Example: LaTeq "3x+1" --jpeg --output ~/Documents
# Example: LaTeq "3x+1" --png --output ~/Documents --filename "my_equation"
# Example: LaTeq "\tikz \draw (0,0) circle (1cm);" --packages "tikz"
# Example: LaTeq "\chemfig{H-C(-[2]H)(-[6]H)-H}" --packages "chemfig,xcolor"

if [ $# -eq 0 ]; then
    echo "Usage: $0 \"equation\" [--png|--jpeg] [--output /path/to/dir] [--filename name] [--packages \"pkg1,pkg2,pkg3\"]"
    echo "Example: $0 \"3x+1\""
    echo "Example: $0 \"3x+1\" --png"
    echo "Example: $0 \"3x+1\" --jpeg --output ~/Documents"
    echo "Example: $0 \"3x+1\" --png --output ~/Documents --filename \"my_equation\""
    echo "Example: $0 \"\\tikz \\draw (0,0) circle (1cm);\" --packages \"tikz\""
    echo "Example: $0 \"\\chemfig{H-C(-[2]H)(-[6]H)-H}\" --packages \"chemfig,xcolor\""
    echo "By default, files are saved in the current directory"
    echo "Default packages: amsmath, amssymb, amsfonts"
    exit 1
fi

EQUATION="$1"
EXPORT_PNG=false
EXPORT_JPEG=false
OUTPUT_DIR="."
CUSTOM_FILENAME=""
PACKAGES=""

# Parse arguments
shift
while [[ $# -gt 0 ]]; do
    case $1 in
        --png)
            EXPORT_PNG=true
            shift
            ;;
        --jpeg)
            EXPORT_JPEG=true
            shift
            ;;
        --output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --filename)
            CUSTOM_FILENAME="$2"
            shift 2
            ;;
        --packages)
            PACKAGES="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Setup directories - temporary files always go to /tmp/LaTeq
TEMP_DIR="/tmp/LaTeq"
mkdir -p "$TEMP_DIR"

# If output directory is specified, create it and check permissions
FINAL_OUTPUT_DIR="$OUTPUT_DIR"
mkdir -p "$FINAL_OUTPUT_DIR"
if [ ! -w "$FINAL_OUTPUT_DIR" ]; then
    echo "Error: Cannot write to $FINAL_OUTPUT_DIR"
    exit 1
fi

# Get absolute paths to compare them properly
TEMP_DIR_ABS=$(cd "$TEMP_DIR" && pwd)
FINAL_OUTPUT_DIR_ABS=$(cd "$FINAL_OUTPUT_DIR" && pwd)

# Determine filename
if [ ! -z "$CUSTOM_FILENAME" ]; then
    FILENAME="$CUSTOM_FILENAME"
else
    FILENAME="equation_$(date +%s)"
fi

# Temporary files (always in /tmp/LaTeq)
TEX_FILE="${TEMP_DIR}/${FILENAME}.tex"
PDF_FILE="${TEMP_DIR}/${FILENAME}.pdf"
PNG_FILE="${TEMP_DIR}/${FILENAME}.png"
JPEG_FILE="${TEMP_DIR}/${FILENAME}.jpg"

# Final output files (in specified output directory)
FINAL_PDF_FILE="${FINAL_OUTPUT_DIR_ABS}/${FILENAME}.pdf"
FINAL_PNG_FILE="${FINAL_OUTPUT_DIR_ABS}/${FILENAME}.png"
FINAL_JPEG_FILE="${FINAL_OUTPUT_DIR_ABS}/${FILENAME}.jpg"

# Start building the LaTeX document
cat > "$TEX_FILE" << EOF
\documentclass[border=10pt]{standalone}
\usepackage{amsmath}
\usepackage{amssymb}
\usepackage{amsfonts}
EOF

# Add custom packages if specified
if [ ! -z "$PACKAGES" ]; then
    echo "Additional packages: $PACKAGES"
    # Split packages by comma and add each one
    IFS=',' read -ra PKG_ARRAY <<< "$PACKAGES"
    for pkg in "${PKG_ARRAY[@]}"; do
        # Trim whitespace
        pkg=$(echo "$pkg" | xargs)
        if [ ! -z "$pkg" ]; then
            echo "\\usepackage{$pkg}" >> "$TEX_FILE"
        fi
    done
fi

# Complete the LaTeX document
cat >> "$TEX_FILE" << EOF

\begin{document}
\$\displaystyle $EQUATION\$
\end{document}
EOF

echo "Compiling equation: $EQUATION"
if [ "$FINAL_OUTPUT_DIR" != "." ]; then
    echo "Final output directory: $FINAL_OUTPUT_DIR"
fi
if [ ! -z "$PACKAGES" ]; then
    echo "Using additional packages: $PACKAGES"
fi

cd "$TEMP_DIR"
pdflatex -interaction=nonstopmode "${FILENAME}.tex" > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "Compilation successful!"
    rm -f "${TEMP_DIR}/${FILENAME}.aux" "${TEMP_DIR}/${FILENAME}.log" "$TEX_FILE"
    
    if [ "$EXPORT_PNG" = true ] || [ "$EXPORT_JPEG" = true ]; then
        if command -v convert > /dev/null; then
            if [ "$EXPORT_PNG" = true ]; then
                echo "Converting to PNG..."
                convert -density 300 "${FILENAME}.pdf" -quality 90 "${FILENAME}.png"
                # Copy to final output directory if different from temp
                if [ "$TEMP_DIR_ABS" != "$FINAL_OUTPUT_DIR_ABS" ]; then
                    cp "$PNG_FILE" "$FINAL_PNG_FILE"
                    OUTPUT_FILE="$FINAL_PNG_FILE"
                else
                    OUTPUT_FILE="$PNG_FILE"
                fi
                FORMAT="PNG"
            else
                echo "Converting to JPEG..."
                convert -density 300 "${FILENAME}.pdf" -background white -flatten -quality 90 "${FILENAME}.jpg"
                # Copy to final output directory if different from temp
                if [ "$TEMP_DIR_ABS" != "$FINAL_OUTPUT_DIR_ABS" ]; then
                    cp "$JPEG_FILE" "$FINAL_JPEG_FILE"
                    OUTPUT_FILE="$FINAL_JPEG_FILE"
                else
                    OUTPUT_FILE="$JPEG_FILE"
                fi
                FORMAT="JPEG"
            fi

            if [ $? -eq 0 ]; then
                echo "$FORMAT conversion successful!"
                echo "Generated file: $OUTPUT_FILE"
                # Clean up temporary PDF
                rm -f "$PDF_FILE"
                if command -v xdg-open > /dev/null; then
                    nohup xdg-open "$OUTPUT_FILE" > /dev/null 2>&1 &
                elif command -v eog > /dev/null; then
                    nohup eog "$OUTPUT_FILE" > /dev/null 2>&1 &
                elif command -v display > /dev/null; then
                    nohup display "$OUTPUT_FILE" > /dev/null 2>&1 &
                else
                    echo "$FORMAT generated: $OUTPUT_FILE"
                    echo "No image viewer found. Please open manually."
                fi
            else
                echo "Error during $FORMAT conversion!"
                rm -f "$PDF_FILE"
                exit 1
            fi
        else
            echo "ImageMagick (convert) not installed. Required for image conversion:"
            echo "sudo apt install imagemagick"
            rm -f "$PDF_FILE"
            exit 1
        fi
    else
        # Copy PDF to final output directory if different from temp
        if [ "$TEMP_DIR_ABS" != "$FINAL_OUTPUT_DIR_ABS" ]; then
            cp "$PDF_FILE" "$FINAL_PDF_FILE"
            OUTPUT_FILE="$FINAL_PDF_FILE"
        else
            OUTPUT_FILE="$PDF_FILE"
        fi
        echo "PDF generated: $OUTPUT_FILE"
        if command -v xdg-open > /dev/null; then
            nohup xdg-open "$OUTPUT_FILE" > /dev/null 2>&1 &
        elif command -v evince > /dev/null; then
            nohup evince "$OUTPUT_FILE" > /dev/null 2>&1 &
        elif command -v okular > /dev/null; then
            nohup okular "$OUTPUT_FILE" > /dev/null 2>&1 &
        else
            echo "No PDF viewer found. Please open manually."
        fi
    fi
else
    echo "Compilation error!"
    echo "Check your equation syntax and package dependencies."
    echo ""
    
    # Interactive error handling
    while true; do
        echo "What would you like to do?"
        echo "1) Show LaTeX log"
        echo "2) Show generated .tex file"
        echo "3) Save log file to disk"
        echo "4) Save .tex file to disk"
        echo "5) Show both log and .tex file"
        echo "6) Clean up and exit"
        echo ""
        read -p "Choose an option (1-6): " choice
        
        case $choice in
            1)
                echo ""
                echo "LaTeX log:"
                echo "===================="
                if [ -f "${TEMP_DIR}/${FILENAME}.log" ]; then
                    cat "${TEMP_DIR}/${FILENAME}.log"
                else
                    echo "Log file not found"
                fi
                echo "===================="
                echo ""
                ;;
            2)
                echo ""
                echo "Generated .tex file:"
                echo "===================="
                if [ -f "$TEX_FILE" ]; then
                    cat "$TEX_FILE"
                else
                    echo "TeX file not found"
                fi
                echo "===================="
                echo ""
                ;;
            3)
                if [ -f "${TEMP_DIR}/${FILENAME}.log" ]; then
                    SAVED_LOG="${FINAL_OUTPUT_DIR}/lateq_error_$(date +%s).log"
                    cp "${TEMP_DIR}/${FILENAME}.log" "$SAVED_LOG"
                    echo "Log saved to: $SAVED_LOG"
                else
                    echo "No log file to save"
                fi
                echo ""
                ;;
            4)
                if [ -f "$TEX_FILE" ]; then
                    SAVED_TEX="${FINAL_OUTPUT_DIR}/lateq_error_$(date +%s).tex"
                    cp "$TEX_FILE" "$SAVED_TEX"
                    echo "TeX file saved to: $SAVED_TEX"
                else
                    echo "No TeX file to save"
                fi
                echo ""
                ;;
            5)
                echo ""
                echo "Generated .tex file:"
                echo "===================="
                if [ -f "$TEX_FILE" ]; then
                    cat "$TEX_FILE"
                else
                    echo "TeX file not found"
                fi
                echo "===================="
                echo ""
                echo "LaTeX log:"
                echo "===================="
                if [ -f "${TEMP_DIR}/${FILENAME}.log" ]; then
                    cat "${TEMP_DIR}/${FILENAME}.log"
                else
                    echo "Log file not found"
                fi
                echo "===================="
                echo ""
                ;;
            6)
                echo "Cleaning up and exiting..."
                break
                ;;
            *)
                echo "Invalid option. Please choose 1-6."
                echo ""
                ;;
        esac
    done
    
    # Clean up temporary files
    rm -f "$TEX_FILE" "${TEMP_DIR}/${FILENAME}.log" "${TEMP_DIR}/${FILENAME}.aux"
    exit 1
fi
