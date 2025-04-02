// bun install markdown-it
// for advanced usage, see https://github.com/markdown-it/markdown-it/blob/master/support/demo_template/index.mjs

/* https://github.com/Mathpix/mathpix-markdown-it
 * TODO use mathpix-markdown-it instead of raw markdown-it, rewrite the code
 * but it errors with `Uncaught ReferenceError: global is not defined`
 */
import markdownit from 'markdown-it'

const md = markdownit({ html: true, linkify: true })

const markdownit_tags = document.querySelectorAll('.markdownit.grace-loading')
// console.log(markdownit_tags);
for (let i = 0; i < markdownit_tags.length; i++) {
    const markdownit_tag = markdownit_tags[i]
    const markdown_source = markdownit_tag.innerHTML
    // console.log(markdown_source);
    const converted_source = markdown_source
        .replaceAll(/&lt;/g, '<')
        // unescape to make quotes work
        .replaceAll(/&gt;/g, '>')
        // we escape fr:tex tags to avoid conflicts with markdown syntax
        // note that we need to use `+?` which is a lazy quantifier, meaning it matches as few characters as possible
        .replaceAll(/\\([\[\(])(.+?)\\([\)\]])/g, '\\\\$1$2\\\\$3')
    // console.log(converted_source)
    markdownit_tag.innerHTML = md.render(converted_source)
    markdownit_tag.classList.remove('grace-loading')
}
