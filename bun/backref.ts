const citations = document.querySelectorAll('.link-reference > .link.local > a')

const citation_map = {}

for (const citation of citations) {
    const href = citation.getAttribute('href')
    citation_map[href] = citation_map[href] || 0
    const citation_id = ++citation_map[href]
    citation.setAttribute(
        'id',
        `ref-${href.replace('.xml', '')}-${citation_id}`,
    )
}

const references = document.querySelectorAll(
    'article footer section[data-taxon="Reference"] details summary header h1 a',
)

for (const reference of references) {
    const href = reference.getAttribute('href')
    const citation_count = citation_map[href]
    for (let i = 1; i <= citation_count; i++) {
        // create a back reference
        const back_reference = document.createElement('a')
        back_reference.textContent = '↩'
        back_reference.setAttribute(
            'href',
            `#ref-${href.replace('.xml', '')}-${i}`,
        )
        back_reference.setAttribute(
            'style',
            'color: var(--uts-text-gentle) !important;text-decoration: none; margin-left: 0.5ex; margin-right: 0.5ex;',
        )
        reference.parentElement?.parentElement?.appendChild(back_reference)
    }
}
