# Utensil's Forest

[![Built with Forester](https://img.shields.io/badge/Built_with-Forester-27560f?style=flat)](https://www.jonmsterling.com/jms-005P.xml)

https://utensil.github.io/forest/

## Development

[![Bundled with Bun](https://img.shields.io/badge/Bundled_with-Bun-f9f1e2?style=flat)](https://bun.sh) [![Styled with Lightning CSS](https://img.shields.io/badge/Styled_with-Lightning_CSS-faba32?style=flat)](https://lightningcss.com) [![Linted with Biome](https://img.shields.io/badge/Linted_with-Biome-60a5fa?style=flat&logo=biome)](https://biomejs.dev)

### Initial Setup

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
```

To initialize `theme` directory, review and run `./thm.sh`.

Add a `forest.toml`, then:

```bash
forester new --dest=trees --prefix=uts
```
### How to run

Run `./dev.sh` to watch the modified files and serve them to be browsed.

Then open `http://localhost:1314` in your browser.

`./dev.sh` internally run `./build.sh` to build the forest and its dependencies. `./build.sh` is also used in CI, check out `.github/workflows/gh-pages.yml` for more details.

### Trouble Shooting

If something goes wrong, check out https://github.com/jonsterling/forest .

Locally I will

```bash
git clone https://git.sr.ht/~jonsterling/public-trees jms
```

so I can check Jon Sterling's use of Forester conveniently.

In order to use `dvisvgm` required by forester to compile LaTeX to SVG, I have to:

```bash
brew uninstall texlive
brew install --cask mactex
```

See https://tex.stackexchange.com/a/676179/75671 for why.

### Experimental features

#### `bun`

I'm experimenting with authoring `js/ts/jsx/tsx` using [bun](https://bun.sh/), so I also need to run

```bash
curl -fsSL https://bun.sh/install | bash
# source ~/.bashrc
source ~/.zshrc
```

to install `bun`.

Rendering `js/ts/jsx/tsx` are also done by `dev.sh` in development with watch support or `build.sh` in CI. Manually this is:

```bash
bun build ./bun/<file-name> --outdir output
```

To use any package, just figure out the package name from the import and run `bun install <package-name>`, `package.json` will be updated by `bun`.

#### WASM

I'm also experimenting with WebAssembly, and some of the JS/TS code will rely on WASM.

As long as one has working `bun` and [rustup](https://rustup.rs/), the `build.sh` should take care of the rest.

## License

See [REUSE.md](REUSE.md) for details.
