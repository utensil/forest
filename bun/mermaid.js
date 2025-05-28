// bun add mermaid
// Similar implementation pattern to markdownit.js, but for mermaid diagrams
import mermaid from 'mermaid'

// Configure mermaid with appropriate settings
mermaid.initialize({
    startOnLoad: false,
    securityLevel: 'loose',
    // best effort theming on light/dark mode loading/switching
    // light -> colorful forest theme on first load, colorful purple theme on switching to dark mode, then refresh to get a neutral dark mode
    // dark -> neutral dark mode on first load, neutral light mode on switching to light mode, then refresh to get to a colorful forest theme
    theme: document.documentElement.dataset.appliedMode == 'dark' ? 'neutral' : 'forest',
})

await mermaid.run({
    querySelector: '.mermaid.grace-loading',
})

// then remove grace-loading class for them
for (const el of document.querySelectorAll('.mermaid.grace-loading')) {
    el.classList.remove('grace-loading')
}
