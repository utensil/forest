import { Billboard, CameraControls, Plane, Text } from '@react-three/drei'
import { Canvas, useFrame, useThree } from '@react-three/fiber'
import React, { useRef, useMemo, useState, useEffect } from 'react'
import { createRoot } from 'react-dom/client'
// The purpose of this file is to run shadertoy shaders without modification in React Three Fiber.
// All shaders without external resources (e.g. images as sampler2D from channels ) should work out of the box.
// This file is based on experiments in bun/hello-react-three-fiber.tsx
// References:
// - https://blog.maximeheckel.com/posts/the-study-of-shaders-with-react-three-fiber/
// - https://www.thefrontdev.co.uk/workflow-from-shadertoy-to-react-three-fiber-r3f
// - https://medium.com/@m.mhde96/implementing-a-shadertoy-in-react-three-fiber-eee4541a15b2
// bun install three react-dom react @react-three/fiber @react-three/drei
import * as THREE from 'three'

const defaults = {
    fragmentShaderPreamble: `varying vec2 vUv;
uniform vec3      iResolution;           // viewport resolution (in pixels)
uniform float     iTime;                 // shader playback time (in seconds)
// uniform float     iTimeDelta;            // render time (in seconds)
// uniform float     iFrameRate;            // shader frame rate
uniform int       iFrame;                // shader playback frame
// uniform float     iChannelTime[4];       // channel playback time (in seconds)
// uniform vec3      iChannelResolution[4]; // channel resolution (in pixels)
uniform vec4      iMouse;                // mouse pixel coords. xy: current (if MLB down), zw: click
// uniform samplerXX iChannel0..3;          // input channel. XX = 2D/Cube
// uniform vec4      iDate;                 // (year, month, day, time in seconds)
`,
    fragmentShaderPostemable: `void main() {

    // call void mainImage(out vec4 pixelColor, in vec2 pixelCoordinate)
    vec4 pixelColor;
    mainImage(pixelColor, vUv * iResolution.xy);
    gl_FragColor = pixelColor;
}`,
    vertexShader: `varying vec2 vUv;

void main() {
  vUv = uv;
  vec4 modelPosition = modelMatrix * vec4(position, 1.0);
  vec4 viewPosition = viewMatrix * modelPosition;
  vec4 projectedPosition = projectionMatrix * viewPosition;

  gl_Position = projectedPosition;
}`,
}

// uts begin adapted from https://lygia.xyz/resolve.js

// import resolveLygia from "https://lygia.xyz/resolve.esm.js"

async function resolveIncludesAsync(input) {
    const lines = Array.isArray(input) ? input : input.split(/\r?\n/)

    const src = ''
    const response = await Promise.all(
        lines.map(async (line, i) => {
            const line_trim = line.trim()
            if (line_trim.startsWith('#include "lygia')) {
                let include_url = line_trim.substring(15)
                include_url = `https://lygia.xyz${include_url.replace(/\"|\;|\s/g, '')}`
                console.debug('fetching', include_url)
                return fetch(include_url).then((res) => res.text())
            }
            // uts begin
            if (line_trim.startsWith('#include "')) {
                let include_url = line_trim.substring(10)
                include_url = include_url.replace(/\"|\;|\s/g, '')
                console.debug('fetching', include_url)
                return fetch(include_url).then((res) => res.text())
            }
            // uts end
            return line
        }),
    )

    return response.join('\n')
}

// uts end

const HOVER_OUT = 0
const HOVER_STARTED = 1
const HOVERING = 2

const ShaderPlane = (props) => {
    // This reference will give us direct access to the mesh
    const mesh = useRef()
    const [isHovered, setIsHovered] = useState(HOVER_OUT)
    const [initialHoverTime, setInitialHoverTime] = useState(0)
    // const [isInView, setIsInView] = useState(false);
    const { invalidate, setFrameloop } = useThree()
    const initialTime = props.initialTime

    useFrame((state) => {
        const { clock } = state
        const elapsedTime = clock.getElapsedTime()
        if (!mesh.current) {
            return
        }
        if (isHovered === HOVER_STARTED) {
            if (mesh.current.material.uniforms.iTime.value === initialTime) {
                mesh.current.material.uniforms.iTime.value = 0
            }
            setInitialHoverTime(
                elapsedTime - mesh.current.material.uniforms.iTime.value,
            )
            setIsHovered(HOVERING)
        } else if (isHovered === HOVERING) {
            mesh.current.material.uniforms.iTime.value =
                elapsedTime - initialHoverTime
        }
    })
    // const element = props.element;

    // useEffect(() => {
    //     const observer = new IntersectionObserver(
    //         ([entry]) => {
    //             setIsInView(entry.isIntersecting);
    //         },
    //         { threshold: 0.1 }
    //     );

    //     if (element) {
    //         observer.observe(element);
    //     }

    //     return () => {
    //         if (element) {
    //             observer.unobserve(element);
    //         }
    //     };
    // }, [element]);

    // useEffect(() => {
    //     if (isInView) {
    //         setInitialHoverTime(clock.current.getElapsedTime());
    //         setFrameloop("always");
    //     }
    // }, [isInView]);

    // useFrame(() => {
    //     if (mesh.current) {
    //         const elapsedTime = clock.current.getElapsedTime();
    //         mesh.current.material.uniforms.iTime.value = isInView ? elapsedTime - initialHoverTime : defaultTime;
    //         // if(!isInView) {
    //         //     setFrameloop("demand");
    //         // }
    //     }
    // });

    const uniforms = useMemo(
        () => ({
            iTime: {
                value: initialTime,
            },
            iFrame: {
                value: 0.0,
            },
            iMouse: {
                value: new THREE.Vector4(),
            },
            iResolution: { value: new THREE.Vector3(16, 9, 1) },
        }),
        [initialTime],
    )

    const handlePointerOver = (e) => {
        // console.debug(e);
        setIsHovered(HOVER_STARTED)
        // invalidate();
        setFrameloop('always')
    }

    const handlePointerOut = (e) => {
        // console.debug(e);
        setIsHovered(HOVER_OUT)
        setFrameloop('demand')
        console.debug('iTime', mesh.current.material.uniforms.iTime.value)
    }

    return (
        <Plane
            args={[16, 9]}
            ref={mesh}
            onPointerOver={handlePointerOver}
            onPointerOut={handlePointerOut}
        >
            <shaderMaterial
                uniforms={uniforms}
                fragmentShader={
                    defaults.fragmentShaderPreamble +
                    props.fragmentShader +
                    defaults.fragmentShaderPostemable
                }
                vertexShader={defaults.vertexShader}
            />
        </Plane>
    )
}

const embeded_shaders = document.querySelectorAll('.embeded-shadertoy')

for (const element of embeded_shaders) {
    const shader = element.textContent
    element.textContent = ''

    element.classList.add('lazy-loading')

    let initialTime = 0.0
    // if classList has something starting with iTime-, then extract the rest as a number and use it as initial time
    for (const className of element.classList) {
        if (className.startsWith('iTime-')) {
            initialTime = Number.parseFloat(className.substring(6))
            element.classList.remove(className)
        }
    }

    // let handleMouseOver = (event) => {
    //     element.removeEventListener('mouseover', handleMouseOver);
    resolveIncludesAsync(shader).then((shader) => {
        element.classList.remove('lazy-loading')
        // const renderer = ImageEffectRenderer.createTemporary(element, shader, options);
        createRoot(element).render(
            // https://r3f.docs.pmnd.rs/advanced/scaling-performance
            <Canvas frameloop="demand">
                {/* <CameraControls /> */}
                {/* <ambientLight intensity={Math.PI / 2} />
                  <spotLight position={[10, 10, 10]} angle={0.15} penumbra={1} decay={0} intensity={Math.PI} />
                  <pointLight position={[-10, -10, -10]} decay={0} intensity={Math.PI} /> */}
                <Billboard>
                    <ShaderPlane
                        fragmentShader={shader}
                        initialTime={initialTime}
                    />
                    {/* element={element}  */}
                </Billboard>
            </Canvas>,
        )
    })
    // };

    // element.addEventListener('mouseover', handleMouseOver);
}
