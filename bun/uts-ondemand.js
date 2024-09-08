const load_script = (src) => {
    console.log(`loading ${src}`);
    const script = document.createElement('script');
    script.type = 'module';
    script.src = src;
    document.head.appendChild(script);
}

document.addEventListener('DOMContentLoaded', async () => {

    const markdownit_tags = document.querySelectorAll('.markdownit.lazy-loading');

    if (markdownit_tags.length != 0) {
        load_script('markdownit.js');
    }

    const typst_tags = document.querySelectorAll('.typst-root.lazy-loading');

    if (typst_tags.length != 0) {
        load_script('typst.js');
    }

    const pikchr_tags = document.querySelectorAll('.pikchr-root.lazy-loading');

    if (pikchr_tags.length != 0) {
        load_script('pikchr.js');
    }

    const code_tags = document.querySelectorAll('article code.highlight.lazy-loading');

    if (code_tags.length != 0) {
        load_script('shiki.js');
    }

    const embeded_shaders = document.querySelectorAll('.embeded-shader');

    if (embeded_shaders.length != 0) {
        load_script('shader.js');
    }

    const embeded_shadertoys = document.querySelectorAll('.embeded-shadertoy');

    if (embeded_shadertoys.length != 0) {
        load_script('shadertoy.js');
    }

    const embeded_usegpus = document.querySelectorAll('.usegpu');

    if (embeded_usegpus.length != 0) {
        load_script('usegpu.js');
    }
});