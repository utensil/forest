import { ImageEffectRenderer } from 'https://esm.sh/@mediamonks/image-effect-renderer@2.4.0'

// uts begin adapted from https://lygia.xyz/resolve.js

// import resolveLygia from "https://lygia.xyz/resolve.esm.js"

async function resolveIncludesAsync(lines) {
    if (!Array.isArray(lines))
        lines = lines.split(/\r?\n/);
  
    let src = "";
    const response = await Promise.all(
        lines.map(async (line, i) => {
            const line_trim = line.trim();
            if (line_trim.startsWith('#include "lygia')) {
                let include_url = line_trim.substring(15);
                include_url = "https://lygia.xyz" + include_url.replace(/\"|\;|\s/g, "");
                console.debug("fetching", include_url);
                return fetch(include_url).then((res) => res.text());
            }
            // uts begin
            else if (line_trim.startsWith('#include "') ) {
                let include_url = line_trim.substring(10);
                include_url = include_url.replace(/\"|\;|\s/g,'');
                console.debug("fetching", include_url);
                return fetch(include_url).then((res) => res.text());
            }
            // uts end
            else
                return line;
        })
    );
  
    return response.join("\n");
}

// uts end

const options = { loop: true };

const embeded_shaders = document.querySelectorAll('.embeded-shader');

embeded_shaders.forEach((element) => {
    let shader = element.textContent;
    element.textContent = '';

    resolveIncludesAsync(shader).then((shader) => {
        const renderer = ImageEffectRenderer.createTemporary(element, shader, options);
    });
});