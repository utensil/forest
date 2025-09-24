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

const result = await Bun.build({
    entrypoints: [args[0]],
    outdir: './output/forest',
    target: 'browser',
    minify: true,
    plugins: [wgslLoader],
})

if (!result.success) {
    console.error('Build failed')
    for (const message of result.logs) {
        // Bun will pretty print the message object
        console.error(message)
    }
}
