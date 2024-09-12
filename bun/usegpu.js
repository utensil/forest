// bun add @use-gpu/webgpu
// Follows https://usegpu.live/docs/guides-webgpu-canvas
import React, { render } from '@use-gpu/live';
import { createRoot } from 'react-dom/client'
import { WebGPU, AutoCanvas, Canvas } from '@use-gpu/webgpu';
import { FullScreen } from '@use-gpu/workbench';
import { wgsl } from '@use-gpu/shader/wgsl';
import { Loop, Pass, RawFullScreen, RawTexture } from '@use-gpu/workbench';

// adapted from the default new compute.toys shader
const shader = wgsl`
//   @link fn getSample(i: u32) -> vec4<f32> {};
//   @link fn getSize() -> vec4<u32> {};

// @link fn getTexture(uv: vec2<f32>) -> vec4<f32> {}
@link fn getTextureSize() -> vec2<f32> {}
@link fn getTargetSize() -> vec2<f32> {}

fn rand(co: vec2<f32>) -> f32
{
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

fn main(uv: vec2<f32>) -> vec4<f32> {
    let size = getTextureSize(); // getSize();
    let fragCoord = vec2f(f32(uv.x) + .5, f32(size.y - uv.y) - .5);
    let fragCoordNormalized = fragCoord / vec2f(size);

    // Time varying pixel colour
    var col = .5 + .5 * cos(rand(uv.xy) + uv.xyx + vec3<f32>(0.,2.,4.));

    // Convert from gamma-encoded to linear colour space
    col = pow(col, vec3<f32>(2.2));

    return vec4<f32>(col, 1.0);
  }
`;

const embeded_usegpus = document.querySelectorAll('.usegpu');

render(() => {
        return (
          <WebGPU>
            <AutoCanvas
              selector={".usegpu"}
              samples={4}
            >
                <Loop>
                    <Pass>
                        <FullScreen shader={shader} />
                    </Pass>
                </Loop>
            </AutoCanvas>
          </WebGPU>
        )
      });


// const embeded_shaders = document.querySelectorAll('.usegpu');

// embeded_shaders.forEach((element) => {
//     let shader = element.textContent;
//     element.textContent = '';

//     element.classList.add('lazy-loading');

//     let handleMouseOver = (event) => {
//         element.removeEventListener('mouseover', handleMouseOver);
//         resolveIncludesAsync(shader).then((shader) => {
//             element.classList.remove('lazy-loading');

            

//         });
//     };

//     element.addEventListener('mouseover', handleMouseOver);
// });

