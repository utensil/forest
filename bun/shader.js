import { ImageEffectRenderer } from 'https://esm.sh/@mediamonks/image-effect-renderer@2.4.0'

// uts begin adapted from https://lygia.xyz/resolve.js

// import resolveLygia from "https://lygia.xyz/resolve.esm.js"

async function resolveIncludesAsync(lines) {
    if (!Array.isArray(lines)) lines = lines.split(/\r?\n/)

    const src = ''
    const response = await Promise.all(
        lines.map(async (line, i) => {
            const line_trim = line.trim()
            if (line_trim.startsWith('#include "lygia')) {
                let include_url = line_trim.substring(15)
                include_url = `https://lygia.xyz${include_url.replace(/\"|\;|\s/g, '')}`
                console.debug('fetching', include_url)
                return fetch(include_url).then((res) => res.text())
            }
            // uts begin
            if (line_trim.startsWith('#include "')) {
                let include_url = line_trim.substring(10)
                include_url = include_url.replace(/\"|\;|\s/g, '')
                console.debug('fetching', include_url)
                return fetch(include_url).then((res) => res.text())
            }
            // uts end
            return line
        }),
    )

    return response.join('\n')
}

// uts end

const options = { loop: true }

const embeded_shaders = document.querySelectorAll('.embeded-shader')

embeded_shaders.forEach((element) => {
    const shader = element.textContent
    element.textContent = ''

    element.classList.add('lazy-loading')

    const handleMouseOver = (event) => {
        element.removeEventListener('mouseover', handleMouseOver)
        resolveIncludesAsync(shader).then((shader) => {
            element.classList.remove('lazy-loading')
            const renderer = ImageEffectRenderer.createTemporary(
                element,
                shader,
                options,
            )
        })
    }

    element.addEventListener('mouseover', handleMouseOver)
})
