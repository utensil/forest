// bun install mathpix-markdown-it
import { MathpixMarkdownModel } from 'mathpix-markdown-it'

// Initialize with options for math rendering
const options = {
    htmlTags: true,
    breaks: true,
    outMath: {
        include_mathml: true,
        include_latex: true,
        include_svg: true
    }
}

// Add required styles to document head
const style = document.createElement("style")
style.setAttribute("id", "Mathpix-styles")
style.innerHTML = MathpixMarkdownModel.getMathpixFontsStyle() + MathpixMarkdownModel.getMathpixStyle(true)
document.head.appendChild(style)

const markdownit_tags = document.querySelectorAll('.markdownit.grace-loading')
for (const markdownit_tag of markdownit_tags) {
    const markdown_source = markdownit_tag.innerHTML
    const converted_source = markdown_source
        .replaceAll(/&lt;/g, '<')
        .replaceAll(/&gt;/g, '>')
        .replaceAll(/\\([\[\(])(.+?)\\([\)\]])/g, '\\\\$1$2\\\\$3')
    
    markdownit_tag.innerHTML = MathpixMarkdownModel.markdownToHTML(converted_source, options)
    markdownit_tag.classList.remove('grace-loading')
}
