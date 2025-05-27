// bun add mermaid
// Similar implementation pattern to markdownit.js, but for mermaid diagrams
import mermaid from 'mermaid'

// Configure mermaid with appropriate settings
mermaid.initialize({
    startOnLoad: false,
    securityLevel: 'loose',
    theme: 'forest',
    // fontFamily: 'trebuchet ms, verdana, arial',
})

// Use an async function to properly handle rendering with await
const renderMermaidDiagrams = async () => {
    const mermaidTags = document.querySelectorAll('.mermaid.grace-loading')
    console.log(`Found ${mermaidTags.length} mermaid elements to render`)

    for (let i = 0; i < mermaidTags.length; i++) {
        const mermaidTag = mermaidTags[i]
        const mermaidCode = mermaidTag.textContent.trim()

        // Generate a unique ID for this diagram if it doesn't have one
        if (!mermaidTag.id) {
            mermaidTag.id = `mermaid-${Math.random().toString(36).substring(2, 10)}`
        }

        try {
            // Create a container for the rendered diagram
            const container = document.createElement('div')

            // Use await to handle the promise
            const { svg, bindFunctions } = await mermaid.render(
                `${mermaidTag.id}-svg`,
                mermaidCode,
            )

            // Set the container's innerHTML to the SVG
            container.innerHTML = svg

            // Clear the mermaid tag but keep the element itself
            mermaidTag.innerHTML = ''

            // Append the SVG to the mermaid tag
            mermaidTag.appendChild(container.firstChild)

            // console.debug('Diagram rendered successfully:', mermaidTag)

            if (bindFunctions) {
                bindFunctions(mermaidTag)
            }

            mermaidTag.classList.remove('grace-loading')
        } catch (err) {
            console.error('Error rendering mermaid diagram:', err)
            mermaidTag.innerHTML = `<div class="mermaid-error">Error: ${err.message}</div>`
            mermaidTag.classList.remove('grace-loading')
        }
    }
}

// Execute the async function
renderMermaidDiagrams().catch((err) => {
    console.error('Failed to render mermaid diagrams:', err)
})
