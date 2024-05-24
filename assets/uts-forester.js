function getUserPreference() {
    return localStorage.getItem("theme") || "system";
}

function saveUserPreference(userPreference) {
    localStorage.setItem("theme", userPreference);
}

function getAppliedMode(userPreference) {
    if (userPreference === "light") {
        return "light";
    }
    if (userPreference === "dark") {
        return "dark";
    }
    // system
    if (matchMedia("(prefers-color-scheme: light)").matches) {
        return "light";
    }
    return "dark";
}

function setAppliedMode(mode) {
    document.documentElement.dataset.appliedMode = mode;
}

function rotatePreferences(userPreference) {
    if (userPreference === "dark") {
        return "light";
    }
    if (userPreference === "light") {
        return "dark";
    }
    // for invalid values, just in case
    return rotatePreferences(getAppliedMode("system"));
}

// the class of body is toggled between none and dark
function toggleTheme() {
    const newUserPref = rotatePreferences(getUserPreference());
    userPreference = newUserPref;
    saveUserPreference(newUserPref);
    setAppliedMode(getAppliedMode(newUserPref));
}

// on document ready
document.addEventListener("DOMContentLoaded", function () {
    // on clicking the button with id theme-toggle, the function toggleTheme is called
    document.getElementById("theme-toggle").onclick = toggleTheme;
});

// Important to be 1st in the DOM
const theme = localStorage.getItem('theme') || 'light';
document.documentElement.dataset.appliedMode = theme;
