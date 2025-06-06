// bun add markmap-lib markmap-view
// Similar implementation pattern to mermaid.js for rendering markmap elements
import { Transformer, builtInPlugins } from 'markmap-lib'
import { Markmap, loadCSS, loadJS, refreshHook } from 'markmap-view'

// Initialize the transformer with default plugins
// const transformer = new Transformer([...builtInPlugins])
const transformer = new Transformer()

// Use an async function to properly handle rendering
const renderMarkmapDiagrams = async () => {
    const markmapTags = document.querySelectorAll('.markmap.grace-loading')
    console.log(`Found ${markmapTags.length} markmap elements to render`)

    for (let i = 0; i < markmapTags.length; i++) {
        const markmapTag = markmapTags[i]
        const markmapCode = markmapTag.textContent.trim()

        try {
            // Transform the Markdown content to markmap data
            const { root, features } = transformer.transform(markmapCode)

            console.debug('Transformed markmap data:', root, features)

            const { styles, scripts } = transformer.getUsedAssets(features)

            if (styles && loadCSS) loadCSS(styles)
            if (scripts && loadJS) {
                loadJS(scripts, { getMarkmap: () => ({ refreshHook }) })
            }

            // Create a container for the rendered markmap
            const container = document.createElementNS(
                'http://www.w3.org/2000/svg',
                'svg',
            )

            container.style.width = '100%'
            container.style.minHeight = '70vh'

            // Clear the markmap tag content but keep the element itself
            markmapTag.innerHTML = ''

            // Append the container to the markmap tag
            markmapTag.appendChild(container)

            // Render the markmap
            const markmap = Markmap.create(
                container,
                {
                    pan: false,
                    zoom: false,
                },
                root,
            )

            // markmap.renderData();
            // markmap.fit();

            console.debug('Markmap rendered successfully:', markmapTag)

            // Remove the loading class
            markmapTag.classList.remove('grace-loading')
        } catch (err) {
            console.error('Error rendering markmap diagram:', err)
            markmapTag.innerHTML = `<div class="markmap-error">Error: ${err.message}</div>`
            markmapTag.classList.remove('grace-loading')
        }
    }
}

// Execute the async function
renderMarkmapDiagrams().catch((err) => {
    console.error('Failed to render markmap diagrams:', err)
})
