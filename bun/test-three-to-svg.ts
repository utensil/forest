import * as THREE from 'three'
import { OrbitControls } from 'three/addons/controls/OrbitControls.js'
import { SVGRenderer } from 'three/addons/renderers/SVGRenderer.js'

// console.clear();

const width = 500
const height = 500

const renderTestScene = (renderer, root) => {
    /* SETUP */
    const scene = new THREE.Scene()
    const camera = new THREE.PerspectiveCamera(75, width / height, 0.1, 1000)
    camera.position.z = 5

    root.appendChild(renderer.domElement) // Add the SVG in the DOM
    renderer.domElement.setAttribute('xmlns', 'http://www.w3.org/2000/svg') // Add the xmlns attribute

    /* Create 30 boxes */
    const geometry = new THREE.BoxGeometry()
    for (let i = 0; i < 20; i++) {
        // Create a random color for the material
        //   const material = new THREE.MeshBasicMaterial({
        //     color: 0xffffff * Math.random()
        //   });
        // create a material that reacts to lights
        const material = new THREE.MeshPhongMaterial({
            color: 0xffffff * Math.random(),
        })

        // Create a box
        const box = new THREE.Mesh(geometry, material)
        // Randomize the position, scale & rotation
        box.position.random().subScalar(0.5).multiplyScalar(8)
        box.scale.random().multiplyScalar(2).addScalar(0.1)
        box.rotation.set(
            Math.random() * Math.PI,
            Math.random() * Math.PI,
            Math.random() * Math.PI,
        )

        // Add a directional light
        const light = new THREE.DirectionalLight(0xffffff, 0.6)
        // Add an ambient light
        const ambient = new THREE.AmbientLight(0xffffff, 0.1)

        // Add the box to the scene
        scene.add(box)
        // Add the light to the scene
        scene.add(light)
        scene.add(ambient)
    }

    // Init the contoller
    const controls = new OrbitControls(camera, renderer.domElement)
    // Render the scene on each update of the controls
    controls.addEventListener('change', () => {
        renderer.render(scene, camera)
    })
    // First render of the scene
    renderer.render(scene, camera)

    /* EVENTS */
    function onWindowResize() {
        camera.aspect = width / height
        camera.updateProjectionMatrix()
        renderer.setSize(width, height)
    }
    window.addEventListener('resize', onWindowResize, false)
}

const webgl_renderer = new THREE.WebGLRenderer()
webgl_renderer.setSize(width, height) // Define its size

const three2webgl_root = document.querySelector('#three2webgl-root')

if (three2webgl_root) {
    renderTestScene(webgl_renderer, three2webgl_root)
}

const svg_renderer = new SVGRenderer() // Init a renderer
svg_renderer.overdraw = 0.5 // change to 0 to allow three.js to render overlapping lines
svg_renderer.setSize(width, height) // Define its size
svg_renderer.setQuality('high')
svg_renderer.setClearColor(0, 1) // set the background color to black as WebGLRenderer's default

const three2svg_root = document.querySelector('#three2svg-root')

if (three2svg_root) {
    renderTestScene(svg_renderer, three2svg_root)
}
