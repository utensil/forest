// Adapted from https://penrose.cs.cmu.edu/docs/ref/react
// bun install @penrose/core
import * as Penrose from "@penrose/core";

const penrose_roots = document.querySelectorAll('.penrose-root');
penrose_roots.forEach(penrose_root => {
    const domain = penrose_root.querySelector('.penrose-domain').textContent;
    const substance = penrose_root.querySelector('.penrose-substance').textContent
    const style = penrose_root.querySelector('.penrose-style').textContent;
    const variation = "";
    const trio = { variation, domain, substance, style };
    penrose_root.innerHTML = "";
    penrose_root.classList.remove('penrose-root');
    Penrose.diagram(trio, penrose_root, async () => undefined);
});
