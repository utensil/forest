module.exports = {
    plugins: {
        'postcss-import': {},
        'tailwindcss/nesting': {},
        tailwindcss: { config: './tailwind.config.js' },
        autoprefixer: {},
    },
}
