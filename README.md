# LaTeq
**Compile standalone LaTeX equations into PDF, PNG, or JPEG with a simple command.**

## 🧮 What is LaTeq?
LaTeq is a command-line tool written in Bash that lets you compile LaTeX math equations on the fly. It's perfect for generating beautiful equations for slides, documents, or image-based content. It supports PDF, PNG, and JPEG outputs and opens the result directly.

## ✨ Features
- **Multiple output formats**: PDF (default), PNG, and JPEG
- **Custom package support**: Add any LaTeX packages you need
- **Interactive error handling**: Detailed debugging options when compilation fails
- **Automatic file opening**: Generated files open in your default viewer
- **Flexible output locations**: Save files wherever you want

## 🔧 Dependencies
- `texlive` (for compiling LaTeX)
- `imagemagick` (for converting PDFs to images)

Install on Debian-based systems:
```bash
sudo apt install texlive imagemagick
```

For full LaTeX functionality with all packages:
```bash
sudo apt install texlive-full
```

## 🧪 Testing
To quickly test the script without installing it system-wide:
```bash
chmod +x LaTeq.sh
./LaTeq.sh "x^2 + \frac{1}{2}" --png
```
Make sure the output is opened and appears as expected.

## 🌍 System-wide Installation
To use `LaTeq` from anywhere on your system:
```bash
sudo cp LaTeq.sh /usr/local/bin/LaTeq
sudo chmod +x /usr/local/bin/LaTeq
```
You can now run:
```bash
LaTeq "e^{i\pi} + 1 = 0" --jpeg
```
from any directory.

## 🛠 Usage
```bash
LaTeq "equation" [--png|--jpeg] [--output /path/to/dir] [--packages "pkg1,pkg2,pkg3"]
```

### Basic Examples
```bash
LaTeq "3x+1"
LaTeq "x^2 + y^2 = z^2" --png
LaTeq "\int_0^1 x^2 dx" --jpeg --output ~/Documents
```

### Advanced Examples with Packages
```bash
# TikZ graphics
LaTeq "\tikz \draw (0,0) circle (1cm);" --packages "tikz"

# Chemistry formulas
LaTeq "\chemfig{H-C(-[2]H)(-[6]H)-H}" --packages "chemfig,xcolor"

# Complex diagrams with multiple packages
LaTeq '\begin{tikzpicture} \node[draw,fill=blue!20] {Hello}; \end{tikzpicture}' --packages "tikz,xcolor" --png --output ~/Desktop

# Physics equations
LaTeq "\hbar \omega = E" --packages "physics,siunitx"

# Custom fonts
LaTeq "E = mc^2" --packages "newtxtext,newtxmath" --png
```

By default, files are saved in `/tmp/LaTeq`.

## 📦 Package Support
LaTeq includes these packages by default:
- `amsmath` - Advanced math environments
- `amssymb` - Mathematical symbols  
- `amsfonts` - Mathematical fonts

You can add additional packages using the `--packages` flag with a comma-separated list:
```bash
LaTeq "equation" --packages "tikz,pgfplots,xcolor"
```

Popular packages you might want to use:
- `tikz` - Graphics and diagrams
- `pgfplots` - Plotting
- `chemfig` - Chemical formulas
- `physics` - Physics notation
- `siunitx` - SI units
- `xcolor` - Colors
- `mathtools` - Extended math tools

## 📤 Output
* **PDF** (default) - Vector format, perfect for documents
* **PNG** (`--png`) - Raster format with transparency
* **JPEG** (`--jpeg`) - Raster format, smaller file size

The generated files are opened automatically using your system's default viewer.

## 🐛 Error Handling
When compilation fails, LaTeq provides an interactive menu with these options:

1. **Show LaTeX log** - View detailed error messages
2. **Show generated .tex file** - Inspect the LaTeX code
3. **Save log file to disk** - Keep the log for later analysis  
4. **Save .tex file to disk** - Save the LaTeX source for debugging
5. **Show both log and .tex file** - Display both at once
6. **Clean up and exit** - Remove temporary files and exit

This makes it easy to debug complex equations or package conflicts.

## ⚠️ Notes
* You must use escaped LaTeX in the command-line string (e.g., `\\frac` instead of `\frac`) or write the equation between quotes (e.g., `LaTeq "\frac{3x+1}{2}"` or `LaTeq \\frac{3x+1}{2}`)
* If `convert` is missing, install ImageMagick as shown above
* For complex equations with custom commands, you can define them inline:
  ```bash
  LaTeq "\newcommand{\mysum}{\displaystyle\sum} \mysum_{i=1}^n x_i"
  ```

## 🔍 Troubleshooting
- **Package not found**: Install `texlive-full` or the specific package collection
- **Command not found**: The LaTeX command might be undefined - check spelling or add required packages
- **Compilation hangs**: Use Ctrl+C to stop and check your equation syntax
- **No output file**: Check the interactive error menu for details

## 📝 Examples Gallery

### Mathematics
```bash
LaTeq "\sum_{n=1}^{\infty} \frac{1}{n^2} = \frac{\pi^2}{6}"
LaTeq "\oint_C \mathbf{F} \cdot d\mathbf{r} = \iint_S (\nabla \times \mathbf{F}) \cdot d\mathbf{S}"
```

### Physics  
```bash
LaTeq "E = mc^2" --packages "physics"
LaTeq "\hat{H}\psi = E\psi" --packages "physics"
```

### Chemistry
```bash
LaTeq "\ce{H2SO4 + 2NaOH -> Na2SO4 + 2H2O}" --packages "mhchem"
LaTeq "\chemfig{*6(=-=(-OH)-=-=-)}" --packages "chemfig"
```

### Graphics
```bash
LaTeq "\tikz[scale=0.8] \draw[->] (0,0) -- (2,1) node[right] {\$F\$};" --packages "tikz"
```
