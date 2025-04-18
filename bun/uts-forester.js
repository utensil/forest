function getUserPreference() {
    return localStorage.getItem('theme') || 'system'
}

function saveUserPreference(userPreference) {
    localStorage.setItem('theme', userPreference)
}

function getAppliedMode(userPreference) {
    if (userPreference === 'light') {
        return 'light'
    }
    if (userPreference === 'dark') {
        return 'dark'
    }
    // system
    if (matchMedia('(prefers-color-scheme: dark)').matches) {
        return 'dark'
    }
    return 'light'
}

function setAppliedMode(mode) {
    document.documentElement.dataset.appliedMode = mode
}

function rotatePreferences(userPreference) {
    if (userPreference === 'dark') {
        return 'light'
    }
    if (userPreference === 'light') {
        return 'dark'
    }
    // for invalid values, just in case
    return rotatePreferences(getAppliedMode('system'))
}

// the class of body is toggled between none and dark
function rotateFontPreferences(currentFont) {
    if (currentFont === 'serif') return 'mono'
    if (currentFont === 'mono') return 'sans'
    return 'serif'
}

function getFontPreference() {
    return localStorage.getItem('font') || 'serif'
}

function saveFontPreference(font) {
    localStorage.setItem('font', font)
}

function setAppliedFont(font) {
    document.documentElement.dataset.appliedFont = font
}

function toggleFont() {
    const newFontPref = rotateFontPreferences(getFontPreference())
    saveFontPreference(newFontPref)
    setAppliedFont(newFontPref)
}

function toggleTheme() {
    const newUserPref = rotatePreferences(getUserPreference())
    userPreference = newUserPref
    saveUserPreference(newUserPref)
    setAppliedMode(getAppliedMode(newUserPref))
}

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
    // on clicking the button with id theme-toggle, the function toggleTheme is called
    document.getElementById('theme-toggle').onclick = toggleTheme
    document.getElementById('font-toggle').onclick = toggleFont
    document.getElementById('search').onclick = search
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

// Important to be 1st in the DOM
const theme = localStorage.getItem('theme') || getAppliedMode('system')
document.documentElement.dataset.appliedMode = theme
const font = localStorage.getItem('font') || 'serif'
document.documentElement.dataset.appliedFont = font
