const load_script = (src) => {
    console.debug(`loading ${src}`)
    const script = document.createElement('script')
    script.type = 'module'
    script.src = src
    document.head.appendChild(script)
}

const register = (selector, script) => {
    const tags = document.querySelectorAll(selector)

    if (tags.length !== 0) {
        load_script(script)
    }
}

document.addEventListener('DOMContentLoaded', async () => {
    register('.markdownit', 'markdownit.js')
    register('.typst-root', 'typst.js')
    register('.pikchr-root', 'pikchr.js')
    register('article code.highlight', 'shiki.js')
    register('.embeded-shader', 'shader.js')
    register('.embeded-shadertoy', 'shadertoy.js')
    register('.usegpu', 'usegpu.js')
    register('.wgputoy', 'wgputoy.js')
    register('.graphviz-root', 'graphviz.js')
    register('.d3-graphviz-root', 'd3-graphviz.js')

    const hostname = window.location.hostname

    if (hostname === 'localhost' || hostname === '127.0.0.1') {
        load_script('live.js')
    }
})
