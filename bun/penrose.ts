// Adapted from https://penrose.cs.cmu.edu/docs/ref/react
// bun install @penrose/core
import * as Penrose from '@penrose/core'

const fetch_text = async (url) => {
    const response = await fetch(url)
    return await response.text()
}

const penrose_roots = document.querySelectorAll('.penrose-root.loading')
for (const penrose_root of penrose_roots) {
    let trio = {}
    const penrose_root_trio = penrose_root.getAttribute('data-trio')
    if (penrose_root_trio) {
        // fetch trio json
        const response = await fetch(penrose_root_trio)
        const trio_spec = await response.json()
        // console.debug(trio_spec);
        const domain = await fetch_text(`./penrose/${trio_spec.domain}`)
        const substance = await fetch_text(`./penrose/${trio_spec.substance}`)
        const style = await fetch_text(`./penrose/${trio_spec.style[0]}`)
        const variation = trio_spec.variation || ''
        trio = { variation, domain, substance, style }
    } else {
        const domain = penrose_root.querySelector('.penrose-domain').textContent
        const substance =
            penrose_root.querySelector('.penrose-substance').textContent
        const style = penrose_root.querySelector('.penrose-style').textContent
        const variation = ''
        trio = { variation, domain, substance, style }
    }

    penrose_root.innerHTML = ''
    const dia = await Penrose.interactiveDiagram(
        trio,
        penrose_root,
        async () => undefined,
    )
    penrose_root.classList.remove('loading')
}
