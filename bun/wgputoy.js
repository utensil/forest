import init, { create_renderer, WgpuToyRenderer } from '../lib/wgputoy/pkg'

await init()

const embeded_wgputoys = document.querySelectorAll('.wgputoy')

embeded_wgputoys.forEach(async (element) => {
    const canvas = document.createElement('canvas')
    canvas.id = `wgputoy-${Math.random().toString(36).substring(7)}`

    let shader = element.textContent
    let custom = element.getAttribute('data-custom')
    // console.debug('custom', custom);
    if (custom) {
        custom = JSON.parse(custom)
    } else {
        custom = {}
    }
    element.innerHTML = ''
    element.classList.add('lazy-loading')

    const handleMouseOver = async (event) => {
        element.removeEventListener('mouseover', handleMouseOver)
        element.classList.remove('lazy-loading')
        element.appendChild(canvas)
        if (canvas?.getContext('webgpu') && 'gpu' in navigator) {
            const context = canvas.getContext('webgpu')
            const presentationFormat = navigator.gpu.getPreferredCanvasFormat()
            const adapter = await navigator.gpu.requestAdapter()
            if (adapter) {
                const device = await adapter.requestDevice()

                if (device) {
                    context.configure({
                        device,
                        format: presentationFormat,
                    })

                    const width = element.clientWidth
                    const height = element.clientHeight

                    // console.log(width, height);

                    const renderer = await create_renderer(
                        width,
                        height,
                        canvas.id,
                    )
                    renderer.on_success = () => {}
                    renderer.on_error = (error) => {
                        console.error(error)
                    }

                    // console.log(renderer);

                    shader = shader.replace(
                        '@group(0) @binding(5) var<uniform> custom: Custom;',
                        '',
                    )

                    // if custom has more than 0 keys
                    if (Object.keys(custom).length > 0) {
                        renderer.set_custom_floats(
                            Object.keys(custom),
                            Float32Array.from(Object.values(custom)),
                        )
                    }

                    renderer.preprocess(shader).then((s) => {
                        if (s) {
                            let start
                            let last = 0
                            renderer.compile(s)
                            // renderer.render();

                            const step = (timestamp) => {
                                if (start === undefined) {
                                    start = timestamp
                                }
                                const elapsed = timestamp - start

                                renderer.set_time_elapsed(elapsed / 1000.0)
                                renderer.set_time_delta(
                                    (elapsed - last) / 1000.0,
                                )

                                last = elapsed

                                renderer.render()

                                requestAnimationFrame(step)
                            }

                            requestAnimationFrame(step)
                        }
                    })
                }
            }
        }
    }

    element.addEventListener('mouseover', handleMouseOver)
})
