const systemTheme = matchMedia('(prefers-color-scheme: dark)')

function getThemePreference() {
    const theme = localStorage.getItem('theme')
    if (theme === 'light' || theme === 'dark' || theme === 'auto') {
        return theme
    }
    return 'auto'
}

function saveThemePreference(themePreference) {
    localStorage.setItem('theme', themePreference)
}

function getAppliedMode(themePreference) {
    if (themePreference === 'light') {
        return 'light'
    }
    if (themePreference === 'dark') {
        return 'dark'
    }
    if (systemTheme.matches) {
        return 'dark'
    }
    return 'light'
}

function setAppliedMode(mode) {
    document.documentElement.dataset.appliedMode = mode
}

function rotateThemePreference(themePreference) {
    if (themePreference === 'auto') {
        return 'light'
    }
    if (themePreference === 'light') {
        return 'dark'
    }
    return 'auto'
}

function updateThemeToggleLabel() {
    const themeToggle = document.getElementById('theme-toggle')
    if (!themeToggle) return
    const themePreference = getThemePreference()
    const appliedMode = getAppliedMode(themePreference)
    const nextThemePreference = rotateThemePreference(themePreference)
    const detail =
        themePreference === 'auto' ? `auto (${appliedMode})` : themePreference
    const label = `Theme: ${detail}; next: ${nextThemePreference}`
    themeToggle.title = label
    themeToggle.setAttribute('aria-label', label)
}

function applyThemePreference(themePreference) {
    document.documentElement.dataset.themePreference = themePreference
    setAppliedMode(getAppliedMode(themePreference))
    updateThemeToggleLabel()
}

function getLightPaperPreference() {
    const lightPaper = localStorage.getItem('light-paper')
    if (
        lightPaper === 'mix' ||
        lightPaper === 'near-white' ||
        lightPaper === 'sepia'
    ) {
        return lightPaper
    }
    return 'mix'
}

function saveLightPaperPreference(lightPaperPreference) {
    localStorage.setItem('light-paper', lightPaperPreference)
}

function rotateLightPaperPreference(lightPaperPreference) {
    if (lightPaperPreference === 'mix') {
        return 'near-white'
    }
    if (lightPaperPreference === 'near-white') {
        return 'sepia'
    }
    return 'mix'
}

function updateLightPaperToggleLabel() {
    const lightPaperToggle = document.getElementById('light-paper-toggle')
    if (!lightPaperToggle) return
    const lightPaperPreference = getLightPaperPreference()
    const nextLightPaperPreference =
        rotateLightPaperPreference(lightPaperPreference)
    const label = `Light paper: ${lightPaperPreference}; next: ${nextLightPaperPreference}`
    lightPaperToggle.title = label
    lightPaperToggle.setAttribute('aria-label', label)
}

function applyLightPaperPreference(lightPaperPreference) {
    document.documentElement.dataset.lightPaper = lightPaperPreference
    updateLightPaperToggleLabel()
}

function rotateFontPreferences(currentFont) {
    if (currentFont === 'serif') return 'mono'
    if (currentFont === 'mono') return 'sans'
    return 'serif'
}

function getFontPreference() {
    const font = localStorage.getItem('font')
    if (font === 'serif' || font === 'mono' || font === 'sans') {
        return font
    }
    return 'serif'
}

function saveFontPreference(font) {
    localStorage.setItem('font', font)
}

function setAppliedFont(font) {
    document.documentElement.dataset.appliedFont = font
}

function updateFontToggleLabel() {
    const fontToggle = document.getElementById('font-toggle')
    if (!fontToggle) return
    const fontPreference = getFontPreference()
    const nextFontPreference = rotateFontPreferences(fontPreference)
    const label = `Font: ${fontPreference}; next: ${nextFontPreference}`
    fontToggle.title = label
    fontToggle.setAttribute('aria-label', label)
}

function applyFontPreference(fontPreference) {
    setAppliedFont(fontPreference)
    updateFontToggleLabel()
}

function toggleFont() {
    const newFontPref = rotateFontPreferences(getFontPreference())
    saveFontPreference(newFontPref)
    applyFontPreference(newFontPref)
}

function toggleTheme() {
    const newThemePreference = rotateThemePreference(getThemePreference())
    saveThemePreference(newThemePreference)
    applyThemePreference(newThemePreference)
}

function toggleLightPaper() {
    const newLightPaperPreference = rotateLightPaperPreference(
        getLightPaperPreference(),
    )
    saveLightPaperPreference(newLightPaperPreference)
    applyLightPaperPreference(newLightPaperPreference)
}

function bindControl(controlId, action) {
    const control = document.getElementById(controlId)
    if (!control) return
    control.onclick = action
    if (control.getAttribute('role') !== 'button') return
    control.addEventListener('keydown', (event) => {
        if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault()
            action()
        }
    })
}

// AGENT-NOTE: Keep the persisted preference distinct from the applied mode so auto can follow device changes.
systemTheme.addEventListener('change', () => {
    if (getThemePreference() === 'auto') {
        applyThemePreference('auto')
    }
})

function search() {
    const ninja = document.querySelector('ninja-keys')
    const mode = document.documentElement.dataset.appliedMode
    ninja.setAttribute('class', mode)
    ninja.open()
}

function togglelang() {
    const article = document.querySelector('article')
    if (article) {
        article.classList.toggle('show-langblock')
    }
}

// on document ready
document.addEventListener('DOMContentLoaded', () => {
    bindControl('theme-toggle', toggleTheme)
    bindControl('light-paper-toggle', toggleLightPaper)
    bindControl('font-toggle', toggleFont)
    bindControl('search', search)
    applyThemePreference(getThemePreference())
    applyLightPaperPreference(getLightPaperPreference())
    applyFontPreference(getFontPreference())
    const langblock_toggle = document.getElementById('langblock-toggle')
    if (langblock_toggle) langblock_toggle.onclick = togglelang

    const content_out_of_sight_observer = new IntersectionObserver(
        (entries) => {
            for (const entry of entries) {
                const details = entry.target.querySelector(
                    'section > details[id]',
                )
                const id = details.getAttribute('id')
                // console.log(entry);

                const toc_entry = document.querySelector(
                    `nav#toc [data-target="#${id}"]`,
                )

                if (
                    !entry.isIntersecting &&
                    toc_entry &&
                    !toc_entry.parentElement.querySelector('ul li')
                ) {
                    // console.log("Scrolling out of view", entry.target, entry.intersectionRatio, entry.isIntersecting, entry);
                    const toc_container = toc_entry
                        .closest('li')
                        .parentElement.closest('li')
                    if (toc_container) toc_container.classList.remove('active')
                    content_out_of_sight_observer.unobserve(entry.target)
                }
            }
        },
    )

    const toc_out_of_sight_observer = new IntersectionObserver((entries) => {
        for (const entry of entries) {
            // console.log(entry);
            toc_out_of_sight_observer.unobserve(entry.target)
            if (!entry.isIntersecting) {
                // console.log("Scrolling into view", entry.target);
                entry.target.scrollIntoView({ block: 'center' })
            }
        }
    })

    const observer = new IntersectionObserver((entries) => {
        for (const entry of entries) {
            // console.log(entry);
            const id = entry.target.getAttribute('id')
            if (entry.intersectionRatio > 0) {
                // handle only leaf sections
                // if(entry.target.querySelector(`section`)) {
                //     return;
                // }
                const toc_entry = document.querySelector(
                    `nav#toc [data-target="#${id}"]`,
                )

                if (
                    toc_entry &&
                    !toc_entry.parentElement.querySelector('ul li')
                ) {
                    const toc_container = toc_entry
                        .closest('li')
                        .parentElement.closest('li')
                    if (toc_container) toc_container.classList.add('active')
                    toc_out_of_sight_observer.observe(toc_entry)
                }
                // else {
                //     target_element = document.querySelector(`#${id} h1`);
                //     console.warn("Not found", target_element.textContent);
                // }
            } else {
                // handle only leaf sections
                // if(entry.target.querySelector(`section`)) {
                //     return;
                // }
                const toc_entry = document.querySelector(
                    `nav#toc [data-target="#${id}"]`,
                )
                if (
                    toc_entry &&
                    !toc_entry.parentElement.querySelector('ul li')
                ) {
                    // toc_entry.parentElement.parentElement.classList.remove('active');
                    content_out_of_sight_observer.observe(
                        entry.target
                            .closest('details')
                            .parentElement.closest('details'),
                    )
                }
            }
        }
    })

    // Track all sections that have an `id` applied
    for (const section of document.querySelectorAll(
        'article section > details[id]',
    )) {
        observer.observe(section)
    }
})

// Important to be first in the DOM, before the page body is parsed.
applyThemePreference(getThemePreference())
applyLightPaperPreference(getLightPaperPreference())
applyFontPreference(getFontPreference())
