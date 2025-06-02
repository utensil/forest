// bun add cubing

// import { Alg } from "cubing/alg";
import { TwistyPlayer } from "cubing/twisty";
// import { randomScrambleForEvent } from "cubing/scramble";

const twistyOptions = window.twistyOptions || {
    puzzle: '3x3x3',
    hintFacelets: 'none',
    controlPanel: 'bottom-row',
    background: 'none'
}

const twisty_tags = document.querySelectorAll('.twisty.grace-loading')
// console.log(twisty_tags);
for (let i = 0; i < twisty_tags.length; i++) {
    const twisty_tag = twisty_tags[i]

    const setup = twisty_tag.getAttribute('data-setup')
    const alg = twisty_tag.textContent.trim()

    const twistyOptionsLocal = {
        experimentalSetupAlg: setup || '',
        alg: alg || '',
        ...twistyOptions
    }

    const player = new TwistyPlayer(twistyOptionsLocal)

    player.style.width = '95%'

    // const pre = document.createElement('pre')
    // pre.textContent = alg

    twisty_tag.innerHTML = ''

    // twisty_tag.appendChild(pre)

    twisty_tag.appendChild(player)

    twisty_tag.classList.remove('grace-loading')
}
