import { ImageEffectRenderer } from 'https://esm.sh/@mediamonks/image-effect-renderer@2.4.0'

// uts begin adapted from https://lygia.xyz/resolve.js

// import resolveLygia from "https://lygia.xyz/resolve.esm.js"

function getFile(url) {
    let httpRequest = new XMLHttpRequest();
    httpRequest.open("GET", url, false);
    httpRequest.send();
    if (httpRequest.status == 200)
        return httpRequest.responseText;
    else
        return "";
  }

function resolveLygia(lines) {
    if ( !Array.isArray(lines) ) {
        lines = lines.split(/\r?\n/);
    }

    let src = "";
    lines.forEach( (line, i) => {
        const line_trim = line.trim();
        if (line_trim.startsWith('#include "lygia') ) {
            let include_url = line_trim.substring(15);
            include_url = "https://lygia.xyz" + include_url.replace(/\"|\;|\s/g,'');
            src += getFile(include_url) + '\n';
        }
        // uts begin
        else if (line_trim.startsWith('#include "') ) {
            let include_url = line_trim.substring(10);
            include_url = include_url.replace(/\"|\;|\s/g,'');
            src += getFile(include_url) + '\n';
        }
        // uts end
        else {
            src += line + '\n';
        }
    });
    
    return src;
}

// uts end

const options = { loop: true };

const embeded_shaders = document.querySelectorAll('.embeded-shader');

embeded_shaders.forEach((element) => {
    let shader = element.textContent;
    element.textContent = '';
    
    shader = resolveLygia(shader);
    console.log(shader.substring(0, 100));
    const renderer = ImageEffectRenderer.createTemporary(element, shader, options);
});