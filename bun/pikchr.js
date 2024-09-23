// bun install pikchr-wasm
// source repo: https://github.com/fabiospampinato/pikchr-wasm
// alternative: https://github.com/felixr/pikchr-wasm

import pikchr from 'pikchr-wasm'; // Default entrypoint, optimized for speed, ~76kb min+gzip
// import pikchr from 'pikchr-wasm/speed'; // Default entrypoint, optimized for speed, ~76kb min+gzip
// import pikchr from 'pikchr-wasm/size'; // Alternative entrypoint, optimized for bundle size, ~65kb min+gzip

await pikchr.loadWASM (); // First of all you need to load the WASM instance and wait for it

const pikchr_roots = document.querySelectorAll('.pikchr-root.loading');
pikchr_roots.forEach(async (pikchr_root) => {
    const pikchr_source = pikchr_root.textContent;
    pikchr_root.innerHTML = "";
    const pikchr_svg = pikchr.render(pikchr_source);
    pikchr_root.innerHTML = pikchr_svg;
    pikchr_root.classList.remove('loading');
});