document.addEventListener('DOMContentLoaded', async () => {

    const code_tags = document.querySelectorAll('article code');

    if (code_tags.length != 0) {
        console.log('loading shiki.js');
        const script = document.createElement('script');
        script.type = 'module';
        script.src = 'shiki.js';
        document.head.appendChild(script);
    }

    const embeded_shaders = document.querySelectorAll('.embeded-shader');

    if (embeded_shaders.length != 0) {
        console.log('loading shader.js');
        const shaderScript = document.createElement('script');
        shaderScript.type = 'module';
        shaderScript.src = 'shader.js';
        document.head.appendChild(shaderScript);
    }
});