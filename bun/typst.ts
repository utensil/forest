import typst_ts_renderer_bg from '@myriaddreamin/typst-ts-renderer/pkg/typst_ts_renderer_bg.wasm'
// The following paths come from https://github.com/Myriad-Dreamin/typst.ts/blob/main/packages/typst.ts/examples/all-in-one-lite.html
// But they crashes bun so we do the copy manually in our build.sh
import typst_ts_web_compiler_bg from '@myriaddreamin/typst-ts-web-compiler/pkg/typst_ts_web_compiler_bg.wasm'
import { FetchAccessModel } from '@myriaddreamin/typst.ts'
// bun install @myriaddreamin/typst.ts @myriaddreamin/typst-ts-web-compiler @myriaddreamin/typst-ts-renderer
// following https://myriad-dreamin.github.io/typst.ts/cookery/guide/all-in-one.html
import {
    $typst,
    TypstSnippet,
} from '@myriaddreamin/typst.ts/dist/esm/contrib/snippet.mjs'
import { randstr } from '@myriaddreamin/typst.ts/dist/esm/utils.mjs'

$typst.setCompilerInitOptions({
    getModule: () => `/forest/${typst_ts_web_compiler_bg}`,
})
$typst.setRendererInitOptions({
    getModule: () => `/forest/${typst_ts_renderer_bg}`,
})

const getUrlBase = () => {
    const url = new URL(window.location.href)
    const urlParts = url.pathname.split('/')
    urlParts.pop()
    const urlBase = `${url.origin}/forest/typst/`
    console.debug(urlBase)
    return urlBase
}

const fetchBackend = new FetchAccessModel(
    // window.location.hostname === 'utensil.github.io' ? '/forest/typst/' : '/typst/'
    getUrlBase(),
)

$typst.use(TypstSnippet.withAccessModel(fetchBackend))

TypstSnippet.prototype.getCompileOptionsOld =
    TypstSnippet.prototype.getCompileOptions

$typst.getCompileOptions = async (opts) => {
    if ('mainContent' in opts) {
        // console.log('calling new');
        const destFile = `/${randstr()}.typ`
        await $typst.addSource(destFile, opts.mainContent)
        return { mainFilePath: destFile, diagnostics: 'none' }
    }
    // console.log('calling old');
    return await $typst.getCompileOptionsOld(opts)
}

TypstSnippet.prototype.removeTmpOld = TypstSnippet.prototype.removeTmp

$typst.removeTmp = (opts) => {
    if (opts.mainFilePath) {
        return $typst.unmapShadow(opts.mainFilePath)
    }
    return Promise.resolve()
}

const fetch_text = async (url) => {
    const response = await fetch(url)
    return await response.text()
}

const typst_tags = document.querySelectorAll('.typst-root.loading')
// console.log(typst_tags);
for (const typst_tag of typst_tags) {
    let typst_src_url = typst_tag.getAttribute('data-src')

    try {
        if (typst_src_url) {
            if (!typst_src_url.startsWith('/')) {
                typst_src_url = `/${typst_src_url}`
            }
            const rendered = await $typst.svg({
                mainFilePath: typst_src_url,
                data_selection: {
                    js: true,
                    css: false,
                    defs: true,
                    body: true,
                },
            })
            typst_tag.innerHTML = rendered
            typst_tag.classList.remove('loading')
        } else {
            const typst_source = typst_tag.textContent
            // console.log(typst_source);
            const rendered = await $typst.svg({
                mainContent: typst_source,
                data_selection: {
                    js: true,
                    css: false,
                    defs: true,
                    body: true,
                },
            })
            typst_tag.innerHTML = rendered
            typst_tag.classList.remove('loading')
        }
    } catch (e) {
        console.error(e)
        typst_tag.innerHTML = `<pre>The Typst file fails to render:\n\n${e.stack}</pre>`
        typst_tag.classList.remove('loading')
    }
}
