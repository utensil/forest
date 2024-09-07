// bun install @use-gpu/webgpu
// Follows https://usegpu.live/docs/guides-webgpu-canvas

import { WebGPU, AutoCanvas } from '@use-gpu/webgpu';

const App = () => {
  return (
    <WebGPU>
      <AutoCanvas
        selector=".usegpu"
        samples={4}
      >

      </AutoCanvas>
    </WebGPU>
  )
};

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


