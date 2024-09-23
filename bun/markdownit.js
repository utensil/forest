// bun install markdown-it
// for advanced usage, see https://github.com/markdown-it/markdown-it/blob/master/support/demo_template/index.mjs
import markdownit from 'markdown-it'

const md = markdownit({html: true});

const markdownit_tags = document.querySelectorAll('.markdownit.grace-loading');
console.log(markdownit_tags);
for (let i = 0; i < markdownit_tags.length; i++) {
    const markdownit_tag = markdownit_tags[i];
    const markdown_source = markdownit_tag.innerHTML;
    // console.log(markdown_source);
    markdownit_tag.innerHTML = md.render(markdown_source);
    markdownit_tag.classList.remove('grace-loading');
}