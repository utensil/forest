// bun add uwal

// based on https://github.com/UstymUkhman/uwal/blob/main/src/lessons/fundamentals/index.js
import { UWAL } from 'uwal'
import { renderDemoError, renderDemoResults } from './demo-output'

const uwalCompute = async (
    input: Float32Array,
    shader: string,
): Promise<number[]> => {
    // Run computations on the GPU:
    {
        // const input = new Float32Array([1, 3, 5]);

        const Computation = new (await UWAL.ComputePipeline('compute'))()

        const computeBuffer = Computation.CreateBuffer({
            size: input.byteLength,
            usage:
                GPUBufferUsage.STORAGE |
                GPUBufferUsage.COPY_SRC |
                GPUBufferUsage.COPY_DST,
        })

        Computation.WriteBuffer(computeBuffer, input)

        const module = Computation.CreateShaderModule(shader)
        Computation.CreatePipeline({ module })

        const bindGroup = Computation.CreateBindGroup(
            Computation.CreateBindGroupEntries({ buffer: computeBuffer }),
        )

        Computation.CreatePassDescriptor()
        Computation.SetBindGroups(bindGroup)
        Computation.Workgroups = input.length
        Computation.Compute()

        const resultBuffer = Computation.CreateBuffer({
            size: input.byteLength,
            usage: GPUBufferUsage.MAP_READ | GPUBufferUsage.COPY_DST,
        })

        Computation.CopyBufferToBuffer(
            computeBuffer,
            resultBuffer,
            resultBuffer.size,
        )
        Computation.SubmitCommandBuffer()

        await resultBuffer.mapAsync(GPUMapMode.READ)
        const result = new Float32Array(resultBuffer.getMappedRange())
        const values = Array.from(result)
        resultBuffer.unmap()
        return values
    }
}

const input = new Float32Array([1, 3, 5])

const shader = `
@group(0) @binding(0) var<storage, read_write> data: array<f32>;

@compute @workgroup_size(1)
fn compute(@builtin(global_invocation_id) id: vec3u)
{
    let i = id.x;
    data[i] *= 2;
}
`

try {
    const result = await uwalCompute(input, shader)
    console.log(result)
    renderDemoResults('uwal', [
        ['Input', '[1, 3, 5]'],
        ['GPU output', `[${result.join(', ')}]`],
    ])
} catch (error) {
    console.error(error)
    renderDemoError('uwal', error)
}
