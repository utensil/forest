const load_script = (src) => {
    console.log(`loading ${src}`);
    const script = document.createElement('script');
    script.type = 'module';
    script.src = src;
    document.head.appendChild(script);
}

document.addEventListener('DOMContentLoaded', async () => {

    const markdownit_tags = document.querySelectorAll('.markdownit-raw');

    if (markdownit_tags.length != 0) {
        load_script('markdownit.js');
    }

    const code_tags = document.querySelectorAll('article code');

    if (code_tags.length != 0) {
        load_script('shiki.js');
    }

    const embeded_shaders = document.querySelectorAll('.embeded-shader');

    if (embeded_shaders.length != 0) {
        load_script('shader.js');
    }

    const r3f_root = document.querySelector('#r3f-root');

    if(r3f_root) {
        load_script('hello-react-three-fiber.js');
    }

    const three2svg_root = document.querySelector('#three2svg-root');

    if(three2svg_root) {
        load_script('test-three-to-svg.js');
    }
});