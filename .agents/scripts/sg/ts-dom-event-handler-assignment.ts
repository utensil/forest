// Example match for ts-dom-event-handler-assignment (TypeScript)
const button = document.createElement('button');
button.onclick = () => alert('Clicked!');
input.onchange = handleChange;
link.onmouseover = function() { /* ... */ };
// Not matched:
button.disabled = true;
