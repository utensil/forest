type DemoResult = readonly [label: string, value: string]

function outputFor(name: string): HTMLElement | null {
    return document.querySelector(`[data-demo-output="${name}"]`)
}

export function renderDemoResults(
    name: string,
    results: readonly DemoResult[],
): void {
    const output = outputFor(name)
    if (!output) {
        return
    }

    output.classList.remove('demo-output--error')

    const title = document.createElement('p')
    title.className = 'demo-output__title'
    title.textContent = 'Computed locally'

    const list = document.createElement('dl')
    list.className = 'demo-output__results'
    for (const [label, value] of results) {
        const term = document.createElement('dt')
        term.textContent = label
        const definition = document.createElement('dd')
        definition.textContent = value
        list.append(term, definition)
    }

    output.replaceChildren(title, list)
}

export function renderDemoError(name: string, error: unknown): void {
    const output = outputFor(name)
    if (!output) {
        return
    }

    output.classList.add('demo-output--error')
    const title = document.createElement('p')
    title.className = 'demo-output__title'
    title.textContent = 'This browser-side computation could not run.'
    const detail = document.createElement('code')
    detail.textContent = error instanceof Error ? error.message : String(error)
    output.replaceChildren(title, detail)
}
