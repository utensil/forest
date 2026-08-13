import init, { create_renderer } from '../lib/wgputoy/pkg'

interface CustomUniforms {
    [key: string]: number
}

const initialized = init()

function showError(element: Element, message: string): void {
    element.classList.remove('lazy-loading')
    element.classList.add('wgputoy-error')
    element.textContent = message
}

async function startToy(element: Element): Promise<void> {
    const canvas = document.createElement('canvas')
    canvas.id = `wgputoy-${Math.random().toString(36).substring(7)}`

    let shader = element.textContent || ''
    let custom: CustomUniforms = {}
    const customAttr = element.getAttribute('data-custom')
    if (customAttr) {
        custom = JSON.parse(customAttr)
    }
    element.innerHTML = ''
    element.classList.add('lazy-loading')

    try {
        if (!('gpu' in navigator)) {
            showError(element, 'This browser does not support WebGPU.')
            return
        }

        await initialized
        element.classList.remove('lazy-loading')
        element.appendChild(canvas)

        const context = canvas.getContext('webgpu')
        if (!context) {
            showError(element, 'WebGPU is unavailable for this canvas.')
            return
        }

        const presentationFormat = navigator.gpu.getPreferredCanvasFormat()
        const adapter = await navigator.gpu.requestAdapter()
        if (!adapter) {
            showError(element, 'No WebGPU adapter is available.')
            return
        }

        const device = await adapter.requestDevice()
        context.configure({ device, format: presentationFormat })

        const renderer = await create_renderer(
            element.clientWidth,
            element.clientHeight,
            canvas.id,
        )
        renderer.on_success = () => {}
        renderer.on_error = (error) => {
            console.error(error)
            showError(element, `WebGPU shader error: ${error}`)
        }

        shader = shader.replace(
            '@group(0) @binding(5) var<uniform> custom: Custom;',
            '',
        )

        if (Object.keys(custom).length > 0) {
            renderer.set_custom_floats(
                Object.keys(custom),
                Float32Array.from(Object.values(custom)),
            )
        }

        const processedShader = await renderer.preprocess(shader)
        if (!processedShader) {
            showError(element, 'WebGPU shader preprocessing failed.')
            return
        }

        let start: number | undefined
        let last = 0
        renderer.compile(processedShader)

        const step = (timestamp: DOMHighResTimeStamp) => {
            if (start === undefined) {
                start = timestamp
            }
            const elapsed = timestamp - start
            renderer.set_time_elapsed(elapsed / 1000.0)
            renderer.set_time_delta((elapsed - last) / 1000.0)
            last = elapsed
            renderer.render()
            requestAnimationFrame(step)
        }

        requestAnimationFrame(step)
    } catch (error) {
        console.error(error)
        showError(
            element,
            `WebGPU renderer failed: ${error instanceof Error ? error.message : String(error)}`,
        )
    }
}

const embeddedWgputoys = document.querySelectorAll('.wgputoy')
const observer = new IntersectionObserver(
    (entries) => {
        for (const entry of entries) {
            if (entry.isIntersecting) {
                observer.unobserve(entry.target)
                void startToy(entry.target)
            }
        }
    },
    { rootMargin: '200px' },
)

for (const element of embeddedWgputoys) {
    observer.observe(element)
}
