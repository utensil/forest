import mermaid from 'mermaid'

const config = {
    startOnLoad: false,
    securityLevel: 'loose',
    theme:
        document.documentElement.dataset.appliedMode === 'dark'
            ? 'neutral'
            : 'forest',
}

mermaid.initialize(config)

await mermaid.run({
    querySelector: '.mermaid.grace-loading',
})

const graceLoadingElements = document.querySelectorAll('.mermaid.grace-loading')
for (const el of graceLoadingElements) {
    el.classList.remove('grace-loading')
}
