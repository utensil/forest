// bun install @myriaddreamin/typst.ts @myriaddreamin/typst-ts-web-compiler @myriaddreamin/typst-ts-renderer
// following https://myriad-dreamin.github.io/typst.ts/cookery/guide/all-in-one.html
import { $typst, TypstSnippet } from '@myriaddreamin/typst.ts/dist/esm/contrib/snippet.mjs';
import { FetchAccessModel } from '@myriaddreamin/typst.ts';
// The following paths come from https://github.com/Myriad-Dreamin/typst.ts/blob/main/packages/typst.ts/examples/all-in-one-lite.html
// But they crashes bun so we do the copy manually in our build.sh
// import typst_ts_web_compiler_bg from '@myriaddreamin/typst-ts-web-compiler/pkg/typst_ts_web_compiler_bg.wasm';
// import typst_ts_renderer_bg from '@myriaddreamin/typst-ts-renderer/pkg/typst_ts_renderer_bg.wasm';

$typst.setCompilerInitOptions({
    getModule: () => './typst_ts_web_compiler_bg.wasm',
});
$typst.setRendererInitOptions({
    getModule: () => './typst_ts_renderer_bg.wasm',
});

const fetchBackend = new FetchAccessModel(
    '/typst/',
);
$typst.use(
    TypstSnippet.withAccessModel(fetchBackend),
);

const fetch_text = async (url) => {
    const response = await fetch(url);
    return await response.text();
};

const typst_tags = document.querySelectorAll('.typst-root.lazy-loading');
// console.log(typst_tags);
for (let i = 0; i < typst_tags.length; i++) {
    const typst_tag = typst_tags[i];
    let typst_src_url = typst_tag.getAttribute('data-src');
    if(typst_src_url) {
        if(!typst_src_url.startsWith('/')) {
            typst_src_url = `/${typst_src_url}`;
        }
        const rendered = await $typst.svg({ mainFilePath: typst_src_url });
        typst_tag.innerHTML = rendered;
        typst_tag.classList.remove('lazy-loading');
    } else {
        const typst_source = typst_tag.textContent;
        console.log(typst_source);
        const rendered = await $typst.svg({ mainContent: typst_source });
        typst_tag.innerHTML = rendered;
        typst_tag.classList.remove('lazy-loading');
    }
}