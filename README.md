# LaTeq

**Compile standalone LaTeX equations into PDF, PNG, or JPEG with a simple command.**

## 🧮 What is LaTeq?

LaTeq is a command-line tool written in Bash that lets you compile LaTeX math equations on the fly. It’s perfect for generating beautiful equations for slides, documents, or image-based content. It supports PDF, PNG, and JPEG outputs and opens the result directly.

## 🔧 Dependencies

- `texlive` (for compiling LaTeX)
- `imagemagick` (for converting PDFs to images)

Install on Debian-based systems:

```bash
sudo apt install texlive imagemagick
````

## 🚀 Installation

```bash
sudo cp LaTeq.sh /usr/local/bin/LaTeq
sudo chmod +x /usr/local/bin/LaTeq
```

## 🛠 Usage

```bash
LaTeq "x^2 + \frac{1}{2}" [--png|--jpeg] [--output /path/to/dir]
```

### Examples

```bash
LaTeq "3x+1"
LaTeq "x^2 + y^2 = z^2" --png
LaTeq "\int_0^1 x^2 dx" --jpeg --output ~/Documents
```

By default, files are saved in `/tmp/latex_equations`.

## 📤 Output

* PDF (default)
* PNG (`--png`)
* JPEG (`--jpeg`)

The generated files are opened automatically using your system's default viewer.

## ⚠️ Notes

* You must use escaped LaTeX in the command-line string (e.g., `\\frac` instead of `\frac`) or write the equation between quotes (e.g., `LaTeq "\frac{3x+1}{2}"` or `Lateq \\frac{3x+1}{2}`)
* If `convert` is missing, install ImageMagick as shown above.
* If you don't see anything generated, check the equation syntax or LaTeX errors.
