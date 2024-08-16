import { ImageEffectRenderer } from 'https://esm.sh/@mediamonks/image-effect-renderer@2.4.0'
import resolveLygia from "https://lygia.xyz/resolve.esm.js"

// const shader = `
// `;

const options = { loop: true };

const embeded_shaders = document.querySelectorAll('.embeded-shader');

embeded_shaders.forEach((element) => {
    let shader = element.textContent;
    element.textContent = '';
    
    shader = resolveLygia(shader);
    console.log(shader.substring(0, 100));
    const renderer = ImageEffectRenderer.createTemporary(element, shader, options);
});