// bun add @use-gpu/webgpu
// Follows https://usegpu.live/docs/guides-webgpu-canvas
import React, { render } from '@use-gpu/live';
import { createRoot } from 'react-dom/client'
import { WebGPU, AutoCanvas, Canvas } from '@use-gpu/webgpu';
import { FullScreen } from '@use-gpu/workbench';
import { wgsl } from '@use-gpu/shader/wgsl';
import { Loop, Pass, RawFullScreen, RawTexture } from '@use-gpu/workbench';

const shader = wgsl`
//   @link fn getSample(i: u32) -> vec4<f32> {};
//   @link fn getSize() -> vec4<u32> {};

  fn main(uv: vec2<f32>) -> vec4<f32> {
    let size = vec4<u32>(3, 4, 5, 6); // getSize();
    let iuv = vec2<u32>(uv * vec2<f32>(size.xy));
    let i = iuv.x + iuv.y * size.x;

    let value = vec4<f32>(3.0, 4.0, 5.0, 6.0); // getSample(i);
    let tone = normalize(vec3<f32>(0.5 + value.xy, 1.0));
    let color = vec3<f32>(
      tone.x * tone.x * tone.z + tone.y * tone.y * tone.y,
      tone.y * tone.z,
      tone.z + tone.y * tone.y
    ) * value.z;

    let b = color.b;
    let boost = vec3<f32>(b*b*b*.25, b*b*.25 + b*.125, 0.0);
    let mapped = (1.0 - 1.0 / (max(vec3<f32>(0.0), (color + boost*0.5) * 2.0) + 1.0));

    return vec4<f32>(mapped, 1.0);
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
                        <RawFullScreen texture={shader} />
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

