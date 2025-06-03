# LaTeq
**Compile standalone LaTeX equations into PDF, PNG, or JPEG with a simple command.**

## 🧮 What is LaTeq?
LaTeq is a command-line tool written in Bash that lets you compile LaTeX math equations on the fly. It's perfect for generating beautiful equations for slides, documents, or image-based content. It supports PDF, PNG, and JPEG outputs and opens the result directly.

## ✨ Features
- **Multiple output formats**: PDF (default), PNG, and JPEG
- **Custom filename support**: Specify your own filename with `--filename`
- **Custom package support**: Add any LaTeX packages you need
- **Interactive error handling**: Detailed debugging options when compilation fails
- **Automatic file opening**: Generated files open in your default viewer
- **Flexible output locations**: Save files wherever you want
- **Temporary file separation**: Working files stay in `/tmp/LaTeq`, only final output goes to your specified directory

## 🚀 Quick Installation

### Automatic Installation (Recommended)

#### 🐧 Linux / macOS
Install LaTeq system-wide with a single command:

```bash
curl -sSL https://raw.githubusercontent.com/MathieuMichels/LaTeq/main/install.sh | bash
```

This script will:
- ✅ Check and install all dependencies (texlive, imagemagick)
- ✅ Download the latest LaTeq script from GitHub
- ✅ Install it system-wide to `/usr/local/bin/LaTeq`
- ✅ Test the installation
- ✅ Work on Debian/Ubuntu, RedHat/CentOS, and Arch Linux

#### 🪟 Windows
Install LaTeq system-wide with a single PowerShell command (run as Administrator):

```powershell
powershell -Command "& {Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/MathieuMichels/LaTeq/main/install-windows.ps1' -UseBasicParsing | Invoke-Expression}"
```

This script will:
- ✅ Check for dependencies (recommends MiKTeX/TeX Live and ImageMagick)
- ✅ Download the latest LaTeq scripts from GitHub (PowerShell + Batch wrapper)
- ✅ Install them system-wide to `C:\Program Files\LaTeq`
- ✅ Add to system PATH so you can use `LaTeq` from anywhere
- ✅ Set PowerShell execution policy if needed
- ✅ Test the installation

After installation, you can use `LaTeq` from anywhere in Command Prompt or PowerShell!

### Manual Installation

#### 🐧 Linux / macOS
If you prefer manual installation or want more control:

```bash
# Download the script
wget https://raw.githubusercontent.com/MathieuMichels/LaTeq/main/LaTeq.sh

# Make it executable
chmod +x LaTeq.sh

# Install system-wide
sudo cp LaTeq.sh /usr/local/bin/LaTeq
```

#### 🪟 Windows
For manual Windows installation:

```powershell
# Download the scripts
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/MathieuMichels/LaTeq/main/LaTeq.ps1" -OutFile "LaTeq.ps1"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/MathieuMichels/LaTeq/main/LaTeq.bat" -OutFile "LaTeq.bat"

# Create installation directory (as Administrator)
New-Item -ItemType Directory -Path "C:\Program Files\LaTeq" -Force

# Copy files (as Administrator)
Copy-Item "LaTeq.ps1" "C:\Program Files\LaTeq\"
Copy-Item "LaTeq.bat" "C:\Program Files\LaTeq\"

# Add to PATH (as Administrator)
$path = [Environment]::GetEnvironmentVariable("Path", "Machine")
[Environment]::SetEnvironmentVariable("Path", "$path;C:\Program Files\LaTeq", "Machine")
```

## 🔧 Dependencies
The automatic installer handles these for you, but if installing manually:

### 🐧 Linux / macOS
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

### 🪟 Windows
- **MiKTeX** or **TeX Live** (for compiling LaTeX)
- **ImageMagick** (for converting PDFs to images)
- **PowerShell** (included with Windows)

Install dependencies:
- **MiKTeX**: Download from [miktex.org](https://miktex.org/download)
- **TeX Live**: Download from [tug.org/texlive](https://www.tug.org/texlive/windows.html)
- **ImageMagick**: Download from [imagemagick.org](https://imagemagick.org/script/download.php#windows)

Or use **Chocolatey** package manager:
```powershell
choco install miktex imagemagick
```

## 🧪 Testing
If you used the automatic installer, LaTeq is already installed system-wide.

### 🐧 Linux / macOS
To test manually or after manual installation:
```bash
chmod +x LaTeq.sh
./LaTeq.sh "x^2 + \frac{1}{2}" --jpeg
```

### 🪟 Windows
To test manually or after manual installation:
```powershell
.\LaTeq.ps1 "x^2 + \frac{1}{2}" -jpeg
```
or
```cmd
LaTeq.bat "x^2 + \frac{1}{2}" -jpeg
```

![Testing Example](galery/testing_example.jpg)

Make sure the output is opened and appears as expected.

## 🌍 System-wide Installation
If you used the automatic installer, this step is already completed!

### 🐧 Linux / macOS
For manual system-wide installation:
To use `LaTeq` from anywhere on your system:
```bash
sudo cp LaTeq.sh /usr/local/bin/LaTeq
sudo chmod +x /usr/local/bin/LaTeq
```

### 🪟 Windows
For manual system-wide installation (run as Administrator):
```powershell
# Copy scripts to system directory
Copy-Item "LaTeq.ps1" "C:\Program Files\LaTeq\"
Copy-Item "LaTeq.bat" "C:\Program Files\LaTeq\"

# Add to system PATH
$path = [Environment]::GetEnvironmentVariable("Path", "Machine")
[Environment]::SetEnvironmentVariable("Path", "$path;C:\Program Files\LaTeq", "Machine")
```

You can now run from any directory:
```bash
LaTeq "e^{i\pi} + 1 = 0" --jpeg    # Linux/macOS
```
```cmd
LaTeq "e^{i\pi} + 1 = 0" -jpeg     # Windows
```
![Euler's Identity](galery/euler_identity.jpg)

## 🛠 Usage

### 🐧 Linux / macOS
```bash
LaTeq "equation" [--png|--jpeg] [--output /path/to/dir] [--filename name] [--packages "pkg1,pkg2,pkg3"]
```

### 🪟 Windows
```cmd
LaTeq "equation" [-png|-jpeg] [-output "path"] [-filename "name"] [-packages "pkg1,pkg2,pkg3"]
```

### Basic Examples

Simple linear equation:
```bash
LaTeq "3x+1"
```
![Basic equation](galery/example_basic.jpg)

Pythagorean theorem:
```bash
LaTeq "x^2 + y^2 = z^2" --jpeg
```
![Pythagorean theorem](galery/pythagorean.jpg)

Integral calculation:
```bash
LaTeq "\int_0^1 x^2 dx" --jpeg --output ~/Documents
```
![Integral](galery/integral.jpg)

### Advanced Examples with Packages

TikZ graphics:
```bash
LaTeq "\tikz \draw (0,0) circle (1cm);" --packages "tikz" --jpeg --filename "circle"
```
![TikZ Circle](galery/tikz_circle.jpg)

Chemistry formulas:
```bash
LaTeq "\chemfig{H-C(-[2]H)(-[6]H)-H}" --packages "chemfig,xcolor" --jpeg --filename "methane"
```
![Methane molecule](galery/methane.jpg)

Complex diagrams with multiple packages:
```bash
LaTeq '\begin{tikzpicture} \node[draw,fill=blue!20] {Hello}; \end{tikzpicture}' --packages "tikz,xcolor" --jpeg --output ~/Desktop --filename "hello_box"
```
![Complex TikZ Diagram](galery/hello_box.jpg)

Physics equations:
```bash
LaTeq "\hbar \omega = E" --packages "physics"
```
![Physics Equation](galery/hbar_omega.jpg)

Custom fonts:
```bash
LaTeq "E = mc^2" --packages "newtxtext,newtxmath" --jpeg --filename "einstein_custom"
```
![Einstein with Custom Fonts](galery/einstein_custom_font.jpg)

More complex:
```bash
LaTeq "\boxed{\underbrace{\rho\bigl(\tfrac{\partial\mathbf{u}}{\partial t}+(\mathbf{u}\cdot\nabla)\mathbf{u}\bigr)}_{\color{red}\text{Inertia}}\;=\; -\underbrace{\nabla p}_{\color{blue}\text{Pressure}}\;+\;\underbrace{\mu\,\nabla^2\mathbf{u}}_{\color{green}\text{Viscous}}\;+\;\underbrace{\mathbf{f}}_{\color{orange}\text{Body Force}}}" --packages "amsmath,mathtools,xcolor"
```
![Navier-Stokes Equation](galery/navier_stokes.jpg)

By default, files are saved in the current directory.

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
  ![Custom Command Example](galery/custom_command.jpg)

## 🔍 Troubleshooting
- **Package not found**: Install `texlive-full` or the specific package collection
- **Command not found**: The LaTeX command might be undefined - check spelling or add required packages
- **Compilation hangs**: Use Ctrl+C to stop and check your equation syntax
- **No output file**: Check the interactive error menu for details

## 📝 Examples Gallery

### Mathematics

Basel problem:
```bash
LaTeq "\sum_{n=1}^{\infty} \frac{1}{n^2} = \frac{\pi^2}{6}"
```
![Basel Problem](galery/basel_problem.jpg)

Stokes theorem:
```bash
LaTeq "\oint_C \mathbf{F} \cdot d\mathbf{r} = \iint_S (\nabla \times \mathbf{F}) \cdot d\mathbf{S}"
```
![Stokes Theorem](galery/stokes_theorem.jpg)

### Physics

Einstein's mass-energy equivalence:
```bash
LaTeq "E = mc^2" --packages "physics"
```
![Einstein's Formula](galery/einstein.jpg)

Schrödinger equation:
```bash
LaTeq "\hat{H}\psi = E\psi" --packages "physics"
```
![Schrödinger Equation](galery/schrodinger.jpg)

### Chemistry

Acid-base reaction:
```bash
LaTeq "\ce{H2SO4 + 2NaOH -> Na2SO4 + 2H2O}" --packages "mhchem"
```
![Chemical Reaction](galery/chemical_reaction.jpg)

Phenol structure:
```bash
LaTeq "\chemfig{*6(=-=(-OH)-=-=-)}" --packages "chemfig"
```
![Phenol Structure](galery/benzene_phenol.jpg)

### Graphics

Force vector diagram:
```bash
LaTeq "\tikz[scale=0.8] \draw[->] (0,0) -- (2,1) node[right] {\$F\$};" --packages "tikz"
```
![Force Vector](galery/force_vector.jpg)
