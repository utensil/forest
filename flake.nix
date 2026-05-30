{
  description = "utensil forest SSG toolchains — tectonic + forester + WASM pkgs (pinned, cache-reusable; mirrors blog's flake pattern)";

  inputs = {
    # Pinned nixpkgs (full commit hash, NOT a branch ref — input resolution
    # without the GitHub API avoids 403 rate-limits and fetches the tarball
    # directly). Picked to have recent tectonic + forester + wasm-pack.
    # NOTE: revision below is a placeholder; the first GH Actions run will
    # surface whether it has the packages we need. Bump as needed.
    nixpkgs.url = "github:NixOS/nixpkgs/cc6431d5598071f0021efc6c009c79e5b5fe1617";
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
      forestTectonicFor = pkgs: pkgs.stdenv.mkDerivation {
        pname = "forest-tectonic";
        version = "${pkgs.tectonic.version}-with-cache";

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
        version = "5ab7277-unstable";

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
          opam init --bare --no-setup --disable-sandboxing -y
          opam switch create forester ${pkgs.ocaml.version} -y
          eval "$(opam env --switch=forester)"
          opam pin add forester 'git+https://git.sr.ht/~jonsterling/ocaml-forester#5ab7277' --no-action -y
          opam install forester -y
          which forester
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
          pins = [
            { name = "wgputoy"; url = "https://github.com/compute-toys/wgpu-compute-toy.git";
              hash = "60d0bec4bd912a54d5049f2c28c1bd6a0916e5ec";
              path = "."; }
            { name = "egglog"; url = "https://github.com/egraphs-good/egglog.git";
              hash = "8d9b10ec712106b21d10b7bf45d10c0f9d1d09c7";
              path = "egglog/web-demo"; }
            { name = "rhaiscript"; url = "https://github.com/rhaiscript/playground";
              hash = "9fa80661bc9eb69363ac86879826dcd8ccb604af";
              path = "."; }
          ];
        in pkgs.stdenv.mkDerivation {
          pname = "forest-wasm-pkgs";
          version = "wgputoy-${builtins.substring 0 7 (builtins.elemAt (builtins.split " " "60d0bec4bd912a54d5049f2c28c1bd6a0916e5ec") 0)}";

          dontUnpack = true;
          dontConfigure = true;

          nativeBuildInputs = with pkgs; [
            rustc cargo wasm-pack bun nodejs binaryen git cacert
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
              ( cd "${p.name}"
                git fetch --depth 1 origin "${p.hash}"
                git checkout "${p.hash}"
                cd "${p.path}"
                wasm-pack build --target web --release --out-dir pkg .
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
              cp -r $TMPDIR/work/${p.name}/${p.path}/pkg/. $out/pkg/${p.name}/
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
