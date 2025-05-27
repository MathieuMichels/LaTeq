#!/bin/bash

# Script to compile a LaTeX equation to standalone PDF, PNG, or JPEG
# Usage: LaTeq "equation" [--png|--jpeg] [--output /path/to/dir]
# Example: LaTeq "3x+1"
# Example: LaTeq "3x+1" --png
# Example: LaTeq "3x+1" --jpeg --output ~/Documents

if [ $# -eq 0 ]; then
    echo "Usage: $0 \"equation\" [--png|--jpeg] [--output /path/to/dir]"
    echo "Example: $0 \"3x+1\""
    echo "Example: $0 \"3x+1\" --png"
    echo "Example: $0 \"3x+1\" --jpeg --output ~/Documents"
    echo "By default, files are saved in /tmp/latex_equations/"
    exit 1
fi

EQUATION="$1"
EXPORT_PNG=false
EXPORT_JPEG=false
OUTPUT_DIR="/tmp/latex_equations"

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
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

mkdir -p "$OUTPUT_DIR"

if [ ! -w "$OUTPUT_DIR" ]; then
    echo "Error: Cannot write to $OUTPUT_DIR"
    exit 1
fi

FILENAME="equation_$(date +%s)"
TEX_FILE="${OUTPUT_DIR}/${FILENAME}.tex"
PDF_FILE="${OUTPUT_DIR}/${FILENAME}.pdf"
PNG_FILE="${OUTPUT_DIR}/${FILENAME}.png"
JPEG_FILE="${OUTPUT_DIR}/${FILENAME}.jpg"

cat > "$TEX_FILE" << EOF
\documentclass[border=10pt]{standalone}
\usepackage{amsmath}
\usepackage{amssymb}
\usepackage{amsfonts}

\begin{document}
\$\displaystyle $EQUATION\$
\end{document}
EOF

echo "Compiling equation: $EQUATION"
echo "Output directory: $OUTPUT_DIR"

cd "$OUTPUT_DIR"
pdflatex -interaction=nonstopmode "${FILENAME}.tex" > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "Compilation successful!"
    rm -f "${OUTPUT_DIR}/${FILENAME}.aux" "${OUTPUT_DIR}/${FILENAME}.log" "$TEX_FILE"
    
    if [ "$EXPORT_PNG" = true ] || [ "$EXPORT_JPEG" = true ]; then
        if command -v convert > /dev/null; then
            if [ "$EXPORT_PNG" = true ]; then
                echo "Converting to PNG..."
                convert -density 300 "${FILENAME}.pdf" -quality 90 "${FILENAME}.png"
                OUTPUT_FILE="${OUTPUT_DIR}/${FILENAME}.png"
                FORMAT="PNG"
            else
                echo "Converting to JPEG..."
                convert -density 300 "${FILENAME}.pdf" -background white -flatten -quality 90 "${FILENAME}.jpg"
                OUTPUT_FILE="${OUTPUT_DIR}/${FILENAME}.jpg"
                FORMAT="JPEG"
            fi

            if [ $? -eq 0 ]; then
                echo "$FORMAT conversion successful!"
                echo "Generated file: $OUTPUT_FILE"
                rm -f "${OUTPUT_DIR}/${FILENAME}.pdf"
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
                rm -f "${OUTPUT_DIR}/${FILENAME}.pdf"
                exit 1
            fi
        else
            echo "ImageMagick (convert) not installed. Required for image conversion:"
            echo "sudo apt install imagemagick"
            rm -f "${OUTPUT_DIR}/${FILENAME}.pdf"
            exit 1
        fi
    else
        echo "PDF generated: $PDF_FILE"
        if command -v xdg-open > /dev/null; then
            nohup xdg-open "$PDF_FILE" > /dev/null 2>&1 &
        elif command -v evince > /dev/null; then
            nohup evince "$PDF_FILE" > /dev/null 2>&1 &
        elif command -v okular > /dev/null; then
            nohup okular "$PDF_FILE" > /dev/null 2>&1 &
        else
            echo "No PDF viewer found. Please open manually."
        fi
    fi
else
    echo "Compilation error!"
    echo "Check your equation syntax."
    rm -f "$TEX_FILE"
    exit 1
fi
