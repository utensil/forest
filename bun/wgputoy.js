import init, { create_renderer, WgpuToyRenderer } from '../lib/wgputoy/pkg';

await init();

const embeded_wgputoys = document.querySelectorAll('.wgputoy');

embeded_wgputoys.forEach(async (embeded_wgputoy) => {
    const canvas = document.createElement('canvas');
    canvas.id = 'wgputoy-' + Math.random().toString(36).substring(7);
    embeded_wgputoy.innerHTML = '';
    embeded_wgputoy.appendChild(canvas);

    if (canvas && canvas.getContext('webgpu') && 'gpu' in navigator) {
        const context = canvas.getContext('webgpu');
        const presentationFormat = navigator.gpu.getPreferredCanvasFormat();
        const adapter = await navigator.gpu.requestAdapter();
        if (adapter) {
            const device = await adapter.requestDevice();
            
            if (device) {
                context.configure({
                    device,
                    format: presentationFormat,
                });

                const width = embeded_wgputoy.clientWidth;
                const height = embeded_wgputoy.clientHeight;

                console.log(width, height);
            
                const renderer = await create_renderer(width, height, canvas.id);
            
                console.log(renderer);
            
                renderer.preprocess(`
                    @compute @workgroup_size(16, 16)
                    fn main_image(@builtin(global_invocation_id) id: vec3u) {
                        // Viewport resolution (in pixels)
                        let screen_size = textureDimensions(screen);
                    
                        // Prevent overdraw for workgroups on the edge of the viewport
                        if (id.x >= screen_size.x || id.y >= screen_size.y) { return; }
                    
                        // Pixel coordinates (centre of pixel, origin at bottom left)
                        let fragCoord = vec2f(f32(id.x) + .5, f32(screen_size.y - id.y) - .5);
                    
                        // Normalised pixel coordinates (from 0 to 1)
                        let uv = fragCoord / vec2f(screen_size);
                    
                        // Time varying pixel colour
                        var col = .5 + .5 * cos(time.elapsed + uv.xyx + vec3f(0.,2.,4.));
                    
                        // Convert from gamma-encoded to linear colour space
                        col = pow(col, vec3f(2.2));
                    
                        // Output to screen (linear colour space)
                        textureStore(screen, id.xy, vec4f(col, 1.));
                    }`).then(s => {
                        if (s) {
                            let start;
                            let last = 0;
                            renderer.compile(s);

                            const step = (timestamp) => {
                                if (start === undefined) {
                                  start = timestamp;
                                }
                                const elapsed = timestamp - start;
                              
                                renderer.set_time_elapsed(elapsed / 1000.0);
                                renderer.set_time_delta((elapsed - last) / 1000.0);

                                last = elapsed;

                                renderer.render();

                                requestAnimationFrame(step);
                            };
                              
                            requestAnimationFrame(step);
                        }
                });
            }
        }
    }


});