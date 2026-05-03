import path from 'node:path'
import Bun from 'bun'
import type { BunPlugin } from 'bun'

const args = process.argv.slice(2)

// console.log(args);

const wgslLoader: BunPlugin = {
    name: 'wgsl',
    async setup(build) {
        const { transpileWGSL } = await import('@use-gpu/shader/wgsl')

        // when a .wgsl file is imported...
        build.onLoad({ filter: /\.(wgsl)$/ }, async (args) => {
            // read and parse the file
            const source = await Bun.file(args.path).text()
            const exports = transpileWGSL(source, args.path)

            // console.log(exports);

            // and returns it as a module
            return {
                contents: exports,
                // exports,
                loader: 'js', // special loader for JS objects
            }
        })
    },
}

// bun 1.2.x doesn't reliably pick the `browser` exports condition for
// @rose-lang/wasm (used by @penrose/core >=3.3.0); alias to browser.js directly.
// The matching WASM asset is copied below after a successful build.
const aliases: Record<string, { jsEntry: string; wasmAssets: string[] }> = {
    '@rose-lang/wasm': {
        jsEntry: 'node_modules/@rose-lang/wasm/dist/browser.js',
        wasmAssets: ['node_modules/@rose-lang/wasm/dist/wbg/rose_web_bg.wasm'],
    },
}

const result = await Bun.build({
    entrypoints: [args[0]],
    outdir: './output/forest',
    target: 'browser',
    minify: true,
    plugins: [wgslLoader],
    alias: Object.fromEntries(
        Object.entries(aliases).map(([pkg, { jsEntry }]) => [
            pkg,
            path.join(import.meta.dir, jsEntry),
        ]),
    ),
})

if (!result.success) {
    console.error('Build failed')
    for (const message of result.logs) {
        // Bun will pretty print the message object
        console.error(message)
    }
} else {
    // Copy WASM assets for aliased packages — bun doesn't auto-copy npm WASM files.
    // These must come from the same dist/ tree as the aliased JS entry.
    for (const { wasmAssets } of Object.values(aliases)) {
        for (const wasmPath of wasmAssets) {
            const src = path.join(import.meta.dir, wasmPath)
            const dest = path.join(
                import.meta.dir,
                'output/forest',
                path.basename(src),
            )
            await Bun.write(dest, Bun.file(src))
        }
    }
}
