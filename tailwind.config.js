/** @type {import('tailwindcss').Config} */
module.exports = {
    content: ['./bun/*.{js,ts,jsx,tsx}'],
    theme: {
        extend: {
            invert: {
                25: '.25',
                50: '.5',
                75: '.75',
                85: '.85',
            },
        },
    },
    plugins: [],
}
