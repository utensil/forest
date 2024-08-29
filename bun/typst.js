// bun install @myriaddreamin/typst.ts @myriaddreamin/typst-ts-web-compiler @myriaddreamin/typst-ts-renderer
// following https://myriad-dreamin.github.io/typst.ts/cookery/guide/all-in-one.html
import { $typst, TypstSnippet } from '@myriaddreamin/typst.ts/dist/esm/contrib/snippet.mjs';
import { FetchAccessModel } from '@myriaddreamin/typst.ts';
import { randstr } from '@myriaddreamin/typst.ts/dist/esm/utils.mjs';
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

const getUrlBase = () => {
    const url = new URL(window.location.href);
    const urlParts = url.pathname.split('/');
    urlParts.pop();
    const urlBase = url.origin + urlParts.join('/') + '/typst/';
    console.log(urlBase);
    return urlBase;
}

const fetchBackend = new FetchAccessModel(
    // window.location.hostname === 'utensil.github.io' ? '/forest/typst/' : '/typst/'
    getUrlBase()
);

$typst.use(
    TypstSnippet.withAccessModel(fetchBackend),
);

TypstSnippet.prototype.getCompileOptionsOld = TypstSnippet.prototype.getCompileOptions;

$typst.getCompileOptions = async (opts) => {
    if ('mainContent' in opts) {
        // console.log('calling new');
        const destFile = `/${randstr()}.typ`;
        await $typst.addSource(destFile, opts.mainContent);
        return { mainFilePath: destFile, diagnostics: 'none' };
    } else {
        // console.log('calling old');
        return await $typst.getCompileOptionsOld(opts);
    }
};

TypstSnippet.prototype.removeTmpOld = TypstSnippet.prototype.removeTmp;

$typst.removeTmp  = (opts) => {
    if (opts.mainFilePath) {
        return $typst.unmapShadow(opts.mainFilePath);
    }
    return Promise.resolve();
}

const fetch_text = async (url) => {
    const response = await fetch(url);
    return await response.text();
};

const typst_tags = document.querySelectorAll('.typst-root.lazy-loading');
// console.log(typst_tags);
for (let i = 0; i < typst_tags.length; i++) {
    const typst_tag = typst_tags[i];
    let typst_src_url = typst_tag.getAttribute('data-src');

    try {
        if(typst_src_url) {
            if(!typst_src_url.startsWith('/')) {
                typst_src_url = `/${typst_src_url}`;
            }
            const rendered = await $typst.svg({ mainFilePath: typst_src_url });
            typst_tag.innerHTML = rendered;
            typst_tag.classList.remove('lazy-loading');
        } else {
            const typst_source = typst_tag.textContent;
            // console.log(typst_source);
            const rendered = await $typst.svg({ mainContent: typst_source });
            typst_tag.innerHTML = rendered;
            typst_tag.classList.remove('lazy-loading');
        }
    }
    catch (e) {
        console.error(e);
        typst_tag.innerHTML = `<pre>The Typst file fails to render:\n\n${e.stack}</pre>`;
        typst_tag.classList.remove('lazy-loading');
    }
}