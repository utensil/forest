import { getFactory, initGiNaC } from 'ginac-wasm'
// bun add ginac-wasm
import ginac_wasm from 'ginac-wasm/dist/ginac.wasm'
import { renderDemoError, renderDemoResults } from './demo-output'
;(async () => {
    try {
        const GiNaC = await initGiNaC(`/forest/${ginac_wasm}`)
        const g = getFactory()

        const expressions = GiNaC([
            // 2 * 3 = 6
            g.mul(g.numeric('2'), g.numeric('3')),
            // x + 2x = 3x
            g.add(g.symbol('x'), g.mul(g.numeric('2'), g.symbol('x'))),
            // (2*sin(x))' = 2*cos(x)
            g.diff(g.mul(g.numeric('2'), g.sin(g.symbol('x'))), g.symbol('x')),
            // internal parser of GiNaC
            g.parse('x^3 + 3*x + 1'),
        ])
        console.log(expressions)

        console.log(
            GiNaC([
                g.numeric('2'),
                g.numeric('3'),
                // reference first and second items from the array => 2*3 = 6
                g.mul(g.ref(0), g.ref(1)),
            ]),
        )

        // Besides the string output format, GiNaC can generate traversable JSON.
        console.dir(
            GiNaC(
                [
                    // 2*sin(x)
                    g.mul(g.numeric('2'), g.sin(g.symbol('x'))),
                ],
                { json: true },
            ),
            { depth: null },
        )

        renderDemoResults('ginac', [
            ['2 × 3', expressions[0]?.string ?? 'no result'],
            ['x + 2x', expressions[1]?.string ?? 'no result'],
            ['d/dx (2 sin(x))', expressions[2]?.string ?? 'no result'],
            ['parse(x³ + 3x + 1)', expressions[3]?.string ?? 'no result'],
        ])
    } catch (error) {
        console.error(error)
        renderDemoError('ginac', error)
    }
})()
