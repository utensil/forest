---
title: Enhanced iframe
tag: features/component
---

Quartz can embed external content using iframes based on a frontmatter property or directly in markdown content. You can add it to any layout by using `Component.Iframe` in `quartz.layout.ts`.

## Features

- Automatically embeds external content using an iframe
- Displays the source URL in a subtle header
- Provides a convenient "open in new tab" button
- Responsive design that works on all screen sizes
- Supports custom styling through the `iframe-style` frontmatter property or inline style attributes
- Can be configured via component options or frontmatter
- Supports direct HTML iframe tags in markdown content

## Usage

### Via Frontmatter

Add an `iframe` property to your frontmatter with the URL you want to embed:

```yaml
---
title: My Page
iframe: https://example.com
---
```

The component will automatically render an iframe with the specified URL, along with a header showing the URL and an external link icon to open the content in a new tab.

### Via Component Options

When adding the component to your layout, you can specify the source URL and styles directly:

```typescript
Component.Iframe({
  src: "https://example.com",
  style: {
    height: "400px",
    border: "1px solid red"
  }
})
```

This is useful when you want to embed a specific iframe in a layout regardless of the page content.

### Via HTML in Markdown

You can directly include iframe HTML tags in your markdown content:

```html
<iframe src="https://example.com" style="width: 100%; height: 500px; border: none;"></iframe>
```

The `iframe-embed` transformer will automatically process these tags and render them using the Iframe component.

### Priority Order

When multiple configuration methods are used:
1. Component options take precedence over frontmatter and inline HTML
2. Frontmatter values are used as fallbacks if component options are not provided
3. Inline HTML iframe attributes are used when directly embedding in markdown

## Custom Styling

### Via Frontmatter

You can customize the styling of the iframe by adding an `iframe-style` property to your frontmatter:

```yaml
---
title: My Page
iframe: https://example.com
iframe-style:
  height: 300px
  border: 2px solid #3498db
  borderRadius: 8px
---
```

The `iframe-style` property accepts any valid CSS properties in camelCase format (like React inline styles).

### Via Inline Style Attribute

When using HTML iframe tags directly in markdown, you can use the style attribute:

```html
<iframe src="https://example.com" style="width: 100%; height: 400px; border: 2px solid blue; border-radius: 10px;"></iframe>
```

### Style Distribution

The iframe-embed transformer intelligently distributes style properties between the container and the iframe itself:

- **Container styles**: width, border, border-radius, margin, box-shadow, etc.
- **Iframe styles**: height, padding, background, etc.

This ensures that styles like borders and border-radius are applied to the container (which includes the header), while content-specific styles are applied to the iframe itself.

## Examples

Here are some examples of iframes embedded directly in markdown:

<iframe src="https://example.com" style="width: 100%; height: 500px; border: none;"></iframe>

Here's another iframe with different styling:

<iframe src="https://example.com" style="width: 100%; height: 400px; border: 2px solid blue; border-radius: 10px;"></iframe>

And one with custom margin and box-shadow:

<iframe src="https://example.com" style="width: 90%; height: 300px; margin: 0 auto; box-shadow: 0 4px 8px rgba(0,0,0,0.2); border-radius: 8px;"></iframe>

<iframe src="https://www.example.com" style="width: 50%; height: 200px; border-radius: 50px; border-color: red; border-width: 5px;"></iframe>

## Customization

You can customize the default appearance of the iframe by modifying the styles in `quartz/components/styles/iframe.scss`.

Some aspects you might want to customize:
- The height of the iframe (default is 80vh)
- The border and border-radius
- The header appearance
- The colors and spacing

### Component Files

- Component: `quartz/components/Iframe.tsx`
- Style: `quartz/components/styles/iframe.scss`
- Transformer: `quartz/plugins/transformers/iframe-embed.ts`

## Technical Details

The iframe embedding functionality is implemented through two main components:

1. **Iframe Component**: Renders the iframe with a header showing the source URL and an external link button.

2. **iframe-embed Transformer**: Processes HTML iframe tags in markdown content and transforms them to be rendered by the Iframe component. The transformer:
   - First performs a text-level transformation to replace iframe tags with custom div tags
   - Then transforms these custom div tags into the proper iframe container structure
   - Preserves the src and style attributes from the original iframe
   - Ensures each iframe is rendered in its correct position within the document

To enable the transformer, make sure it's included in your `quartz.config.ts` file:

```typescript
plugins: {
  transformers: [
    // other transformers...
    Plugin.IframeEmbed(),
  ],
}
```
