
// bun add @hpcc-js/wasm
import { Graphviz } from "@hpcc-js/wasm/graphviz"

const graphviz = await Graphviz.load()

const possible_layouts = [
    'circo', 'dot', 'fdp', 'sfdp', 'neato', 'osage', 'patchwork', 'twopi' // , 'nop', 'nop2'
]

const graphviz_roots = document.querySelectorAll('.graphviz-root.loading')
for (const graphviz_root of graphviz_roots) {
    const graphviz_source = graphviz_root.textContent
    let layout = graphviz_root.getAttribute('data-layout')
    if (!possible_layouts.includes(layout)) {
        // randomly choose a layout
        layout = possible_layouts[Math.floor(Math.random() * possible_layouts.length)]
        console.debug('randomly choose a layout:', layout)
    }

    graphviz_root.innerHTML = ''
    const graphviz_svg = graphviz.layout(graphviz_source, 'svg', layout)
    graphviz_root.innerHTML = graphviz_svg
    graphviz_root.classList.remove('loading')
}
