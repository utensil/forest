import { getHighlighter } from 'https://esm.sh/shiki@1.6.0'

document.addEventListener('DOMContentLoaded', async () => {

    const lean4res = await fetch('https://cdn.jsdelivr.net/gh/leanprover/vscode-lean4@master/vscode-lean4/syntaxes/lean4.json')

    console.log(lean4res)

    if(!lean4res.ok) {
        console.error('Failed to fetch lean4.json')
    }
    let lean4json;
    try {
        lean4json = await lean4res.json()
    } catch(err) {
      console.error(err);
    }

    const codes = document.querySelectorAll('code')
        codes.forEach(async code => {
            let lang = code.getAttribute('class') || 'plaintext'
            let langAlias = {}

            if((lang == 'lean4' || lang == 'lean') && lean4json) {
                lang = lean4json
                langAlias = { 
                    lean4: 'Lean 4',
                    lean: 'Lean 4'
                }
            }

            const highlighter = await getHighlighter({
                langs: [lang],
                langAlias,
                themes: ['one-dark-pro'],
            })

            const html = await highlighter.codeToHtml(
                code.textContent.replaceAll(/^\n/g, '').replaceAll(/\n$/g, ''),
                { lang, theme: 'one-dark-pro' }
            )
            code.innerHTML = html
        })
})