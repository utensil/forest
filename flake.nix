{
  description = "utensil forest SSG toolchains — tectonic + forester + WASM pkgs (pinned, cache-reusable; mirrors blog's flake pattern)";

  inputs = {
    # Pinned nixpkgs — nixos-unstable as of 2026-05-29 (sha 64c08a7ca0…). Recent
    # enough that pkgs.tectonic / pkgs.wasm-pack carry .version, and forester
    # should be available. Full commit hash so input resolution doesn't go via
    # the GH API.
    nixpkgs.url = "github:NixOS/nixpkgs/64c08a7ca051951c8eae34e3e3cb1e202fe36786";
  };

  outputs = { self, nixpkgs }:
    let
      # Linux only — we build/run on the GH Actions runner (x86_64) and on
      # tangled Spindle (x86_64). aarch64 included for local nix develop.
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAll = nixpkgs.lib.genAttrs systems;
      pkgsFor = system: import nixpkgs { inherit system; };

      # ---- forest-tectonic ---------------------------------------------------
      # tectonic LaTeX engine + pre-warmed CTAN cache (built from a tiny doc
      # so the render container starts with the packages it needs already
      # downloaded). Replaces TeX Live 2025 scheme-full (~7GB) — tectonic
      # binary ~30-50MB, cache ~200-300MB.
      #
      # NB: needs network at build time to populate the cache. Within nix
      # sandbox=false. Fine on the depot job (build-depot.yml runs with
      # sandbox=false in nix.conf to match blog's pattern); render then
      # reuses the snapshot offline.
      # Literal version strings everywhere — older nixpkgs wrap tectonic with
      # a derivation that lacks an exposed .version, and we don't want the
      # flake eval to depend on that. Bump as we move pins.
      tectonicVersion = "0.15-with-cache";
      foresterVersion = "5ab7277";
      wasmPkgsVersion = "wgputoy-60d0bec+egglog-8d9b10e+rhai-9fa8066";
      texliveVersion = "small";

      # ---- forest-texlive ---------------------------------------------------
      # forester internally shells out to plain `latex` (the DVI engine) for
      # inline-math rendering — tectonic only writes PDF, isn't a drop-in.
      # nixery rejects `texliveSmall` from the URL path (its Docker name
      # rules forbid uppercase). So bundle it via the flake instead — same
      # NAR closure pattern as tectonic + forester.
      forestTexliveFor = pkgs:
        # forester's inline-math job.tex uses \documentclass{standalone}
        # plus \input{diagrams}/\input{string-diagrams} which pull in
        # tikz-cd + xy. scheme-small alone misses standalone.cls; combine
        # explicitly so we know what's in the closure.
        let texCombo = pkgs.texlive.combine {
          # scheme-medium subsumes scheme-small + a few hundred more packages.
          # Iterating individual packages was running into whack-a-mole
          # (standalone → newpx → xstring → mweights → …). Medium gets us
          # everything common forester preambles touch in one closure (~700 MB
          # raw, ~250 MB NAR after zstd-19). Still well under scheme-full's
          # multi-GB footprint.
          inherit (pkgs.texlive) scheme-medium
            # Extras not in medium that we already KNOW forester uses:
            standalone tikz-cd preview varwidth adjustbox collectbox
            newpx newtx kastrup stmaryrd;
        };
        in pkgs.stdenv.mkDerivation {
          pname = "forest-texlive";
          version = "${texliveVersion}+standalone+tikz-cd";
          dontUnpack = true;
          dontConfigure = true;
          nativeBuildInputs = [ texCombo ];
          buildPhase = ''
            runHook preBuild
            ${texCombo}/bin/latex --version | head -1
            ${texCombo}/bin/kpsewhich standalone.cls
            runHook postBuild
          '';
          installPhase = ''
            runHook preInstall
            mkdir -p $out
            ln -s ${texCombo}/bin $out/bin
            ln -s ${texCombo}/share $out/share || true
            printf '%s\n' \
              'export PATH="'$out'/bin:''${PATH:-}"' \
              > $out/env.sh
            runHook postInstall
          '';
          meta.description = "texlive scheme-small + standalone/tikz-cd/xy combo for forester";
        };

      forestTectonicFor = pkgs: pkgs.stdenv.mkDerivation {
        pname = "forest-tectonic";
        version = tectonicVersion;

        # No source — we build off the nixpkgs tectonic binary plus a tiny
        # warmup .tex file that pulls every package the real forest build
        # is expected to need.
        dontUnpack = true;
        dontConfigure = true;

        nativeBuildInputs = [ pkgs.tectonic pkgs.cacert ];

        buildPhase = ''
          runHook preBuild
          export HOME=$TMPDIR
          export TECTONIC_CACHE_DIR=$HOME/.cache/Tectonic
          mkdir -p "$TECTONIC_CACHE_DIR"
          # Warmup: a representative doc that loads the heavy packages forest
          # uses. Iterate this — add \usepackage{...} lines as the forest LaTeX
          # surfaces missing packages on the first real run.
          cat > warmup.tex <<'WARMUP'
          \documentclass[a4paper]{article}
          \usepackage{amsmath, amssymb, amsthm}
          \usepackage{xcolor}
          \usepackage{tikz}
          \usepackage{hyperref}
          \usepackage{listings}
          \begin{document}
          Hello world.
          \end{document}
          WARMUP
          tectonic --outdir . warmup.tex || true
          ls -la "$TECTONIC_CACHE_DIR" || true
          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall
          mkdir -p $out/bin $out/share
          ln -s ${pkgs.tectonic}/bin/tectonic $out/bin/tectonic
          # snapshot the warmed cache under $out/share so render workflow
          # can `cp -r $out/share/tectonic-cache ~/.cache/Tectonic`.
          if [ -d "$TECTONIC_CACHE_DIR" ]; then
            cp -r "$TECTONIC_CACHE_DIR" $out/share/tectonic-cache
          fi
          # env.sh — source this on Spindle to wire HOME + cache + PATH
          cat > $out/env.sh <<EOSH
          export PATH="$out/bin:''${PATH:-}"
          export TECTONIC_CACHE_DIR="''${HOME:-/tmp}/.cache/Tectonic"
          mkdir -p "''${TECTONIC_CACHE_DIR}"
          if [ -d "$out/share/tectonic-cache" ]; then
            cp -rn "$out/share/tectonic-cache/." "''${TECTONIC_CACHE_DIR}/" 2>/dev/null || true
          fi
          EOSH
          runHook postInstall
        '';

        meta.description = "tectonic LaTeX engine + pre-warmed CTAN cache for forest";
      };

      # ---- forest-forester ---------------------------------------------------
      # Built from sr.ht commit 5ab7277 via opam (same pin as gh-pages.yml).
      # The closure (opam switch + forester binary) is captured under $out
      # so the render workflow can nix-store --import and put forester on PATH.
      #
      # NB: opam needs network at build time → sandbox=false on the depot.
      forestForesterFor = pkgs: pkgs.stdenv.mkDerivation {
        pname = "forest-forester";
        version = foresterVersion;

        dontUnpack = true;
        dontConfigure = true;

        nativeBuildInputs = with pkgs; [
          opam ocaml dune_3 gcc gnumake pkg-config
          libev cacert openssl gmp
          git curl
        ];
        buildInputs = with pkgs; [ libev openssl gmp ];

        buildPhase = ''
          runHook preBuild
          export HOME=$TMPDIR
          export OPAMROOT=$HOME/.opam
          export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
          # OPAMNODEPEXTS=1 stops opam from calling apt-cache / brew (it doesn't
          # have them in a nix sandbox; depexts are satisfied via nativeBuildInputs).
          # OPAMYES + assume-yes avoids interactive prompts on init failure.
          export OPAMNODEPEXTS=1 OPAMYES=1 OPAMNOSANDBOXING=1
          opam init --bare --no-setup --disable-sandboxing -y
          # Use ocaml-system (the nixpkgs ocaml we provide) so opam doesn't try
          # to compile ocaml-base-compiler from source (which then tries apt-cache
          # for system deps and fails on nixos containers).
          opam switch create forester --empty -y
          eval "$(opam env --switch=forester)"
          opam install ocaml-system -y
          opam pin add forester 'git+https://git.sr.ht/~jonsterling/ocaml-forester#5ab7277' --no-action -y
          opam install forester -y
          # nix stdenv doesn't ship `which`; check via command -v instead.
          command -v forester || { echo "::error::forester binary missing after opam install"; exit 1; }
          forester --version || true
          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall
          mkdir -p $out/bin $out/share/opam
          # Capture the forester binary directly.
          cp "$OPAMROOT/forester/bin/forester" $out/bin/forester
          # Also capture the opam switch directory so any forester runtime
          # data (xsl templates etc.) is preserved.
          cp -r "$OPAMROOT/forester/share" $out/share/opam/ || true
          cat > $out/env.sh <<EOSH
          export PATH="$out/bin:''${PATH:-}"
          EOSH
          runHook postInstall
        '';

        meta.description = "forester (Jon Sterling, sr.ht 5ab7277) — opam-built closure";
      };

      # ---- forest-wasm-pkgs --------------------------------------------------
      # Clones each upstream Rust→WASM crate at the pinned hash from build.sh,
      # runs wasm-pack build --target web --release, captures ONLY the pkg/
      # outputs (NOT the Rust toolchain, NOT the target/ dir). This is the
      # operator's "ship only the WASM, not the Rust" optimization — pkg/
      # dirs are 10s-100s of KB each.
      forestWasmPkgsFor = pkgs:
        let
          # `path` mirrors build.sh's `lib_path` arg — relative to the work
          # dir (where we clone the repo), points at the directory wasm-pack
          # runs in. For wgputoy/rhaiscript the cloned repo IS the wasm-pack
          # crate (path = name). For egglog the wasm-pack crate is a subdir
          # of the clone (path = "egglog/web-demo").
          pins = [
            { name = "wgputoy"; url = "https://github.com/compute-toys/wgpu-compute-toy.git";
              hash = "60d0bec4bd912a54d5049f2c28c1bd6a0916e5ec";
              path = "wgputoy"; }
            { name = "egglog"; url = "https://github.com/egraphs-good/egglog.git";
              hash = "8d9b10ec712106b21d10b7bf45d10c0f9d1d09c7";
              path = "egglog/web-demo"; }
            { name = "rhaiscript"; url = "https://github.com/rhaiscript/playground";
              hash = "9fa80661bc9eb69363ac86879826dcd8ccb604af";
              path = "rhaiscript"; }
          ];
        in pkgs.stdenv.mkDerivation {
          pname = "forest-wasm-pkgs";
          version = wasmPkgsVersion;

          dontUnpack = true;
          dontConfigure = true;

          nativeBuildInputs = with pkgs; [
            rustc cargo wasm-pack bun nodejs binaryen git cacert
            patch  # for nix/patches/wgputoy-surface-error-other.patch
            # wgputoy's .cargo/config.toml asks for lld as the linker.
            lld
          ];

          buildPhase = ''
            runHook preBuild
            export HOME=$TMPDIR
            export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
            mkdir -p $TMPDIR/work
            cd $TMPDIR/work
            ${pkgs.lib.concatMapStrings (p: ''
              echo "=== building ${p.name} ==="
              git clone --depth 1 "${p.url}" "${p.name}"
              # git fetch/checkout target the cloned repo (egglog/, wgputoy/, …).
              ( cd "${p.name}"
                git fetch --depth 1 origin "${p.hash}"
                git checkout "${p.hash}"
              )
              # wasm-pack runs in ${p.path} — for egglog the wasm-pack crate
              # lives at egglog/web-demo (a subdir of the clone); for the
              # others, path == name.
              ( cd "${p.path}"
                if [ "${p.name}" = "wgputoy" ]; then
                  # Two diff/context patches against upstream src/lib.rs +
                  # Cargo.toml — `patch -p1` fails loudly if upstream drifts,
                  # vs a bare sed that would silently move. Tracked in
                  # utensil/forest#54 (item 1) + #55 (wasm-opt strategy).
                  patch -p1 --no-backup-if-mismatch < ${./nix/patches/wgputoy-surface-error-other.patch}
                  test "$(grep -c 'SurfaceError::Other' src/lib.rs)" -eq 2 \
                    || { echo "::error::wgputoy patch produced unexpected arm count"; exit 1; }
                  patch -p1 --no-backup-if-mismatch < ${./nix/patches/wgputoy-wasm-opt-bulk-memory.patch}
                fi
                wasm-pack build --target web --release --out-dir pkg . -- --locked
                ls -la pkg
              )
            '') pins}
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            mkdir -p $out/pkg
            ${pkgs.lib.concatMapStrings (p: ''
              mkdir -p $out/pkg/${p.name}
              cp -r $TMPDIR/work/${p.path}/pkg/. $out/pkg/${p.name}/
            '') pins}
            ls -la $out/pkg
            runHook postInstall
          '';

          meta.description = "Pre-built WASM pkgs for forest (wgputoy + egglog + rhaiscript)";
        };

    in {
      packages = forAll (system:
        let pkgs = pkgsFor system; in {
          forest-tectonic = forestTectonicFor pkgs;
          forest-forester = forestForesterFor pkgs;
          forest-wasm-pkgs = forestWasmPkgsFor pkgs;
          forest-texlive = forestTexliveFor pkgs;
        }
      );

      # `nix develop` shells the toolchain — useful for local sanity checks.
      devShells = forAll (system:
        let pkgs = pkgsFor system; in {
          default = pkgs.mkShell {
            packages = [
              pkgs.tectonic pkgs.opam pkgs.bun pkgs.just pkgs.biome
              pkgs.uv pkgs.xsltproc pkgs.nodejs pkgs.wasm-pack
            ];
          };
        }
      );
    };
}
