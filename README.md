This forest is initialized with the following command:

```bash
brew install opam bubblewrap watchexec
opam init --auto-setup --yes
opam update --yes
opam install forester --yes
forester --version

cd ~/projects/
git init forest
cd forest
git pull https://git.sr.ht/~jonsterling/forest-template

git remote add origin https://github.com/utensil/forest.git
git branch -M main
git push -u origin main

# git submodule deinit --all -f
# git rm theme -f
# rm -rf theme
# rm -rf .git/modules/theme
# git submodule add -f -b fix-data-taxon --name theme https://git.sr.ht/~utensil/forester-base-theme theme
# git submodule add -f --name theme https://git.sr.ht/~jonsterling/forester-base-theme theme
# git submodule add -f --name theme https://github.com/utensil/forester-base-theme theme
git submodule update --init --recursive
git submodule update --remote --merge
```

Add a `forest.toml`, then:

```bash
forester new --dest=trees --prefix=uts
```
Run `./dev.sh` to watch the modified files and serve them to be browsed.

Then open `http://localhost:1314` in your browser.

If something goes wrong, check out https://github.com/jonsterling/forest .

Locally I will

```bash
git clone https://git.sr.ht/~jonsterling/public-trees jms
```

so I can check Jon Sterling's use of Forester conveniently.

In order to use `dvisvgm` required by forester to compile LaTeX to SVG, I have to:

```bash
brew uninstall textlive
brew install --cask mactex
```

See https://tex.stackexchange.com/a/676179/75671 for why.
