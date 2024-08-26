
#let setup(body) = {
    // light mode
    // let fg = rgb("000000")
    // let bg = rgb("ffffff")
    // dark mode
    // let fg = rgb("fdfdfd")
    // let bg = rgb(29, 30, 32)
    // set page(fill: bg)
    // set text(fill: fg)
    // // dark mode
    // set table(stroke: fg)

    let a4_width = 595.28pt
    let post_width = 750pt // actually px

    set page(width: a4_width, height: auto, margin: (x: 0.5cm, y: 0.5cm))

    set text(size: 16pt)
    set heading(numbering: "1.")

    body
}