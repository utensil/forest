This forest is initialized with the following command:

```bash
brew install opam fswatch

opam init
opam update
opam install forester
forester --version

cd ~/projects/
git init forest
cd forest
git pull https://git.sr.ht/~jonsterling/forest-template

git remote add origin https://github.com/utensil/forest.git
git branch -M main
git push -u origin main

git submodule update --init --recursive
git submodule update --remote --merge
```

Add a `forest.toml`, then:

```bash
forester new --dest=trees --prefix=uts
```
Update `build.sh`, then

```bash
./build.sh && ./watch.sh
```

And in a separate terminal:

```bash
# python3 -m http.server 1314 -d output
http-server -p 1314 output
```

Then open `http://localhost:1314` in your browser.

If something goes wrong, check out https://github.com/jonsterling/forest .

In order to use `dvisvgm` required by forester to compile LaTeX to SVG, I have to:

```bash
brew uninstall textlive
brew install --cask mactex
```

See https://tex.stackexchange.com/a/676179/75671 for why.
