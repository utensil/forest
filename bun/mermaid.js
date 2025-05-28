// bun add mermaid
// Similar implementation pattern to markdownit.js, but for mermaid diagrams
import mermaid from 'mermaid'

// Configure mermaid with appropriate settings
mermaid.initialize({
    startOnLoad: false,
    securityLevel: 'loose',
    theme: 'neutral',
})

await mermaid.run({
    querySelector: '.mermaid.grace-loading',
})

// then remove grace-loading class for them
for (const el of document.querySelectorAll('.mermaid.grace-loading')) {
    el.classList.remove('grace-loading')
}
