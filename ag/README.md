This directory contains some source code explpring algebraic geometry. 

## Macaulay2

To install Macaulay2 on MacOS:

```bash
-- brew install Macaulay2/tap/M2
```

To run a script that generates a SVG file:

```bash
-- m2 --script ag/hello.m2 > output/hello.svg
```

## Singular

To install Singular on MacOS:

```bash
brew install singular
```

To install for [using it in Jupyter notebooks](https://www.singular.uni-kl.de/index.php/graphical-interface.html):

```bash
# pyenv shell 3.11
pip3 install PySingular
pip3 install jupyter_kernel_singular
```