import { getFactory, initGiNaC } from 'ginac-wasm'
// bun add ginac-wasm
import ginac_wasm from 'ginac-wasm/dist/ginac.wasm'

;(async () => {
    const GiNaC = await initGiNaC(ginac_wasm)
    const g = getFactory()

    console.log(
        GiNaC([
            // 2 * 3 = 6
            g.mul(g.numeric('2'), g.numeric('3')),
            // x + 2x = 3x
            g.add(g.symbol('x'), g.mul(g.numeric('2'), g.symbol('x'))),
            // (2*sin(x))' = 2*cos(x)
            g.diff(g.mul(g.numeric('2'), g.sin(g.symbol('x'))), g.symbol('x')),
            // internal parser of GiNaC
            g.parse('x^3 + 3*x + 1'),
        ]),
    )

    console.log(
        GiNaC([
            g.numeric('2'),
            g.numeric('3'),
            // reference first and second items from the array => 2*3 = 6
            g.mul(g.ref(0), g.ref(1)),
        ]),
    )

    // besides the string output format,
    // it can also generate traversable json structures
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
})()
