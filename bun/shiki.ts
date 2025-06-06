// bun add shiki
import {
    type Highlighter,
    type Lang,
    type Theme,
    createHighlighter,
} from 'shiki'

interface LangAlias {
    [key: string]: string
}

async function loadJson(url: string) {
    const res = await fetch(url)
    try {
        return await res.json()
    } catch (err) {
        console.error(err)
        return undefined
    }
}

// document.addEventListener('DOMContentLoaded', async () => {

const code_tags = document.querySelectorAll(
    'article code.highlight.grace-loading',
)

if (code_tags.length !== 0) {
    // https://github.com/PaulOlteanu/Railscasts-Renewed/blob/master/themes/Railscasts-Renewed.json
    const railscastsjson = await loadJson(
        'https://cdn.jsdelivr.net/gh/PaulOlteanu/Railscasts-Renewed@master/themes/Railscasts-Renewed.json',
    )

    // https://github.com/leanprover/vscode-lean4/blob/master/vscode-lean4/syntaxes/lean4.json
    const lean4json = await loadJson(
        'https://cdn.jsdelivr.net/gh/leanprover/vscode-lean4@master/vscode-lean4/syntaxes/lean4.json',
    )

    const highlightAllCode = async () => {
        const isDark = document.querySelector('html[data-applied-mode="dark"]')
        let theme = isDark ? 'aurora-x' : 'one-light' // 'ayu-dark' //'aurora-x'
        let themes = ['aurora-x', 'one-light']

        for (const code of code_tags) {
            const firstClass = code.classList[0]
            if (!firstClass) continue

            let lang: Lang | unknown = firstClass
            let langAlias: LangAlias = {}

            if (/lean.*/.test(firstClass) && lean4json) {
                lang = lean4json
                langAlias = {
                    lean4: 'Lean 4',
                    lean: 'Lean 4',
                }
            }

            if (isDark && railscastsjson) {
                theme = 'Railscasts Renewed'
                themes = [railscastsjson]
            }

            const highlighter: Highlighter = await createHighlighter({
                langs: [lang as Lang],
                langAlias,
                themes: themes as Theme[],
            })

            const html = await highlighter.codeToHtml(
                code.textContent
                    ?.replaceAll(/^\n/g, '')
                    .replaceAll(/\n$/g, '') || '',
                { lang: lang as Lang, theme: theme as Theme },
            )
            code.innerHTML = html
            code.classList.remove('grace-loading')
        }
    }

    await highlightAllCode()

    const toggleTheme = document.getElementById('theme-toggle').onclick
    document.getElementById('theme-toggle').onclick = async () => {
        toggleTheme()
        await highlightAllCode()
    }
}
// })
