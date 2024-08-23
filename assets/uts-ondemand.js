const load_script = (src) => {
    console.log(`loading ${src}`);
    const script = document.createElement('script');
    script.type = 'module';
    script.src = src;
    document.head.appendChild(script);
}

document.addEventListener('DOMContentLoaded', async () => {

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
});