// example from https://github.com/pmndrs/react-three-fiber
// bun install three react-dom react @react-three/fiber @react-three/drei
import * as THREE from 'three'
import { createRoot } from 'react-dom/client'
import React, { useRef, useState, useMemo } from 'react'
import { Canvas, useFrame, ThreeElements } from '@react-three/fiber'
import { Billboard, Text, Plane, CameraControls } from '@react-three/drei'

function Box(props: ThreeElements['mesh']) {
  const ref = useRef<THREE.Mesh>(null!)
  const [hovered, hover] = useState(false)
  const [clicked, click] = useState(false)
  useFrame((state, delta) => (ref.current.rotation.x += delta))
  return (
    <mesh
      {...props}
      ref={ref}
      scale={clicked ? 1.5 : 1}
      onClick={(event) => click(!clicked)}
      onPointerOver={(event) => hover(true)}
      onPointerOut={(event) => hover(false)}>
      <boxGeometry args={[1, 1, 1]} />
      <meshStandardMaterial color={hovered ? 'hotpink' : 'orange'} />
    </mesh>
  )
}

const ShaderPlane = () => {
    // This reference will give us direct access to the mesh
    const mesh = useRef();
  
    const uniforms = useMemo(
      () => ({
        iTime: {
          value: 0.0,
        },
        iResolution: { value: new THREE.Vector2(10, 10) }
      }), []
    );
  
    useFrame((state) => {
      const { clock } = state;
      mesh.current.material.uniforms.iTime.value = clock.getElapsedTime();
    });
  
    return (
        <Plane args={[10, 10]} ref={mesh}>
            <shaderMaterial
                uniforms={uniforms}
                fragmentShader={`
varying vec2 vUv;
uniform float iTime;
uniform vec2 iResolution;

float SDSphere(in vec3 worldCoordinate, in vec3 center, in float radius) {

    return distance(worldCoordinate, center) - radius;

}

float SDPlane(in vec3 worldCoordinate, in float planeHeight, in vec3 rayDirection) {

    return (worldCoordinate.y - planeHeight)/abs(rayDirection.y);

}

float SDOctahedron( vec3 p, float s)
{
  p = abs(p);
  return (p.x+p.y+p.z-s)*0.57735027;
}


float SDScene(in vec3 worldCoordinate, in vec3 rayDirection) {

    float sphereOne = SDSphere(worldCoordinate, vec3(0.0, 0.0, 0.0), 0.5);
    //float sphereTwo = SDSphere(worldCoordinate, vec3(cos(iTime/3.0), -0.3, sin(iTime/5.0)), 0.2);
    //float sphereThree = SDSphere(worldCoordinate, vec3(sin(iTime/5.0), 0.3, cos(iTime/5.0)), 0.2);
    float orbital = SDOctahedron(worldCoordinate - vec3(cos(iTime/2.0), -0.15, sin(iTime/2.0)), 0.2);
    
    float groundPlane = SDPlane(worldCoordinate, -0.5, rayDirection);

    return min(min(sphereOne, orbital), groundPlane);

}


# define EPSILON 0.001

vec3 estimateNormal(in vec3 worldCoordinate) {

    if (worldCoordinate.y < -0.49) return vec3(0.0, 1.0, 0.0);

    float partialX = SDScene(worldCoordinate + vec3(EPSILON, 0.0, 0.0), vec3(0.0, 0.0, 1.0)) - SDScene(worldCoordinate - vec3(EPSILON, 0.0, 0.0), vec3(0.0, 0.0, 1.0));
    float partialY = SDScene(worldCoordinate + vec3(0.0, EPSILON, 0.0), vec3(0.0, 0.0, 1.0)) - SDScene(worldCoordinate - vec3(0.0, EPSILON, 0.0), vec3(0.0, 0.0, 1.0));
    float partialZ = SDScene(worldCoordinate + vec3(0.0, 0.0, EPSILON), vec3(0.0, 0.0, 1.0)) - SDScene(worldCoordinate - vec3(0.0, 0.0, EPSILON), vec3(0.0, 0.0, 1.0));
    
    return normalize(vec3(partialX, partialY, partialZ));

}


# define MAX_STEPS 105

vec3 rayMarch(in vec3 rayOrigin, in vec3 rayDirection) {

    vec3 ray = rayOrigin;

    for (int index = 0; index < MAX_STEPS; index++) {
   
        float distanceToScene = SDScene(ray, rayDirection);
        
        if (distanceToScene < EPSILON) return ray;
        
        ray += distanceToScene * rayDirection;
    
    }
    
    return vec3(0.0, 0.0, 0.0);

}

vec3 colorA = vec3(0.912,0.191,0.652);
vec3 colorB = vec3(1.000,0.777,0.052);

void main() {
    float aspect = iResolution.x/iResolution.y;
    
    // vec2 xy = gl_FragCoord.xy/iResolution.xy;


    // vec2 xy = gl_FragCoord.xy/800.0;

    vec2 xy = vUv;
    xy -= vec2(0.5, 0.5);
    xy *= 2.0 * vec2(aspect, 1.0);
    
    vec3 observerPosition = vec3(0.0, 0.0, -5.0);
    
    vec3 cameraBox = observerPosition + vec3(xy, 5.0);
    
    vec3 rayDirection = normalize(cameraBox - observerPosition);
    vec3 worldCoordinate = rayMarch(observerPosition, rayDirection);
    
    float renderable = length(worldCoordinate) > 0.0 ? 1.0 : 0.0;
    
    vec3 surfaceNormal = estimateNormal(worldCoordinate);
    float fresnel = 0.9 + dot(surfaceNormal, rayDirection);
    
    vec3 lightSource = vec3(7.0 * cos(iTime), 5.0, 7.0 * sin(iTime));
    
    vec3 photonDirection = normalize(worldCoordinate - lightSource);
    vec3 photonPosition = rayMarch(lightSource, photonDirection);
    
    float directLight = 1.2 - step(0.01, distance(photonPosition, worldCoordinate));
    
    float diffuseLight = 0.25 * smoothstep(0.0, 1.0, directLight * dot(surfaceNormal, -photonDirection));
    
    float ambientLight = 0.7;

    float specularLight = 0.1 * smoothstep(0.0, 1.0, dot(reflect(photonDirection, surfaceNormal), normalize(observerPosition - worldCoordinate)));

    float scatterFactor = 1.0 / sqrt(distance(worldCoordinate, lightSource)/5.0);

    gl_FragColor = vec4(renderable * (diffuseLight + ambientLight + specularLight) * scatterFactor * vec3(1.0, 1.0, 1.0), 1.0);

    // gl_FragColor = (diffuseLight + ambientLight + specularLight) * scatterFactor * vec4(1.0, 1.0, 1.0, 1.0);

    // vec3 color = mix(colorA, colorB, vUv.x);
    // gl_FragColor = (diffuseLight + ambientLight + specularLight) * scatterFactor * vec4(color, 1.0);
}
`}
                vertexShader={`varying vec2 vUv;

void main() {
  vUv = uv;
  vec4 modelPosition = modelMatrix * vec4(position, 1.0);
  vec4 viewPosition = viewMatrix * modelPosition;
  vec4 projectedPosition = projectionMatrix * viewPosition;

  gl_Position = projectedPosition;
}`}
            />
        </Plane>      
    );
  };

createRoot(document.getElementById('r3f-root') as HTMLElement).render(
  <Canvas>
    <CameraControls />
    <ambientLight intensity={Math.PI / 2} />
    <spotLight position={[10, 10, 10]} angle={0.15} penumbra={1} decay={0} intensity={Math.PI} />
    <pointLight position={[-10, -10, -10]} decay={0} intensity={Math.PI} />
    <Box position={[-7, 0, 0]} />
    <Box position={[7, 0, 0]} />
    <Box position={[0, -1.2, 0]} />
    <Box position={[0, 1.2, 0]} />
    <Billboard>
        <Text fontSize="0.2" color="black">rotate the boxes by dragging, scroll to zoom
        </Text>
        <ShaderPlane />
    </Billboard>
  </Canvas>,
)