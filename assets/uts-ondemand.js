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

    const code_tags = document.querySelectorAll('article code.highlight');

    if (code_tags.length != 0) {
        load_script('shiki.js');
    }

    const embeded_shaders = document.querySelectorAll('.embeded-shader');

    if (embeded_shaders.length != 0) {
        load_script('shader.js');
    }
});