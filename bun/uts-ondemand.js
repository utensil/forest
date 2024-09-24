const load_script = (src) => {
    console.debug(`loading ${src}`);
    const script = document.createElement('script');
    script.type = 'module';
    script.src = src;
    document.head.appendChild(script);
}

document.addEventListener('DOMContentLoaded', async () => {

    const markdownit_tags = document.querySelectorAll('.markdownit');

    if (markdownit_tags.length != 0) {
        load_script('markdownit.js');
    }

    const typst_tags = document.querySelectorAll('.typst-root');

    if (typst_tags.length != 0) {
        load_script('typst.js');
    }

    const pikchr_tags = document.querySelectorAll('.pikchr-root');

    if (pikchr_tags.length != 0) {
        load_script('pikchr.js');
    }

    const code_tags = document.querySelectorAll('article code.highlight');

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

    const embeded_wgputoys = document.querySelectorAll('.wgputoy');

    if (embeded_wgputoys.length != 0) {
        load_script('wgputoy.js');
    }

    // load_script('uwal.js');

    // load_script('hello-egglog.js');

    // load_script('hello-ginac.js');

    const hostname = window.location.hostname;
    
    if (hostname === 'localhost' || hostname === '127.0.0.1') {
        load_script('live.js');
    }
});